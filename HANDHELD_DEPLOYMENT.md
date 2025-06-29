# ROMs Downloader - Handheld Linux Deployment Guide

This guide covers deploying ROMs Downloader on handheld Linux devices like Steam Deck, ANBERNIC devices, and retro gaming handhelds running Batocera, RockNIX, JELOS, or similar distributions.

## 🎮 Supported Handheld Platforms

### Fully Tested
- **Steam Deck** (SteamOS)
- **Batocera** (various devices)
- **RockNIX/JELOS** (ANBERNIC and similar devices)

### Expected to Work
- **ArkOS** 
- **RetroPie** (Raspberry Pi handhelds)
- **EmuELEC**
- **351ELEC**
- Any Linux handheld with X11/Wayland support

## 📦 Installation Methods

### Method 1: Handheld-Optimized Package (Recommended)

1. **Download** the handheld package for your architecture:
   - `ROMs_Downloader_Handheld_Linux_arm64.tar.gz` for ARM64 devices
   - `ROMs_Downloader_Handheld_Linux_x64.tar.gz` for x64 devices

2. **Extract** to your device:
   ```bash
   # For Batocera
   tar -xzf ROMs_Downloader_Handheld_Linux_*.tar.gz -C /userdata/roms_downloader/
   
   # For RockNIX/JELOS
   tar -xzf ROMs_Downloader_Handheld_Linux_*.tar.gz -C /storage/roms_downloader/
   
   # For Steam Deck
   tar -xzf ROMs_Downloader_Handheld_Linux_*.tar.gz -C ~/ROMs_Downloader/
   ```

3. **Make executable** and run:
   ```bash
   chmod +x start_roms_downloader.sh
   ./start_roms_downloader.sh
   ```

### Method 2: Standard AppImage

If the handheld package doesn't work, try the standard AppImage:

1. Download `ROMs_Downloader_Linux_*.AppImage`
2. Make it executable: `chmod +x ROMs_Downloader_Linux_*.AppImage`
3. Run directly: `./ROMs_Downloader_Linux_*.AppImage`

## 🔧 Platform-Specific Instructions

### Steam Deck (SteamOS)

1. **Switch to Desktop Mode**
2. **Open Konsole** (terminal)
3. **Create directory**: `mkdir -p ~/ROMs_Downloader`
4. **Extract handheld package** to this directory
5. **Run**: `./start_roms_downloader.sh`

**Adding to Steam:**
1. Add as Non-Steam Game
2. Set target to: `/home/deck/ROMs_Downloader/start_roms_downloader.sh`
3. Enable "Force the use of a specific Steam Play compatibility tool" if needed

### Batocera

1. **Access via SSH** or file manager
2. **Create directory**: `mkdir -p /userdata/roms_downloader`
3. **Upload and extract** the handheld package
4. **Run via SSH**: `cd /userdata/roms_downloader && ./start_roms_downloader.sh`

**Batocera Menu Integration:**
Create `/userdata/system/configs/emulationstation/es_systems.cfg` entry:
```xml
<system>
  <name>roms-downloader</name>
  <fullname>ROMs Downloader</fullname>
  <path>/userdata/roms_downloader</path>
  <extension>.sh</extension>
  <command>/userdata/roms_downloader/start_roms_downloader.sh</command>
</system>
```

### RockNIX/JELOS (ANBERNIC, etc.)

1. **Access via SSH** or network share
2. **Extract to**: `/storage/roms_downloader/`
3. **Set permissions**: `chmod +x /storage/roms_downloader/start_roms_downloader.sh`
4. **Run**: `cd /storage/roms_downloader && ./start_roms_downloader.sh`

### RetroPie (Raspberry Pi)

1. **SSH into device**: `ssh pi@retropie`
2. **Create directory**: `mkdir -p ~/ROMs_Downloader`
3. **Extract package** and run startup script

## ⚙️ Configuration

### Automatic Detection

