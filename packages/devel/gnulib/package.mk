# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gnulib"
# Match version with GNULIB_REVISION in grub bootstrap.conf
PKG_VERSION="9f48fb992a3d7e96610c4ce8be969cff2d61a01b"
PKG_LICENSE="GPL"
PKG_SITE="https://savannah.gnu.org/git/?group=gnulib"
# Same dead endpoint that broke configtools: cgit's snapshot route returns 400
# for every form of this URL. gitweb still serves snapshots, which is what
# UnofficialOS - a JELOS fork that is still maintained - moved to.
#
# PKG_SOURCE_NAME has to be set explicitly here. It is normally derived from
# the URL basename, and for a gitweb query string that derivation produces
# something ending in ";sf=tgz", which scripts/extract does not recognise as a
# tarball.
PKG_URL="http://git.savannah.gnu.org/gitweb/?p=${PKG_NAME}.git;a=snapshot;h=${PKG_VERSION};sf=tgz"
PKG_SOURCE_NAME="${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_LONGDESC="GNU portability library"
PKG_TOOLCHAIN="manual"
