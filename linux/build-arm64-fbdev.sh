#!/usr/bin/env bash

# Run with (on root of the project):
# docker run --rm -it --platform=linux/arm64 -v "$PWD":"$PWD" -w "$PWD" ubuntu:20.04 ./linux/build-arm64-fbdev.sh

set -euo pipefail

echo "[*] Starting ARM64 FBDEV build script"
echo "[*] CWD: $(pwd)"
echo "[*] uname: $(uname -a)"

REPO_ROOT="$(pwd)"
BUILD_ROOT="${REPO_ROOT}/.fbdev_build"

FLUTTER_DIR="${BUILD_ROOT}/flutter"
BUILD_FLUTTER_DIR="${BUILD_ROOT}/build_flutter"
DIST_ROOT="${BUILD_ROOT}/dist"
PORT_ROOT="${DIST_ROOT}/ports/roms_downloader"
BUNDLED_LIBS_DIR="${PORT_ROOT}/bundled_libs"
FLUTTER_ASSETS_DIR="${PORT_ROOT}/flutter_assets"

mkdir -p "${BUILD_ROOT}"

rm -rf "${BUILD_ROOT:?}/"*

# ---------------------------------------------------------------------------
# 1. System dependencies
# ---------------------------------------------------------------------------
echo "[*] Installing system dependencies via apt-get..."

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
    curl git unzip xz-utils zip build-essential cmake pkg-config \
    libc6-dev \
    libgl1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev \
    libdrm-dev libgbm-dev fontconfig \
    libsystemd-dev libinput-dev libudev-dev libxkbcommon-dev \
    libgtk-3-dev \
    ninja-build clang

echo "[*] System dependencies installed."

# ---------------------------------------------------------------------------
# 2. Install Flutter (Pinned to 3.35.4)
# ---------------------------------------------------------------------------
echo "[*] Cloning Flutter 3.35.4 into ${FLUTTER_DIR}..."
if [ ! -d "${FLUTTER_DIR}" ]; then
    git clone https://github.com/flutter/flutter.git -b 3.35.4 --depth 1 "${FLUTTER_DIR}"
else
    echo "    Flutter directory already exists, skipping clone."
fi

export PATH="$PATH:${FLUTTER_DIR}/bin"
git config --global --add safe.directory '*'

echo "[*] Running 'flutter config --enable-linux-desktop'..."
flutter config --enable-linux-desktop

# ---------------------------------------------------------------------------
# 3. Build flutter-pi (Patched for FBDEV)
# ---------------------------------------------------------------------------
echo "[*] Building flutter-pi with FBDEV patch..."

mkdir -p "${BUILD_FLUTTER_DIR}"
cd "${BUILD_FLUTTER_DIR}"

if [ ! -d "flutter-pi" ]; then
    echo "[*] Cloning flutter-pi..."
    git clone https://github.com/ardera/flutter-pi.git
fi

cd flutter-pi

echo "[*] Applying FBDEV patch (if not already applied)..."
patch -p1 -l --forward < "${REPO_ROOT}/linux/flutter-pi-fbdev.patch" || echo "    Patch already applied."

echo "[*] Configuring flutter-pi (CMake)..."
mkdir -p build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SESSION_SWITCHING=OFF \
    -DENABLE_VULKAN=OFF \
    -DENABLE_OPENGL=ON \
    -DENABLE_EGL=ON \
    -DENABLE_GLES=ON \
    -DENABLE_LIBINPUT=ON \
    -DENABLE_UDEV=ON \
    -DENABLE_KMS=ON \
    -DENABLE_X11=OFF \
    -DENABLE_WAYLAND=OFF \
    -DENABLE_TESTS=OFF \
    -DENABLE_SYSTEMD=OFF \
    -DENABLE_DBUS=OFF \
    || (cat CMakeFiles/CMakeError.log && exit 1)

echo "[*] Building flutter-pi..."
make -j"$(nproc)" || make -j1

# Copy binary into build root sandbox
cp flutter-pi "${BUILD_ROOT}/flutter-pi-bin"
echo "[*] flutter-pi built and copied to ${BUILD_ROOT}/flutter-pi-bin"

# ---------------------------------------------------------------------------
# 4. Build the Flutter app
# ---------------------------------------------------------------------------
cd "${REPO_ROOT}"

echo "[*] Running flutter pub get..."
flutter pub get

echo "[*] Building Flutter linux --release..."
flutter build linux --release --dart-define=DISABLE_ANIMATIONS=true

# ---------------------------------------------------------------------------
# 5. Prepare dist layout under .fbdev_build
# ---------------------------------------------------------------------------
echo "[*] Preparing dist layout under ${DIST_ROOT}..."

rm -rf "${DIST_ROOT}"
mkdir -p "${FLUTTER_ASSETS_DIR}"
mkdir -p "${BUNDLED_LIBS_DIR}"

# Copy flutter-pi binary
cp "${BUILD_ROOT}/flutter-pi-bin" "${PORT_ROOT}/flutter-pi"

