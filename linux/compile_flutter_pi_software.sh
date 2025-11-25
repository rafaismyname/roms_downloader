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

# APPLY FBDEV PATCH
# We check if the patch has already been applied to avoid errors
if ! grep -q "init_fbdev" src/flutter-pi.c; then
    echo "Applying FBDEV patch..."
    # We assume the patch file is copied to the build root or available nearby
    # In the CI, we will copy it to the right place.
    # For local testing, we look 3 levels up (build_sw/flutter-pi/build -> ../../../linux)
    if [ -f "../../../linux/flutter_pi_fbdev.patch" ]; then
        git apply ../../../linux/flutter_pi_fbdev.patch
    elif [ -f "../../linux/flutter_pi_fbdev.patch" ]; then
        git apply "../../linux/flutter_pi_fbdev.patch"
    else
        echo "WARNING: Patch file not found! Proceeding without patch (DRM required)."
    fi
else
    echo "FBDEV patch already applied."
fi

# Create build directory
mkdir -p build
cd build

# CONFIGURE CMAKE FOR SOFTWARE RENDERING
# - ENABLE_SOFTWARE=ON: Enables software rendering support
# - ENABLE_OPENGL=OFF: We are using pure software backend now
# - ENABLE_SESSION_SWITCHING=OFF: Keep disabled for Knulli
echo "Configuring CMake for Software Rendering..."
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_SESSION_SWITCHING=OFF \
  -DENABLE_VULKAN=OFF \
  -DENABLE_OPENGL=OFF \
  -DENABLE_EGL=OFF \
  -DENABLE_GLES=OFF \
  -DENABLE_SOFTWARE=ON \
  -DENABLE_LIBINPUT=ON \
  -DENABLE_UDEV=ON \
  -DENABLE_KMS=OFF \
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
