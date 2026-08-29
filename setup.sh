#!/usr/bin/env bash

set -euo pipefail

echo "[*] Installing system + build dependencies ..."
sudo apt-get update
sudo apt-get install -y \
  python3 python3-pip wget \
  python3-requests python3-tabulate \
  build-essential make upx \
  g++-arm-linux-gnueabihf g++-arm-linux-gnueabi g++-aarch64-linux-gnu

tar -xf "BearSSL.tar.gz"
rm -f "BearSSL.tar.gz"

echo
echo "[*] Building BearSSL static libs (x86_64 + ARMv7) ..."
( cd BearSSL && make clean && make lib CC=gcc AR=ar && cp build/libbearssl.a ../libbearssl_x86_64.a )
( cd BearSSL && make clean && make lib CC=arm-linux-gnueabihf-gcc AR=arm-linux-gnueabihf-ar && cp build/libbearssl.a ../libbearssl_arm.a )

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
