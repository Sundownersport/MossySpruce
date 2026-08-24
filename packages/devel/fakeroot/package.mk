# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="fakeroot"
# Upstream rebased 'main', so the old dev commit 305c8a1b is gone from every
# branch. Pin the permanent release tag instead. The tag commit is NOT an
# ancestor of main, so we must also tell get_git to clone the tag directly -
# otherwise its "commit must be in `git log` of the cloned branch" check
# (scripts/get_git) fails the same way, 22 minutes into the build.
PKG_VERSION="6adff503fcf1f3f985d256f7d91f3ae3fa3e2add" # tag debian/1.32.1-1
PKG_GIT_CLONE_BRANCH="debian/1.32.1-1"
PKG_GIT_CLONE_SINGLE="yes"
PKG_LICENSE="GPL3"
PKG_SITE="https://salsa.debian.org/clint/fakeroot"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_HOST="ccache:host libcap:host autoconf:host libtool:host"
PKG_LONGDESC="fakeroot provides a fake root environment by means of LD_PRELOAD and SYSV IPC (or TCP) trickery."
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_HOST="--with-gnu-ld"

pre_configure_host() {
  cd ${PKG_BUILD}
  ./bootstrap
}
