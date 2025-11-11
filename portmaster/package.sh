#!/bin/bash
#
# Package ROMs Downloader for PortMaster
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
PACKAGE_DIR="$SCRIPT_DIR/package"
OUTPUT_ZIP="$SCRIPT_DIR/roms_downloader.zip"

echo "Packaging ROMs Downloader for PortMaster..."

# Clean previous package
rm -rf "$PACKAGE_DIR"
rm -f "$OUTPUT_ZIP"

# Create package structure
mkdir -p "$PACKAGE_DIR/roms_downloader"

# Copy Flutter build
echo "Copying Flutter build..."
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found at $BUILD_DIR"
    echo "Please run 'flutter build linux --release' first"
    exit 1
fi

# Copy executable
cp "$BUILD_DIR/roms_downloader" "$PACKAGE_DIR/roms_downloader/"

# Copy libraries
cp -r "$BUILD_DIR/lib" "$PACKAGE_DIR/roms_downloader/"

# Copy data assets
cp -r "$BUILD_DIR/data" "$PACKAGE_DIR/roms_downloader/"

# Copy port metadata
echo "Copying PortMaster metadata..."
cp "$SCRIPT_DIR/port.json" "$PACKAGE_DIR/roms_downloader/"
cp "$SCRIPT_DIR/roms_downloader.sh" "$PACKAGE_DIR/"

# Make launch script executable
chmod +x "$PACKAGE_DIR/roms_downloader.sh"

# Create icon if available
if [ -f "$PROJECT_ROOT/assets/icon.png" ]; then
    echo "Adding icon..."
    mkdir -p "$PACKAGE_DIR/roms_downloader/images"
    cp "$PROJECT_ROOT/assets/icon.png" "$PACKAGE_DIR/roms_downloader/images/roms_downloader.png"
fi

# Create the zip file
echo "Creating zip package..."
cd "$PACKAGE_DIR"
zip -r "$OUTPUT_ZIP" . -x "*.DS_Store"
cd "$SCRIPT_DIR"

# Clean up
rm -rf "$PACKAGE_DIR"

echo "Package created successfully: $OUTPUT_ZIP"
echo ""
echo "To install on your handheld:"
echo "1. Copy $OUTPUT_ZIP to /roms/ports/ on your device"
echo "2. Launch PortMaster and install the port"
echo ""
echo "File size: $(du -h "$OUTPUT_ZIP" | cut -f1)"
