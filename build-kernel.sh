#!/bin/bash

ARCHIVE_DIR="archives"
WORKDIR="$(pwd)"

KERNEL_VERSION="linux-6.6.29"

KERNEL_ARCHIVE="${KERNEL_VERSION}.tar.xz"

KERNEL_SITE="https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_ARCHIVE}"

JOBS="16"

mkdir -p "${ARCHIVE_DIR}"

if [ ! -f "${ARCHIVE_DIR}/${KERNEL_ARCHIVE}" ]; then
    wget -O "${ARCHIVE_DIR}/${KERNEL_ARCHIVE}" "${KERNEL_SITE}"
fi

echo "Patching kernel"

if [ ! -d "kernel" ]; then
    tar -xJf "${ARCHIVE_DIR}/${KERNEL_ARCHIVE}"
    mv "${KERNEL_VERSION}" kernel

    cd "${WORKDIR}/kernel"
    for i in "${WORKDIR}/patches/patches-6.6/"*; do patch -Np1 <"${i}"; done
    cp -rf "${WORKDIR}/patches/kernel-overlay/." ./

    cd "${WORKDIR}"
fi

echo "Building kernel..."

cd "${WORKDIR}/kernel"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
mkdir -p build "${WORKDIR}/deploy/modules"
make O=build photonicat_defconfig
make O=build Image -j${JOBS}
make O=build modules -j${JOBS}
make O=build rockchip/rk3568-photonicat.dtb
cp -v build/arch/arm64/boot/Image "${WORKDIR}/deploy"
cp -v build/arch/arm64/boot/dts/rockchip/rk3568-photonicat.dtb "${WORKDIR}/deploy"
make O=build modules_install INSTALL_MOD_PATH="${WORKDIR}/deploy/modules" INSTALL_MOD_STRIP=1
tar --xform s:'^./':: -czf "${WORKDIR}/deploy/kmods.tar.gz" -C "${WORKDIR}/deploy/modules" .

cd "${WORKDIR}"
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -d scripts/photonicat.bootscript deploy/boot.scr

echo "Kernel builds completed."
