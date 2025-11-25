#!/bin/bash
set -e

# Directory setup
BUILD_DIR="build_sw"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Clone flutter-pi if not present
if [ ! -d "flutter-pi" ]; then
    curl -L -o flutter-pi.zip https://github.com/ardera/flutter-pi/archive/refs/heads/master.zip
    unzip flutter-pi.zip
    mv flutter-pi-master flutter-pi
fi
cd flutter-pi

# APPLY FBDEV PATCH (USING PYTHON FOR ROBUSTNESS)
# We use a python script to safely inject the code.
if ! grep -q "init_fbdev" src/flutter-pi.c; then
    echo "Injecting FBDEV code into src/flutter-pi.c..."
    
    # Ensure python script is available
    # In CI, the script is in linux/patch_flutter_pi.py relative to repo root
    # The build runs in build_sw/flutter-pi
    # So we need to find it.
    
    PATCH_SCRIPT=""
    if [ -f "../../../linux/patch_flutter_pi.py" ]; then
        PATCH_SCRIPT="../../../linux/patch_flutter_pi.py"
    elif [ -f "../../linux/patch_flutter_pi.py" ]; then
        PATCH_SCRIPT="../../linux/patch_flutter_pi.py"
    elif [ -f "../patch_flutter_pi.py" ]; then
        PATCH_SCRIPT="../patch_flutter_pi.py"
    else
        echo "ERROR: Patch script not found!"
        exit 1
    fi
    
    python3 "$PATCH_SCRIPT" src/flutter-pi.c
    
    echo "FBDEV injection complete."
else
    echo "FBDEV code already present."
fi

# Create build directory
mkdir -p build
cd build

# CONFIGURE CMAKE FOR SOFTWARE RENDERING
# - ENABLE_SOFTWARE=ON: Enables software rendering support
# - ENABLE_OPENGL=ON: Required to satisfy CMake build requirements (even if we don't use it)
# - ENABLE_KMS=ON: Required to satisfy CMake build requirements (linked but not used due to patch)
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
  || (cat CMakeFiles/CMakeError.log && exit 1)

# Build
echo "Building flutter-pi (Software)..."
make -j$(nproc) || make -j1

echo "------------------------------------------------"
echo "Build complete."
echo "Binary is at: $(pwd)/flutter-pi"
echo "Check linked libraries with: ldd flutter-pi"
echo "------------------------------------------------"