The handheld build automatically detects:
- **Platform type** (Batocera, RockNIX, Steam Deck, etc.)
- **Default ROM paths** (`/storage/roms`, `/roms`, etc.)
- **Memory constraints** and optimizes accordingly
- **Touch interface** requirements

### Manual Configuration

If auto-detection fails, you can set environment variables:

```bash
export FLUTTER_HANDHELD_MODE=1
export ROMS_DEFAULT_PATH="/your/roms/path"
export XDG_DATA_HOME="/your/app/data/path"
```

### Storage Paths

The app will automatically detect and suggest:
- **Batocera**: `/storage/roms` or `/userdata/roms`
- **RockNIX/JELOS**: `/roms`
- **Steam Deck**: `~/ROMs` or `~/Documents/ROMs`
- **RetroPie**: `~/RetroPie/roms`

## 🎯 Performance Optimizations

The handheld build includes:

### Memory Optimizations
- **Reduced cache sizes** (50MB vs 200MB)
- **Limited concurrent downloads** (2 vs 4)
- **Garbage collection tuning**
- **Static linking** to reduce memory overhead

### UI Optimizations
- **Touch-friendly interface** when detected
- **Larger buttons and touch targets**
- **Simplified navigation** for gamepad/touch use
- **Auto-scrolling** for better accessibility

### Network Optimizations
- **Conservative download limits**
- **Better error handling** for unstable connections
- **Resume capability** for interrupted downloads

## 🔍 Troubleshooting

### Common Issues

**"Permission denied"**
```bash
chmod +x start_roms_downloader.sh
chmod +x roms_downloader
```

**"Library not found"**
- Use the handheld package (has static linking)
- Check if your device supports the architecture (ARM64 vs x64)

**"Display/X11 errors"**
```bash
export DISPLAY=:0
xhost +local:
```

**"Touch input not working"**
- Ensure you're using the handheld startup script
- Check that `FLUTTER_HANDHELD_MODE=1` is set

### Device-Specific Issues

**Steam Deck - "Steam Input conflicts"**
- Disable Steam Input for the app
- Run from Desktop Mode instead of Gaming Mode

**Batocera - "Network access denied"**
- Check network settings in Batocera menu
- Ensure device has internet connectivity

**ANBERNIC devices - "Performance issues"**
- Use ARM64 build if available
- Reduce concurrent downloads in settings
- Close other apps while using

### Debug Mode

Enable debug output:
```bash
export FLUTTER_DEBUG=1
./start_roms_downloader.sh 2>&1 | tee debug.log
```

## 📱 Controller Support

Current controller support is limited but planned. For now:

1. **Use touch interface** on touch-enabled devices
2. **Connect USB mouse** for precise navigation
3. **SSH access** for remote control via keyboard/mouse

**Planned Features:**
- D-pad navigation
- Button shortcuts
- Gamepad-friendly UI mode

## 🔄 Updates

To update the app:

1. **Download new handheld package**
2. **Backup your configuration** (usually in `./config/` directory)
3. **Extract new version** over old installation
4. **Restore configuration** if needed

## 🆘 Support

If you encounter issues:

1. **Check the debug log** (see Debug Mode above)
2. **Verify your platform** is supported
3. **Test with standard AppImage** as fallback
4. **Report issues** with:
   - Device model and firmware version
   - Architecture (ARM64 vs x64)
   - Full error messages
   - Debug log output

## 📋 System Requirements

### Minimum Requirements
- **Linux kernel 4.0+**
- **64MB RAM** available for the app
- **100MB storage** space
- **Network connectivity**
- **X11 or Wayland** display server

### Recommended
- **ARM64 or x64 architecture**
- **256MB RAM** available
- **Touch screen or mouse/gamepad** input
- **Wi-Fi connection** for downloading

### Tested Configurations
- **Steam Deck**: SteamOS 3.0+, works excellently
- **ANBERNIC RG552**: RockNIX, works well with touch
- **Batocera PC**: x64, full functionality
- **Raspberry Pi 4**: RetroPie, basic functionality
