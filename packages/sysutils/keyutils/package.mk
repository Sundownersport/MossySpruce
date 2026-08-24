# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2023-present Fewtarius

PKG_NAME="keyutils"
PKG_VERSION="1.6.1"
PKG_LICENSE="GPL"
# Upstream lived on people.redhat.com, which Red Hat decommissioned - the fetch
# just times out. Pull the identical upstream tarball from Debian's permanent
# orig-tarball pool instead (bit-for-bit the same 1.6.1 release, unpacks to
# keyutils-1.6.1/). PKG_SOURCE_NAME keeps the cached file canonically named
# despite Debian's keyutils_1.6.1.orig.tar.bz2 basename.
PKG_SITE="https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git/"
PKG_URL="http://deb.debian.org/debian/pool/main/k/keyutils/${PKG_NAME}_${PKG_VERSION}.orig.tar.bz2"
PKG_SOURCE_NAME="${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Keyutils is a set of utilities for managing the key retention facility in the kernel."
PKG_BUILD_FLAGS="+pic"

PKG_MAKE_OPTS_TARGET="NO_ARLIB=0 NO_SOLIB=1 BINDIR=/usr/bin SBINDIR=/usr/sbin LIBDIR=/usr/lib USRLIBDIR=/usr/lib"
PKG_MAKEINSTALL_OPTS_TARGET="${PKG_MAKE_OPTS_TARGET}"

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/share
  rmdir ${INSTALL}/etc/request-key.d
  ln -sf /storage/.config/request-key.d ${INSTALL}/etc/request-key.d
}
