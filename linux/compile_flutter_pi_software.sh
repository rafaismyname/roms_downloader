#!/bin/bash
set -e

# Directory setup
BUILD_DIR="build_sw"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Clone flutter-pi if not present
if [ ! -d "flutter-pi" ]; then
    echo "Cloning flutter-pi..."
    git clone https://github.com/ardera/flutter-pi.git
fi
cd flutter-pi

# Create build directory
mkdir -p build
cd build

# CONFIGURE CMAKE FOR SOFTWARE RENDERING
# - ENABLE_SOFTWARE=ON: Enables software rendering support
# - ENABLE_OPENGL=ON: Required for llvmpipe
# - ENABLE_SESSION_SWITCHING=OFF: Keep disabled for Knulli
echo "Configuring CMake for Software Rendering..."
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_SESSION_SWITCHING=OFF \
  -DENABLE_VULKAN=OFF \
  -DENABLE_OPENGL=ON \
  -DENABLE_EGL=ON \
  -DENABLE_GLES=ON \
  -DENABLE_SOFTWARE=ON \
  -DENABLE_LIBINPUT=ON \
  -DENABLE_UDEV=ON \
  -DENABLE_KMS=ON \
  -DENABLE_X11=OFF \
  -DENABLE_WAYLAND=OFF \
  -DENABLE_TESTS=OFF \
  -DENABLE_SYSTEMD=OFF \
  -DENABLE_DBUS=OFF

# Build
echo "Building flutter-pi (Software)..."
make -j$(nproc)

echo "------------------------------------------------"
echo "Build complete."
echo "Binary is at: $(pwd)/flutter-pi"
echo "Check linked libraries with: ldd flutter-pi"
echo "------------------------------------------------"
