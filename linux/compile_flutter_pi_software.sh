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

# APPLY FBDEV PATCH (USING SED FOR ROBUSTNESS)
# We use sed to inject the code directly, avoiding patch file context issues.
if ! grep -q "init_fbdev" src/flutter-pi.c; then
    echo "Injecting FBDEV code into src/flutter-pi.c..."

    # 1. Inject Headers
    sed -i '1i #include <fcntl.h>\n#include <sys/mman.h>\n#include <linux/fb.h>' src/flutter-pi.c

    # 2. Inject Globals and Functions before main
    sed -i '/int main(int argc, char \*\*argv) {/i \
// FBDEV HACK START \
static int fbfd = 0; \
static struct fb_var_screeninfo vinfo; \
static struct fb_fix_screeninfo finfo; \
static char *fbp = 0; \
\
static bool on_software_present(void *userdata, const void *allocation, size_t row_bytes, size_t height) { \
    if (!fbp) return false; \
    size_t bytes_to_copy = row_bytes * height; \
    size_t fb_size = vinfo.yres_virtual * finfo.line_length; \
    if (bytes_to_copy > fb_size) bytes_to_copy = fb_size; \
    memcpy(fbp, allocation, bytes_to_copy); \
    return true; \
} \
\
static void init_fbdev() { \
    fbfd = open("/dev/fb0", O_RDWR); \
    if (fbfd == -1) { perror("Error: cannot open framebuffer device"); exit(1); } \
    if (ioctl(fbfd, FBIOGET_FSCREENINFO, &finfo) == -1) { perror("Error reading fixed information"); exit(2); } \
    if (ioctl(fbfd, FBIOGET_VSCREENINFO, &vinfo) == -1) { perror("Error reading variable information"); exit(3); } \
    long screensize = vinfo.yres_virtual * finfo.line_length; \
    fbp = (char *)mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fbfd, 0); \
    if ((int)fbp == -1) { perror("Error: failed to map framebuffer device to memory"); exit(4); } \
    printf("FBDEV Initialized: %dx%d, %dbpp\\n", vinfo.xres, vinfo.yres, vinfo.bits_per_pixel); \
} \
// FBDEV HACK END' src/flutter-pi.c

    # 3. Inject init call in main
    sed -i '/int main(int argc, char \*\*argv) {/a \    init_fbdev();' src/flutter-pi.c

    # 4. Modify Renderer Config to use Software
    sed -i 's/config.type = kOpenGL;/config.type = kSoftware;/' src/flutter-pi.c
    sed -i 's/config.open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig);/config.software.struct_size = sizeof(FlutterSoftwareRendererConfig);/' src/flutter-pi.c
    sed -i 's/config.open_gl.make_current = on_make_current;/config.software.surface_present_callback = on_software_present;/' src/flutter-pi.c

    # 5. Comment out unused OpenGL callbacks
    sed -i 's/config.open_gl.clear_current/\/\/ config.open_gl.clear_current/' src/flutter-pi.c
    sed -i 's/config.open_gl.present/\/\/ config.open_gl.present/' src/flutter-pi.c
    sed -i 's/config.open_gl.fbo_callback/\/\/ config.open_gl.fbo_callback/' src/flutter-pi.c
    sed -i 's/config.open_gl.make_resource_current/\/\/ config.open_gl.make_resource_current/' src/flutter-pi.c

    # 6. Disable DRM/GBM setup calls (setup_paths, setup_config)
    sed -i 's/ok = setup_paths/\/\/ ok = setup_paths/' src/flutter-pi.c
    sed -i 's/ok = setup_config/\/\/ ok = setup_config/' src/flutter-pi.c
    
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

# Build
echo "Building flutter-pi (Software)..."
make -j$(nproc)

echo "------------------------------------------------"
echo "Build complete."
echo "Binary is at: $(pwd)/flutter-pi"
echo "Check linked libraries with: ldd flutter-pi"
echo "------------------------------------------------"
