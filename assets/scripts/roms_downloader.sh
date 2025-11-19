#!/bin/bash

# PortMaster/Rocknix Launch Script for Flutter App (via flutter-pi)

# Set the directory to the script's location
# We assume the game data is in /roms/ports/roms_downloader/
GAMEDIR="/roms/ports/roms_downloader"

# If the script is run from a different location, try to detect it
if [ ! -d "$GAMEDIR" ]; then
    GAMEDIR="$(dirname "$0")/roms_downloader"
fi

# Navigate to the game directory
cd "$GAMEDIR"

# Add current directory to library path so it finds libflutter_engine.so
export LD_LIBRARY_PATH="$GAMEDIR:$LD_LIBRARY_PATH"

# Configure flutter-pi
# We run in release mode and point to the flutter_assets directory
# The binary 'flutter-pi' and 'libflutter_engine.so' must be in this folder
./flutter-pi --release ./flutter_assets > /dev/null 2>&1
