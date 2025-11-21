#!/bin/bash

# PortMaster/Rocknix Launch Script for Flutter App (via flutter-pi)

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

# Add current directory to library path so it finds libflutter_engine.so
export LD_LIBRARY_PATH="$GAMEDIR:$LD_LIBRARY_PATH"
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

echo "Attempting to launch on a new Virtual Terminal (VT)..."

# Try using openvt first (cleaner method)
if command -v openvt >/dev/null 2>&1; then
    echo "Using openvt to launch flutter-pi..."
    # -s: switch to the new VT
    # -w: wait for command to complete
    # --: end of openvt options
    openvt -s -w -- ./flutter-pi --release ./flutter_assets
    EXIT_CODE=$?
else
    echo "openvt not found, falling back to manual VT switch..."
    
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
    # Run flutter-pi
    ./flutter-pi --release ./flutter_assets
    EXIT_CODE=$?

    # Switch back to original VT
    echo "Switching back to VT $CURRENT_VT"
    chvt $CURRENT_VT
fi

echo "flutter-pi exited with code $EXIT_CODE"

