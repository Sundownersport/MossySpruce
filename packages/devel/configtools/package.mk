# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2023-present Fewtarius

PKG_NAME="configtools"
PKG_VERSION="d4e37b5868ef910e3e52744c34408084bb13051c"
PKG_LICENSE="GPL"
PKG_SITE="https://git.savannah.gnu.org/cgit/config.git"
# cgit's snapshot endpoint now returns 400 for every form of this URL, over
# both http and https, so the tarball fetch cannot work any more. The git
# endpoint is up, and get_git handles a full SHA in PKG_VERSION directly.
PKG_URL="https://git.savannah.gnu.org/git/config.git"
PKG_GIT_CLONE_SINGLE="yes"
PKG_DEPENDS_HOST=""
PKG_LONGDESC="configtools"
PKG_TOOLCHAIN="manual"

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/configtools
  cp config.* ${TOOLCHAIN}/configtools
}
