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

echo "Launching flutter-pi..."
# Run flutter-pi
./flutter-pi --release ./flutter_assets

EXIT_CODE=$?
echo "flutter-pi exited with code $EXIT_CODE"

