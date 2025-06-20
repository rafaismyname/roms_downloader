# Linux build (for macOS)

## Usage

```bash
# Build for current system architecture
./build_all.sh

# Build for all supported architectures
./build_all.sh --all

# Build for a specific architecture
./build_for_architecture.sh -a arm64

# Build for specific architectures
./build_all.sh arm64 amd64

# Build in debug mode
./build_all.sh -d arm64

# Build with debug mode
./build_for_architecture.sh -a arm64 -t Debug

# Clean build and rebuild
./build_all.sh -c --all

# Show help
./build_all.sh --help
```

#### Prerequisites
- Docker Desktop
- Docker Buildx (for multi-platform builds)


## Supported Architectures

- **native**: Build for current system architecture with optimizations
- **x86_64/amd64**: For standard 64-bit x86 Linux systems
- **aarch64/arm64**: For 64-bit ARM devices (Retroid Pocket 4 Pro, Anbernic RG556, etc.)

## Build Configurations

### Release Build (Default)
- Optimized for performance
- Smaller binary size
- No debug symbols

### Debug Build
- Includes debug symbols
- Larger binary size
- Better for development and troubleshooting

```bash
# Debug build example
./build_all.sh -d aarch64
```

## Output Structure

Built applications are organized as follows:

```
build/
├── bundles/
│   ├── roms_downloader_linux_x86_64/
│   └── roms_downloader_linux_aarch64/
├── linux_x86_64/
└── linux_aarch64/
```

Each bundle contains:
- Executable binary
- Required libraries
- Flutter assets
- Native plugins

## Deployment

### For Target Devices

1. Copy the appropriate bundle to your target device:
   ```bash
   scp -r build/bundles/roms_downloader_linux_aarch64/ user@device:/opt/
   ```

2. Make the executable runnable:
   ```bash
   chmod +x /opt/roms_downloader_linux_aarch64/ROMs\ Downloader
   ```

3. Run the application:
   ```bash
   cd /opt/roms_downloader_linux_aarch64/
   ./ROMs\ Downloader
   ```

## Troubleshooting

### Common Issues

1. **Missing dependencies**: Ensure all prerequisites are installed
2. **Architecture mismatch**: Verify you're building for the correct target architecture
3. **Permission errors**: Check file permissions and use `chmod +x` on executables
4. **Library issues**: Ensure target system has required GTK libraries
