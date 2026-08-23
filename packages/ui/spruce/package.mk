# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2020-present Fewtarius

PKG_NAME="spruce"
PKG_VERSION="$(date +%Y%m%d)"
PKG_ARCH="any"
PKG_LICENSE=""
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain splash plymouth-lite SDL SDL_image SDL_ttf SDL2 SDL2_image SDL2_ttf wireplumber librga"
PKG_LONGDESC="spruceOS launcher hand-off"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/sources/start_spruce.sh ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/start_spruce.sh

  mkdir -p ${INSTALL}/usr/share/spruce
  cp -rf ${PKG_DIR}/sources/*.png ${INSTALL}/usr/share/spruce 2>/dev/null || true

  # spruce hardcodes /mnt/SDCARD in ~1850 places across ~320 files, and the
  # rootfs is a read-only squashfs, so the link cannot be made at runtime.
  # Baking it here is what lets spruce boot unmodified. /storage/roms is TF2,
  # mounted by jelos-automount before the UI service starts.
  mkdir -p ${INSTALL}/mnt
  ln -sf /storage/roms ${INSTALL}/mnt/SDCARD
}
