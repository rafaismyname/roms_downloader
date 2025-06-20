#!/bin/bash
# filepath: launcher.sh
# chmod +x launcher.sh

# ROMs Downloader Launcher for Batocera/RocknixOS

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"

# Application executable name (adjust if different)
APP_EXECUTABLE="roms_downloader"

# Check if we're in the right directory
if [ ! -f "$APP_DIR/$APP_EXECUTABLE" ]; then
    echo "Error: $APP_EXECUTABLE not found in $APP_DIR"
    echo "Please ensure this script is in the same directory as the application"
    exit 1
fi

# Set up environment variables for Flutter/GTK
export DISPLAY=:0.0
export XDG_RUNTIME_DIR="/tmp/runtime-root"
export GDK_BACKEND=x11

# Create runtime directory if it doesn't exist
mkdir -p "$XDG_RUNTIME_DIR"

# Set library path to include local libs
export LD_LIBRARY_PATH="$APP_DIR/lib:$LD_LIBRARY_PATH"

# Change to app directory
cd "$APP_DIR"

# Make sure the executable has proper permissions
chmod +x "$APP_EXECUTABLE"

# Launch the application
echo "Starting ROMs Downloader..."
"./$APP_EXECUTABLE" "$@"

# Capture exit code
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "Application exited with code: $EXIT_CODE"
    echo "Press any key to continue..."
    read -n 1
fi

exit $EXIT_CODE