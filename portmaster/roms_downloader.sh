#!/bin/bash
#
# SPDX-License-Identifier: MIT
#
# ROMs Downloader for PortMaster
# Description: A tool to download ROM collections from custom indexes
# Author: rafaismyname

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source "$controlfolder/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

get_controls

GAMEDIR="/$directory/ports/roms_downloader"

# Ensure game directory exists
mkdir -p "$GAMEDIR"

# Set up environment
export DEVICE_ARCH="${DEVICE_ARCH:-aarch64}"
export LD_LIBRARY_PATH="$GAMEDIR/lib:$LD_LIBRARY_PATH"
export PATH="$GAMEDIR:$PATH"

# Set SDL environment for handhelds
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Try to find and export system OpenGL/EGL libraries
if [ -d "/usr/lib" ]; then
  export LD_LIBRARY_PATH="/usr/lib:$LD_LIBRARY_PATH"
fi
if [ -d "/usr/lib64" ]; then
  export LD_LIBRARY_PATH="/usr/lib64:$LD_LIBRARY_PATH"
fi
if [ -d "/usr/lib/x86_64-linux-gnu" ]; then
  export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
fi

# Export OpenGL variables for software rendering fallback
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe

# Navigate to game directory
cd "$GAMEDIR" || exit 1

# Log file for debugging
LOGFILE="$GAMEDIR/log.txt"
echo "Starting ROMs Downloader at $(date)" > "$LOGFILE"

# Run the application
./roms_downloader >> "$LOGFILE" 2>&1

# Check exit code
ret_code=$?
echo "ROMs Downloader exited with code: $ret_code" >> "$LOGFILE"

# Clean up
$ESUDO kill -9 $(pidof gptokeyb) &> /dev/null
$ESUDO systemctl restart oga_events &> /dev/null
printf "\033c" > /dev/tty0

exit $ret_code
