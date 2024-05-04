#!/bin/bash

ARCHIVE_DIR="archives"
WORKDIR="$(pwd)"

UBOOT_VERSION="u-boot-2023.04"

UBOOT_ARCHIVE="${UBOOT_VERSION}.tar.bz2"

UBOOT_SITE="https://ftp.denx.de/pub/u-boot/${UBOOT_ARCHIVE}"

JOBS="16"

export ROCKCHIP_TPL="${WORKDIR}/rkbin/bin/rk35/rk3568_ddr_1332MHz_v1.16.bin"
export BL31="${WORKDIR}/rkbin/bin/rk35/rk3568_bl31_v1.42.elf"

if [ ! -d "${ARCHIVE_DIR}" ]; then
    mkdir "${ARCHIVE_DIR}"
fi

if [ ! -f "${ARCHIVE_DIR}/${UBOOT_ARCHIVE}" ]; then
    wget -O "${ARCHIVE_DIR}/${UBOOT_ARCHIVE}" "${UBOOT_SITE}"
fi

if [ ! -d "u-boot" ]; then
    tar -xjf "${ARCHIVE_DIR}/${UBOOT_ARCHIVE}"
    mv "${UBOOT_VERSION}" u-boot

    cd "${WORKDIR}/u-boot"
    for i in "${WORKDIR}/patches/u-boot/"*; do patch -p1 < "${i}"; done
    cd "${WORKDIR}"
fi

echo "Building u-boot..."

cd "${WORKDIR}/u-boot"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
mkdir -p build "${WORKDIR}/deploy"
make O=build photonicat-rk3568_defconfig
make O=build -j${JOBS}
cp -v build/idbloader.img "${WORKDIR}/deploy"
cp -v build/u-boot.itb "${WORKDIR}/deploy"


echo "U-boot builds completed."
