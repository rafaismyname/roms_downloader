#!/bin/bash

# PortMaster/Rocknix/Batocera Launch Script for Flutter App (via flutter-pi)

# Get the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The game directory is assumed to be a subdirectory named 'roms_downloader'
# Structure:
# ports/roms_downloader.sh
# ports/roms_downloader/ (contains flutter-pi, libflutter_engine.so, flutter_assets)
GAMEDIR="$SCRIPT_DIR/roms_downloader"

# Setup logging
LOGFILE="$GAMEDIR/log.txt"
# Redirect stdout and stderr to the log file
exec > >(tee -a "$LOGFILE") 2>&1

echo "--- Starting Roms Downloader ---"
date
echo "Script Dir: $SCRIPT_DIR"
echo "Game Dir: $GAMEDIR"

if [ ! -d "$GAMEDIR" ]; then
    echo "ERROR: Game directory not found at $GAMEDIR"
    exit 1
fi

cd "$GAMEDIR"

# Ensure permissions
chmod +x ./flutter-pi

# Prepare runtime libs folder to selectively provide missing libraries
mkdir -p "$GAMEDIR/runtime_libs"
# Clean up previous links
rm -f "$GAMEDIR/runtime_libs"/*

# Function to check and link library if missing from system
check_and_link_lib() {
    local libname="$1"
    local found_path=""
    
    # Check common system locations
    for path in "/usr/lib/$libname" \
                "/usr/lib64/$libname" \
                "/lib/$libname" \
                "/usr/lib/aarch64-linux-gnu/$libname" \
                "/usr/local/lib/$libname"; do
        if [ -f "$path" ]; then
            found_path="$path"
            break
        fi
    done
    
    if [ -n "$found_path" ]; then
        echo "System $libname found at $found_path. Copying..."
        cp "$found_path" "$GAMEDIR/runtime_libs/$libname"
    else
        echo "System $libname NOT found. Using bundled version."
        if [ -f "$GAMEDIR/bundled_libs/$libname" ]; then
            cp "$GAMEDIR/bundled_libs/$libname" "$GAMEDIR/runtime_libs/$libname"
        else
            echo "WARNING: Bundled $libname also missing!"
        fi
    fi
}

# Check for problematic libraries
check_and_link_lib "libdrm.so.2"
check_and_link_lib "libgbm.so.1"
check_and_link_lib "libexpat.so.1"
check_and_link_lib "libinput.so.10"
check_and_link_lib "libevdev.so.2"
check_and_link_lib "libmtdev.so.1"
check_and_link_lib "libwacom.so.2"
check_and_link_lib "libgudev-1.0.so.0"
check_and_link_lib "libudev.so.1"
check_and_link_lib "libxkbcommon.so.0"
check_and_link_lib "libffi.so.7"
check_and_link_lib "libfontconfig.so.1"
check_and_link_lib "libfreetype.so.6"
check_and_link_lib "libssl.so.1.1"
check_and_link_lib "libcrypto.so.1.1"
check_and_link_lib "libwayland-server.so.0"
check_and_link_lib "libwayland-client.so.0"
check_and_link_lib "libwayland-cursor.so.0"
check_and_link_lib "libwayland-egl.so.1"
check_and_link_lib "libsystemd.so.0"
check_and_link_lib "liblzma.so.5"
check_and_link_lib "libzstd.so.1"
check_and_link_lib "liblz4.so.1"
check_and_link_lib "libgcrypt.so.20"
check_and_link_lib "libgpg-error.so.0"
check_and_link_lib "libcap.so.2"
check_and_link_lib "libmount.so.1"
check_and_link_lib "libblkid.so.1"
check_and_link_lib "libuuid.so.1"
check_and_link_lib "libselinux.so.1"
check_and_link_lib "libpcre2-8.so.0"
check_and_link_lib "libgobject-2.0.so.0"
check_and_link_lib "libglib-2.0.so.0"
check_and_link_lib "libpcre.so.3"

# Add runtime_libs and current directory to library path
export LD_LIBRARY_PATH="$GAMEDIR/runtime_libs:$GAMEDIR:$LD_LIBRARY_PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

# Set XDG environment variables to keep data self-contained
export XDG_DATA_HOME="$GAMEDIR/data"
export XDG_CONFIG_HOME="$GAMEDIR/config"
export XDG_CACHE_HOME="$GAMEDIR/cache"

# Set HOME to the game directory to ensure path_provider has a fallback
export HOME="$GAMEDIR"

# Explicitly set XDG_DOCUMENTS_DIR for getApplicationDocumentsDirectory
export XDG_DOCUMENTS_DIR="$GAMEDIR/Documents"

# Create these directories if they don't exist
mkdir -p "$XDG_DATA_HOME"
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_CACHE_HOME"
mkdir -p "$XDG_DOCUMENTS_DIR"

# Generate user-dirs.dirs to satisfy GLib (which path_provider uses)
# IMPORTANT: GLib only understands $HOME, not arbitrary variables like $GAMEDIR.
# We must write literal '$HOME' into the file.
echo 'XDG_DOCUMENTS_DIR="$HOME/Documents"' > "$XDG_CONFIG_HOME/user-dirs.dirs"
echo 'XDG_DOWNLOAD_DIR="$HOME/Downloads"' >> "$XDG_CONFIG_HOME/user-dirs.dirs"
echo 'XDG_DESKTOP_DIR="$HOME/Desktop"' >> "$XDG_CONFIG_HOME/user-dirs.dirs"
echo 'XDG_MUSIC_DIR="$HOME/Music"' >> "$XDG_CONFIG_HOME/user-dirs.dirs"
echo 'XDG_PICTURES_DIR="$HOME/Pictures"' >> "$XDG_CONFIG_HOME/user-dirs.dirs"
echo 'XDG_VIDEOS_DIR="$HOME/Videos"' >> "$XDG_CONFIG_HOME/user-dirs.dirs"

# Debug: Show content of generated file
cat "$XDG_CONFIG_HOME/user-dirs.dirs"

echo "XDG_DATA_HOME: $XDG_DATA_HOME"
echo "HOME: $HOME"

# Check for required files
if [ ! -f "./flutter-pi" ]; then
    echo "ERROR: flutter-pi binary missing!"
    ls -l
    exit 1
fi
if [ ! -f "./libflutter_engine.so" ]; then
    echo "ERROR: libflutter_engine.so missing!"
    ls -l
    exit 1
fi
if [ ! -d "./flutter_assets" ]; then
    echo "ERROR: flutter_assets directory missing!"
    ls -l
    exit 1
fi

echo "Launching on a new Virtual Terminal (VT)..."

# Get current VT
if command -v fgconsole >/dev/null 2>&1; then
    CURRENT_VT=$(fgconsole)
else
    CURRENT_VT=1
fi

# Determine target VT (swap between 1 and 2)
if [ "$CURRENT_VT" = "1" ]; then
    TARGET_VT=2
else
    TARGET_VT=1
fi

echo "Switching from VT $CURRENT_VT to VT $TARGET_VT"
chvt $TARGET_VT

# Wait for switch to complete and ES to release master
sleep 2

echo "Launching flutter-pi..."
# -d "150,85": Force ~6-inch screen dimensions
./flutter-pi --release -d "150,85" ./flutter_assets
EXIT_CODE=$?

# Switch back to original VT
echo "Switching back to VT $CURRENT_VT"
chvt $CURRENT_VT

echo "flutter-pi exited with code $EXIT_CODE"
