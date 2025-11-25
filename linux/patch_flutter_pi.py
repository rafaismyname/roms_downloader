import sys
import re

def patch_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # 1. Inject Headers
    headers = """#define _GNU_SOURCE
#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <linux/fb.h>
"""
    content = content.replace("#define _GNU_SOURCE\n#include <stdio.h>", headers)

    # 2. Inject Globals and Functions (before main)
    fbdev_code = """
// FBDEV HACK START
static int fbfd = 0;
static struct fb_var_screeninfo vinfo;
static struct fb_fix_screeninfo finfo;
static char *fbp = 0;

static bool on_software_present(void *userdata, const void *allocation, size_t row_bytes, size_t height) {
    if (!fbp) return false;
    size_t bytes_to_copy = row_bytes * height;
    size_t fb_size = vinfo.yres_virtual * finfo.line_length;
    if (bytes_to_copy > fb_size) bytes_to_copy = fb_size;
    memcpy(fbp, allocation, bytes_to_copy);
    return true;
}

static void init_fbdev() {
    fbfd = open("/dev/fb0", O_RDWR);
    if (fbfd == -1) { perror("Error: cannot open framebuffer device"); exit(1); }
    if (ioctl(fbfd, FBIOGET_FSCREENINFO, &finfo) == -1) { perror("Error reading fixed information"); exit(2); }
    if (ioctl(fbfd, FBIOGET_VSCREENINFO, &vinfo) == -1) { perror("Error reading variable information"); exit(3); }
    long screensize = vinfo.yres_virtual * finfo.line_length;
    fbp = (char *)mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fbfd, 0);
    if ((int)fbp == -1) { perror("Error: failed to map framebuffer device to memory"); exit(4); }
    printf("FBDEV Initialized: %dx%d, %dbpp\\n", vinfo.xres, vinfo.yres, vinfo.bits_per_pixel);
}
// FBDEV HACK END

int main(int argc, char **argv) {
"""
    content = content.replace("int main(int argc, char **argv) {", fbdev_code)

    # 3. Inject init call in main
    # Note: We already replaced the main signature above, so we don't need to do it again.
    # We just need to make sure init_fbdev() is called.
    # The replacement above puts the function definitions BEFORE main.
    # Now we need to insert the call INSIDE main.
    
    # We can find the start of main again (which is now followed by our injected code if we were careful, 
    # but actually the replace above replaced the signature itself).
    # Let's adjust: The replace above put the code BEFORE main, and kept the signature.
    # So "int main..." is still there.
    
    content = content.replace("int main(int argc, char **argv) {", "int main(int argc, char **argv) {\n    init_fbdev();")

    # 4. Modify Renderer Config
    # We look for the block where config is set and replace it entirely
    # This regex looks for "FlutterRendererConfig config = {0};" and captures until "FlutterProjectArgs args"
    pattern = re.compile(r"(FlutterRendererConfig config = \{0\};)(.*?)(FlutterProjectArgs args)", re.DOTALL)
    
    replacement = """FlutterRendererConfig config = {0};
    config.type = kSoftware;
    config.software.struct_size = sizeof(FlutterSoftwareRendererConfig);
    config.software.surface_present_callback = on_software_present;
    
    // config.open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig);
    // config.open_gl.make_current = on_make_current;
    // config.open_gl.clear_current = on_clear_current;
    // config.open_gl.present = on_present;
    // config.open_gl.fbo_callback = fbo_callback;
    // config.open_gl.make_resource_current = on_make_resource_current;

    FlutterProjectArgs args"""
    
    content = pattern.sub(replacement, content)

    # 5. Disable DRM setup calls
    content = content.replace("ok = setup_paths(&flutterpi);", "// ok = setup_paths(&flutterpi);")
    content = content.replace("ok = setup_config(&flutterpi);", "// ok = setup_config(&flutterpi);")

    with open(filepath, 'w') as f:
        f.write(content)

if __name__ == "__main__":
    patch_file(sys.argv[1])