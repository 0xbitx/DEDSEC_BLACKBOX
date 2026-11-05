#!/usr/bin/env bash

set -euo pipefail

echo "[*] Installing system + build dependencies ..."
sudo apt-get update
sudo apt-get install -y \
  python3 python3-pip wget \
  python3-requests python3-tabulate \
  build-essential make upx \
  g++-arm-linux-gnueabihf g++-arm-linux-gnueabi g++-aarch64-linux-gnu

if [[ -f "BearSSL.tar.gz" ]]; then
  tar -xf "BearSSL.tar.gz"
  rm -f "BearSSL.tar.gz"
elif [[ -d "BearSSL" ]]; then
  echo "[*] Using existing BearSSL/ source tree."
else
  echo "[!] BearSSL source not found (need BearSSL.tar.gz or BearSSL/)."
  exit 1
fi

echo
echo "[*] Building BearSSL static libs (x86_64 + ARMv7) ..."
BS_CFLAGS="-W -Wall -Os -ffunction-sections -fdata-sections -fno-pic -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-stack-protector"
( cd BearSSL && make clean && make lib CC=gcc AR=gcc-ar CFLAGS="$BS_CFLAGS -flto" && cp build/libbearssl.a ../libbearssl_x86_64.a )
( cd BearSSL && make clean && make lib CC=arm-linux-gnueabihf-gcc AR=arm-linux-gnueabihf-gcc-ar CFLAGS="$BS_CFLAGS -flto" && cp build/libbearssl.a ../libbearssl_arm.a )

echo
echo "[*] musl cross-toolchains (smallest ARMv7 / ARMv5 / AArch64 / x86_64 payloads) ..."
read -r -p "    Download musl toolchains now (~465 MB download, ~1.4 GB extracted)? (y/N) " ANS
if [[ "$ANS" =~ ^[Yy]$ ]]; then
    ARM7="armv7-eabihf--musl--stable-2022.08-1"
    URL="https://toolchains.bootlin.com/downloads/releases/toolchains/armv7-eabihf/tarballs/${ARM7}.tar.bz2"
    echo "[*] Downloading ${URL} ..."
    wget -O "${ARM7}.tar.bz2" "$URL"
    tar xf "${ARM7}.tar.bz2" && rm -f "${ARM7}.tar.bz2"

    ARM5="armv5-eabi--musl--stable-2022.08-1"
    URL="https://toolchains.bootlin.com/downloads/releases/toolchains/armv5-eabi/tarballs/${ARM5}.tar.bz2"
    echo "[*] Downloading ${URL} ..."
    wget -O "${ARM5}.tar.bz2" "$URL"
    tar xf "${ARM5}.tar.bz2" && rm -f "${ARM5}.tar.bz2"

    A64="aarch64-linux-musl-cross"
    echo "[*] Downloading https://musl.cc/${A64}.tgz ..."
    wget -O "${A64}.tgz" "https://musl.cc/${A64}.tgz"
    tar xf "${A64}.tgz" && rm -f "${A64}.tgz"

    X64="x86_64-linux-musl-cross"
    echo "[*] Downloading https://musl.cc/${X64}.tgz ..."
    wget -O "${X64}.tgz" "https://musl.cc/${X64}.tgz"
    tar xf "${X64}.tgz" && rm -f "${X64}.tgz"
    echo "[+] musl toolchains ready (payloads drop to ~63-83 KB)."
else
    echo "[!] Skipping musl toolchains. ARM/AArch64/x86_64 fall back to glibc (~220-300 KB)."
fi

echo

echo "[*] Bootlin MIPS BE toolchain (needed to build the 'mips' target) ..."
read -r -p "    Download the big-endian MIPS32 uclibc toolchain now? (y/N) " ANS
if [[ "$ANS" =~ ^[Yy]$ ]]; then
    SDK="mips32--uclibc--stable-2022.08-1"
    URL="https://toolchains.bootlin.com/downloads/releases/toolchains/mips32/tarballs/${SDK}.tar.bz2"
    echo "[*] Downloading ${URL} ..."
    wget -O "${SDK}.tar.bz2" "$URL"
    tar xf "${SDK}.tar.bz2"
    rm -f "${SDK}.tar.bz2"
    echo "[+] Bootlin MIPS BE toolchain ready."
else
    echo "[!] Skipping MIPS BE toolchain. You can build: debug / arm / armv5 / aarch64 now."
fi

echo
echo "[*] Bootlin MIPS LE toolchain (needed to build the 'mipsel' target) ..."
read -r -p "    Download the little-endian MIPS32 uclibc toolchain now? (y/N) " ANS
if [[ "$ANS" =~ ^[Yy]$ ]]; then
    SDK="mips32el--uclibc--stable-2022.08-1"
    URL="https://toolchains.bootlin.com/downloads/releases/toolchains/mips32el/tarballs/${SDK}.tar.bz2"
    echo "[*] Downloading ${URL} ..."
    wget -O "${SDK}.tar.bz2" "$URL"
    tar xf "${SDK}.tar.bz2"
    rm -f "${SDK}.tar.bz2"
    echo "[+] Bootlin MIPS LE toolchain ready."
else
    echo "[!] Skipping MIPS LE toolchain. You can build: debug / arm / armv5 / aarch64 now."
fi

echo
echo "[+] Setup complete."
echo "    Run the C2 server:  sudo ./dedsec_blackbox"
