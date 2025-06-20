#!/bin/bash

# Build script for ROMs Downloader
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
}

# Function to build using Docker
build_with_docker() {
    local arch=$1
    local build_type=${2:-Release}
    
    print_status "Building for architecture: $arch (Build type: $build_type) using Docker"
    
    # Map architectures to Docker platforms
    local docker_platform=""
    local target_arch=""
    case $arch in
        "amd64"|"x86_64")
            docker_platform="linux/amd64"
            target_arch="amd64"
            ;;
        "arm64"|"aarch64")
            docker_platform="linux/arm64"
            target_arch="arm64"
            ;;
        *)
            print_error "Unsupported architecture for Docker build: $arch"
            return 1
            ;;
    esac
    
    # Create build directory and native assets directory
    local output_dir="$BUILD_DIR/linux_$target_arch"
    mkdir -p "$output_dir"
    
    # Pre-create native assets directory to avoid CMake errors
    mkdir -p "$PROJECT_DIR/build/native_assets/linux"
    
    # Build using docker-compose with better error handling
    cd "$SCRIPT_DIR"
    
    print_status "Starting Docker build process..."
    print_status "Build Type: $build_type"
    print_status "Target Architecture: $target_arch"
    print_status "Output Directory: $output_dir"
    
    # Set environment variables for docker-compose
    export BUILD_TYPE="$build_type"
    export TARGET_ARCH="$target_arch"
    export DOCKER_PLATFORM="$docker_platform"
    export OUTPUT_DIR="$output_dir"
    
    # Clean any existing containers first
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Run docker-compose with verbose output and proper error handling
    if ! docker-compose up --build --no-log-prefix --abort-on-container-exit "build-$target_arch"; then
        print_error "Docker build failed for architecture: $target_arch"
        print_error "Check the output above for detailed error information"
        
        # Show container logs for debugging
        print_status "Container logs for debugging:"
        docker-compose logs "build-$target_arch" || true
        
        # Cleanup on failure
        print_status "Cleaning up Docker resources..."
        docker-compose down --remove-orphans 2>/dev/null || true
        return 1
    fi
    
    # Check if build output exists and has content
    if [ ! -d "$output_dir" ]; then
        print_error "Build output directory doesn't exist: $output_dir"
        return 1
    fi
    
    # Check if we have any Flutter build artifacts
    local has_artifacts=false
    if [ -f "$output_dir/roms_downloader" ] || [ -f "$output_dir/lib/libflutter_linux_gtk.so" ] || [ -d "$output_dir/data/flutter_assets" ]; then
        has_artifacts=true
    fi
    
    if [ "$has_artifacts" = false ]; then
        print_warning "No Flutter artifacts found in output directory"
        print_status "Contents of output directory:"
        ls -la "$output_dir" 2>/dev/null || echo "Output directory not accessible"
        
        # Try to find Flutter build artifacts in the project directory
        print_status "Searching for Flutter build artifacts in project..."
        if [ -d "$PROJECT_DIR/build/linux" ]; then
            print_status "Found Flutter build directory, copying artifacts..."
            find "$PROJECT_DIR/build/linux" -name "bundle" -type d | while read bundle_dir; do
                if [ -d "$bundle_dir" ] && [ "$(ls -A "$bundle_dir" 2>/dev/null)" ]; then
                    print_status "Copying from: $bundle_dir"
                    cp -r "$bundle_dir"/* "$output_dir/" 2>/dev/null || true
                    has_artifacts=true
                    break
                fi
            done
        fi
    fi
    
    # Cleanup containers
    docker-compose down --remove-orphans
    
    print_success "Docker build process completed for $arch"
    
    # Create architecture-specific bundle
    local bundle_dir="$BUILD_DIR/bundles/roms_downloader_linux_$target_arch"
    mkdir -p "$bundle_dir"
    
    # Copy all artifacts from output directory
    if [ -d "$output_dir" ] && [ "$(ls -A "$output_dir" 2>/dev/null)" ]; then
        print_status "Creating bundle from output directory..."
        cp -r "$output_dir"/* "$bundle_dir/" 2>/dev/null || true
        
        # Ensure executable permissions
        if [ -f "$bundle_dir/roms_downloader" ]; then
            chmod +x "$bundle_dir/roms_downloader"
        fi
        
        # Verify bundle contents
        if [ "$(ls -A "$bundle_dir" 2>/dev/null)" ]; then
            print_success "Bundle created at: $bundle_dir"
            print_status "Bundle contents:"
            ls -la "$bundle_dir" | head -10
            return 0
        fi
    fi
    
    # Fallback: try to copy from Flutter build directory
    if [ -d "$PROJECT_DIR/build/linux" ]; then
        print_status "Fallback: copying from Flutter build directory..."
        find "$PROJECT_DIR/build/linux" -name "bundle" -type d | while read bundle_dir; do
            if [ -d "$bundle_dir" ] && [ "$(ls -A "$bundle_dir" 2>/dev/null)" ]; then
                cp -r "$bundle_dir"/* "$bundle_dir/" 2>/dev/null || true
                break
            fi
        done
        
        if [ "$(ls -A "$bundle_dir" 2>/dev/null)" ]; then
            print_success "Fallback bundle created at: $bundle_dir"
            return 0
        fi
    fi
    
    print_warning "Bundle creation completed but may be incomplete"
    return 0
}

# Enhanced build function that uses Docker when available
build_architecture() {
    local arch=$1
    local build_type=${2:-Release}
    
    # Use Docker for cross-compilation from macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        build_with_docker "$arch" "$build_type"
    else
        # Use native build on Linux
        build_architecture_native "$arch" "$build_type"
    fi
}

# Original native build function
build_architecture_native() {
    local arch=$1
    local build_type=${2:-Release}
    
    print_status "Building natively for architecture: $arch (Build type: $build_type)"
    
    local arch_build_dir="$BUILD_DIR/linux_$arch"
    mkdir -p "$arch_build_dir"
    
    cd "$arch_build_dir"
    
    # Configure cmake based on architecture
    local cmake_args="-DCMAKE_BUILD_TYPE=$build_type"
    
    case $arch in
        "x86_64"|"amd64")
            cmake_args="$cmake_args -DTARGET_ARCHITECTURES=x86_64"
            ;;
        "aarch64"|"arm64")
            cmake_args="$cmake_args -DTARGET_ARCHITECTURES=aarch64"
            ;;
        "native")
            cmake_args="$cmake_args -DTARGET_ARCHITECTURES=native"
            ;;
        *)
            print_error "Unknown architecture: $arch"
            return 1
            ;;
    esac
    
    # Run Flutter build with error handling
    print_status "Running Flutter build..."
    cd "$PROJECT_DIR"
    if ! flutter build linux --release; then
        print_error "Flutter build failed"
        return 1
    fi
    
    # Configure and build with CMake
    print_status "Configuring CMake..."
    cd "$arch_build_dir"
    if ! cmake $cmake_args "$PROJECT_DIR/linux"; then
        print_error "CMake configuration failed"
        return 1
    fi
    
    print_status "Building with make..."
    if ! make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4); then
        print_error "Make build failed"
        return 1
    fi
    
    print_success "Successfully built for $arch"
    
    # Create architecture-specific bundle
    local bundle_dir="$BUILD_DIR/bundles/roms_downloader_linux_$arch"
    mkdir -p "$bundle_dir"
    if [ -d "bundle" ]; then
        cp -r bundle/* "$bundle_dir/" 2>/dev/null || true
        print_success "Bundle created at: $bundle_dir"
    else
        print_warning "No bundle directory found in build output"
    fi
    
    return 0
}

# Enhanced usage function
show_usage() {
    echo "Usage: $0 [OPTIONS] [ARCHITECTURES...]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help          Show this help message"
    echo "  -d, --debug         Build in Debug mode (default: Release)"
    echo "  -c, --clean         Clean build directories before building"
    echo "  --all               Build for all supported architectures"
    echo "  --docker            Force use of Docker (auto-detected on macOS)"
    echo "  --native            Force native build (Linux only)"
    echo ""
    echo "ARCHITECTURES:"
    echo "  amd64/x86_64        Build for 64-bit x86 systems"
    echo "  arm64/aarch64       Build for 64-bit ARM systems"
    echo ""
    echo "Examples:"
    echo "  $0 --all            # Build for all architectures"
    echo "  $0 arm64 amd64      # Build for specific architectures"
    echo "  $0 -d arm64         # Build ARM64 in debug mode"
}

# Parse command line arguments
BUILD_TYPE="Release"
CLEAN_BUILD=false
BUILD_ALL=false
FORCE_DOCKER=false
FORCE_NATIVE=false
ARCHITECTURES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -d|--debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        --all)
            BUILD_ALL=true
            shift
            ;;
        --docker)
            FORCE_DOCKER=true
            shift
            ;;
        --native)
            FORCE_NATIVE=true
            shift
            ;;
        amd64|x86_64|arm64|aarch64)
            ARCHITECTURES+=("$1")
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Set default architectures
if [ ${#ARCHITECTURES[@]} -eq 0 ] && [ "$BUILD_ALL" = false ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ARCHITECTURES=("arm64")
    else
        ARCHITECTURES=("amd64")
    fi
elif [ "$BUILD_ALL" = true ]; then
    ARCHITECTURES=("amd64" "arm64")
fi

# Check Docker availability if needed
if [[ "$OSTYPE" == "darwin"* ]] || [ "$FORCE_DOCKER" = true ]; then
    check_docker
fi

# Clean build directories if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_status "Cleaning build directories..."
    rm -rf "$BUILD_DIR"
    flutter clean
    print_success "Build directories cleaned"
fi

# Create build directory
mkdir -p "$BUILD_DIR/bundles"

print_status "Starting build process..."
print_status "Build type: $BUILD_TYPE"
print_status "Architectures: ${ARCHITECTURES[*]}"
print_status "Platform: $OSTYPE"

# Build for each architecture
failed_builds=()
for arch in "${ARCHITECTURES[@]}"; do
    if ! build_architecture "$arch" "$BUILD_TYPE"; then
        failed_builds+=("$arch")
    fi
done

# Cleanup Docker resources
if [[ "$OSTYPE" == "darwin"* ]] || [ "$FORCE_DOCKER" = true ]; then
    print_status "Cleaning up Docker resources..."
    cd "$SCRIPT_DIR"
    docker-compose down --remove-orphans --volumes 2>/dev/null || true
    # Don't run system prune automatically as it might remove other containers
    print_status "Docker cleanup completed"
fi

# Summary
echo ""
echo "=== BUILD SUMMARY ==="
if [ ${#failed_builds[@]} -eq 0 ]; then
    print_success "All builds completed successfully!"
    print_status "Bundles available in: $BUILD_DIR/bundles/"
else
    print_warning "Some builds failed:"
    for arch in "${failed_builds[@]}"; do
        print_error "  - $arch"
    done
    exit 1
fi
