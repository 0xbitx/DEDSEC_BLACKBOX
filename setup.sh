#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -eq 0 ]]; then
  SUDO=()
else
  SUDO=(sudo)
fi

echo "[*] Installing system + build dependencies ..."
"${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive apt-get update
"${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  python3 python3-pip wget \
  python3-requests python3-tabulate \
  build-essential make upx

TOOLCHAINS_DIR="${PWD}/toolchains"
BEARSSL_OUT="${TOOLCHAINS_DIR}/bearssl"
mkdir -p "$TOOLCHAINS_DIR"

if [[ -f "BearSSL.tar.gz" ]]; then
  tar -xf "BearSSL.tar.gz"
elif [[ -d "BearSSL" ]]; then
  echo "[*] Using existing BearSSL/ source tree."
else
  echo "[!] BearSSL source not found (need BearSSL.tar.gz or BearSSL/)."
  exit 1
fi

echo
echo "[*] Building host BearSSL lib -> ${BEARSSL_OUT}/host ..."
BS_CFLAGS="-W -Wall -Os -ffunction-sections -fdata-sections -fno-pic -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector"
rm -rf "$BEARSSL_OUT/host" "BearSSL/build"
( cd BearSSL && make lib CC=gcc AR=gcc-ar CFLAGS="$BS_CFLAGS -flto" BUILD="$BEARSSL_OUT/host" )
echo "[+] BearSSL host lib: ${BEARSSL_OUT}/host/libbearssl.a"

fetch_toolchain() {
  local label="$1"
  local url="$2"
  local name="$3"
  local src="$4"
  local triple="$5"
  local dest="${TOOLCHAINS_DIR}/${name}"
  local marker="${dest}/bin/${triple}-g++"
  local archive

  if [[ -x "$marker" ]]; then
    echo "[*] ${label} already installed, skipping."
    return
  fi

  if [[ -d "$dest" ]]; then
    echo "[!] Removing incomplete ${dest} ..."
    rm -rf "$dest"
  fi

  if [[ -d "$src" ]]; then
    echo "[!] Removing incomplete ${src} ..."
    rm -rf "$src"
  fi

  archive="$(basename "$url")"
  echo "[*] Downloading ${label} ..."
  wget -O "$archive" "$url"
  tar xf "$archive"
  rm -f "$archive"

  if [[ ! -x "${src}/bin/${triple}-g++" ]]; then
    echo "[!] Expected toolchain not found at ${src}"
    exit 1
  fi

  mv "$src" "$dest"
  echo "[+] ${label} -> ${dest}"
}

echo
echo "[*] Downloading all cross-toolchains into ${TOOLCHAINS_DIR} ..."

fetch_toolchain "ARMv7 musl toolchain" \
  "https://toolchains.bootlin.com/downloads/releases/toolchains/armv7-eabihf/tarballs/armv7-eabihf--musl--stable-2022.08-1.tar.bz2" \
  "armv7-musl" "armv7-eabihf--musl--stable-2022.08-1" "arm-buildroot-linux-musleabihf"

fetch_toolchain "ARMv5 musl toolchain" \
  "https://toolchains.bootlin.com/downloads/releases/toolchains/armv5-eabi/tarballs/armv5-eabi--musl--stable-2022.08-1.tar.bz2" \
  "armv5-musl" "armv5-eabi--musl--stable-2022.08-1" "arm-buildroot-linux-musleabi"

fetch_toolchain "AArch64 musl toolchain" \
  "https://musl.cc/aarch64-linux-musl-cross.tgz" \
  "aarch64-musl" "aarch64-linux-musl-cross" "aarch64-linux-musl"

fetch_toolchain "x86_64 musl toolchain" \
  "https://musl.cc/x86_64-linux-musl-cross.tgz" \
  "x86_64-musl" "x86_64-linux-musl-cross" "x86_64-linux-musl"

fetch_toolchain "MIPS BE musl toolchain" \
  "https://toolchains.bootlin.com/downloads/releases/toolchains/mips32/tarballs/mips32--musl--stable-2022.08-1.tar.bz2" \
  "mips-be-musl" "mips32--musl--stable-2022.08-1" "mips-buildroot-linux-musl"

fetch_toolchain "MIPS LE musl toolchain" \
  "https://toolchains.bootlin.com/downloads/releases/toolchains/mips32el/tarballs/mips32el--musl--stable-2022.08-1.tar.bz2" \
  "mips-le-musl" "mips32el--musl--stable-2022.08-1" "mipsel-buildroot-linux-musl"

echo
echo "[+] Toolchains in ${TOOLCHAINS_DIR}:"
find "$TOOLCHAINS_DIR" -maxdepth 1 -mindepth 1 -type d ! -name bearssl -printf '    %f\n' | sort
echo "[+] BearSSL output: ${BEARSSL_OUT}"
echo
echo "[+] Setup complete."
echo "    Run the C2 server:  sudo python3 dedsec_blackbox.py"