# Copy flutter assets
echo "[*] Copying Flutter assets..."
cp -r build/linux/arm64/release/bundle/data/flutter_assets/* \
      "${FLUTTER_ASSETS_DIR}/"

# AOT blob
cp build/linux/arm64/release/bundle/lib/libapp.so \
   "${FLUTTER_ASSETS_DIR}/app.so"

# ---------------------------------------------------------------------------
# 6. Bundle shared libraries
# ---------------------------------------------------------------------------
echo "[*] Bundling shared libraries into ${BUNDLED_LIBS_DIR}..."

LIBS_TO_BUNDLE="libdrm.so.2 libgbm.so.1 libexpat.so.1 \
                libinput.so.10 libevdev.so.2 libmtdev.so.1 \
                libwacom.so.2 libgudev-1.0.so.0 libudev.so.1 \
                libgobject-2.0.so.0 libglib-2.0.so.0 libffi.so.7 libpcre.so.3 \
                libxkbcommon.so.0 \
                libwayland-server.so.0 libwayland-client.so.0 libwayland-cursor.so.0 libwayland-egl.so.1 \
                libsystemd.so.0 \
                libcap.so.2 libgcrypt.so.20 libgpg-error.so.0 \
                liblz4.so.1 liblzma.so.5 libzstd.so.1 \
                libmount.so.1 libblkid.so.1 libuuid.so.1 libselinux.so.1 libpcre2-8.so.0 \
                libfontconfig.so.1 libfreetype.so.6 libssl.so.1.1 libcrypto.so.1.1"

for LIB in $LIBS_TO_BUNDLE; do
    PATH_TO_LIB=$(find /usr/lib/aarch64-linux-gnu /lib/aarch64-linux-gnu /usr/lib /lib \
                  -name "$LIB" 2>/dev/null | head -n 1 || true)
    if [ -n "${PATH_TO_LIB:-}" ]; then
        echo "    Bundling $LIB from $PATH_TO_LIB"
        cp "$PATH_TO_LIB" "${BUNDLED_LIBS_DIR}/"
    else
        echo "    WARNING: $LIB not found in build environment!"
    fi
done

# ---------------------------------------------------------------------------
# 7. Download ARM64 engine binaries (sandboxed)
# ---------------------------------------------------------------------------
echo "[*] Downloading ARM64 Flutter engine into ${BUILD_ROOT}..."

cd "${BUILD_ROOT}"

curl -L -o engine.zip \
  "https://github.com/ardera/flutter-engine-binaries-for-arm/archive/refs/tags/engine_c29809135135e262a912cf583b2c90deb9ded610.zip"

unzip -q engine.zip
rm engine.zip

ENGINE_DIR="$(find . -maxdepth 1 -type d -name 'flutter-engine-binaries-for-arm-*' | head -n 1 || true)"
if [ -z "${ENGINE_DIR:-}" ]; then
    echo "ERROR: Could not find unpacked engine directory!"
    exit 1
fi

ENGINE_PATH="${ENGINE_DIR}/arm64/libflutter_engine.so.release"
if [ ! -f "$ENGINE_PATH" ]; then
   echo "ERROR: libflutter_engine.so.release not found in ${ENGINE_DIR}!"
   ls -R "${ENGINE_DIR}"
   exit 1
fi

cp "$ENGINE_PATH" "${PORT_ROOT}/libflutter_engine.so"
rm -rf "${ENGINE_DIR}"

# ---------------------------------------------------------------------------
# 8. ICU data
# ---------------------------------------------------------------------------
echo "[*] Locating ICU data (icudtl.dat)..."
cd "${REPO_ROOT}"

ICU_DATA_PATH=$(find build/linux/arm64/release/bundle -name "icudtl.dat" | head -n 1 || true)
if [ -z "${ICU_DATA_PATH:-}" ]; then
   echo "    ICU Data not found in bundle. Searching in Flutter cache..."
   ICU_DATA_PATH=$(find "${FLUTTER_DIR}/bin/cache/artifacts/engine" -name "icudtl.dat" | head -n 1 || true)
fi

if [ -z "${ICU_DATA_PATH:-}" ]; then
   echo "ERROR: icudtl.dat not found!"
   exit 1
fi

echo "    Found ICU data at: $ICU_DATA_PATH"
cp "$ICU_DATA_PATH" "${FLUTTER_ASSETS_DIR}/"

# ---------------------------------------------------------------------------
# 9. Copy launch script + create ZIP
# ---------------------------------------------------------------------------
echo "[*] Copying launch script..."
cp "${REPO_ROOT}/linux/roms_downloader_fbdev.sh" "${DIST_ROOT}/ports/roms_downloader.sh"
chmod +x "${DIST_ROOT}/ports/roms_downloader.sh"
chmod +x "${PORT_ROOT}/flutter-pi"

echo "[*] Creating zip inside ${BUILD_ROOT}..."
cd "${DIST_ROOT}"
ZIP_PATH="${BUILD_ROOT}/roms_downloader_portmaster_fbdev.zip"
rm -f "${ZIP_PATH}"
zip -r "${ZIP_PATH}" ports/ > /dev/null

echo "[*] Done!"
echo "[*] Output zip: ${ZIP_PATH}"