#!/bin/bash
set -e

# Directory setup
BUILD_DIR="build_knulli"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Clone flutter-pi if not present
if [ ! -d "flutter-pi" ]; then
    curl -L -o flutter-pi.zip https://github.com/ardera/flutter-pi/archive/refs/heads/master.zip
    unzip flutter-pi.zip
    mv flutter-pi-master flutter-pi
fi
cd flutter-pi

# Create build directory
mkdir -p build
cd build

# CONFIGURE CMAKE FOR KNULLI/BUILDROOT
# Key changes:
# - ENABLE_SESSION_SWITCHING=OFF: Disables libsystemd/libseat requirement (run as root/single user)
# - BUILD_TEXT_INPUT_PLUGIN=ON: Keep this
# - CMAKE_BUILD_TYPE=Release
# - We might need to manually disable Wayland if it's auto-detected. 
#   flutter-pi usually auto-detects. To force it off, we might need to hide the pkg-config files 
#   or patch CMakeLists.txt, but disabling session switching is the biggest win.

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SESSION_SWITCHING=OFF \
    -DENABLE_VULKAN=OFF \
    -DENABLE_OPENGL=ON \
    -DENABLE_EGL=ON \
    -DENABLE_GLES=ON \
    -DENABLE_LIBINPUT=ON \
    -DENABLE_UDEV=ON \
    -DENABLE_KMS=ON \
    -DENABLE_X11=OFF \
    -DENABLE_WAYLAND=OFF \
    -DENABLE_TESTS=OFF \
    -DENABLE_SYSTEMD=OFF \
    -DENABLE_DBUS=OFF \
    || (cat CMakeFiles/CMakeError.log && exit 1)

# Build
make -j$(nproc) || make -j1

echo "------------------------------------------------"
echo "Build complete."
echo "Binary is at: $(pwd)/flutter-pi"
echo "Check linked libraries with: ldd flutter-pi"
echo "------------------------------------------------"
