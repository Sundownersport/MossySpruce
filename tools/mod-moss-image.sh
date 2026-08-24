#!/bin/bash
# Turn a stock Moss release image into one that can boot spruceOS, without
# building the distribution.
#
# BACKUP PLAN. The supported path is building MossySpruce from source; this
# exists to get a bootable card sooner, and to have something to fall back on
# if the buildroot stays broken.
#
# Only one change is actually required. spruce refers to /mnt/SDCARD in ~1850
# places, Moss mounts TF2 at /storage/roms, and there is no /mnt in its root at
# all - verified against MOSS-RGB30-install-20231014: the root holds bin dev etc
# flash lib media proc roms run sbin storage sys system tmp usr var, nothing
# creates /mnt at boot, and the root is a read-only squashfs so it cannot be
# made at runtime. So a directory and a symlink go into the squashfs, and
# everything else spruce needs lives on TF2.
#
# What this deliberately does NOT change:
#   - DISTRONAME stays MOSS. Renaming it here would mean rewriting os-release
#     and the update guard for no benefit, but see the warning at the end.
#   - The frontend hand-off stays MinUI-shaped. Put the spruce launcher at
#     .system/rgb30/paks/MinUI.pak/launch.sh on TF2 and Moss will exec it.
#
# Needs root (squashfs ownership) and: squashfs-tools built with lzo, mtools,
# util-linux, gzip. Run it in CI rather than on a laptop.

set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }
note() { echo "==> $*"; }

[ "$(id -u)" -eq 0 ] || die "must run as root - unsquashfs/mksquashfs need it to preserve file ownership"

SRC="${1:-}"
OUT="${2:-MOSSYSPRUCE-RGB30.img.gz}"
[ -n "$SRC" ] || die "usage: $0 <MOSS-RGB30-install-*.img.gz> [output.img.gz]"
[ -f "$SRC" ] || die "no such file: $SRC"

for t in unsquashfs mksquashfs mcopy sfdisk gzip md5sum python3; do
    command -v "$t" >/dev/null || die "missing required tool: $t"
done
mksquashfs -help 2>&1 | grep -q lzo || die "mksquashfs has no lzo support - the Moss SYSTEM is lzo compressed"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

note "decompressing"
gzip -dc "$SRC" > "$WORK/disk.img"

# The boot partition is found, not assumed: it is the EFI System partition.
note "locating the boot partition"
eval "$(python3 "$(dirname "$0")/locate-boot-part.py" "$WORK/disk.img")"
[ -n "${OFF:-}" ] || die "boot partition not located"
note "boot partition at byte $OFF, size $SZ"

note "extracting boot partition"
dd if="$WORK/disk.img" of="$WORK/boot.fat" bs="$SECSZ" skip="$STARTSEC" count=$((SZ / SECSZ)) status=none

note "pulling SYSTEM"
mcopy -i "$WORK/boot.fat" ::SYSTEM "$WORK/SYSTEM"
mcopy -i "$WORK/boot.fat" ::SYSTEM.md5 "$WORK/SYSTEM.md5.orig"

# Fail loudly if the image was already tampered with, rather than building on
# top of an unknown base.
note "verifying the stock SYSTEM checksum"
want="$(awk '{print $1}' "$WORK/SYSTEM.md5.orig")"
have="$(md5sum "$WORK/SYSTEM" | awk '{print $1}')"
[ "$want" = "$have" ] || die "SYSTEM checksum mismatch (recorded $want, actual $have) - is this a stock image?"

note "unpacking the root filesystem"
unsquashfs -no-progress -d "$WORK/root" "$WORK/SYSTEM" >/dev/null

[ -e "$WORK/root/mnt" ] && die "/mnt already exists in this image - it may already be modified"
[ -d "$WORK/root/storage" ] || die "/storage missing - this does not look like a JELOS-lineage root"

note "adding /mnt/SDCARD -> /storage/roms"
mkdir -p "$WORK/root/mnt"
ln -s /storage/roms "$WORK/root/mnt/SDCARD"

# Order the UI after the games card is mounted. The stock image starts the UI
# (minui.service) with no ordering against jelos-automount, and automount's own
# `Before=autostart.service` names a unit that does not exist - the real one is
# jelos-autostart.service - so the ordering edge is silently dropped and the two
# race. When TF2's FAT is dirty, automount's fsck is slow, the UI wins the race,
# checks for the launcher before /storage/roms is mounted, and shows the
# "missing frontend" screen then powers off. First boot after a fresh install
# works; every boot after an unclean poweroff does not. Two independent fixes so
# it cannot regress if one unit changes upstream.
note "ordering the UI after jelos-automount"
UNIT_DIR="$WORK/root/usr/lib/systemd/system"
[ -f "$UNIT_DIR/minui.service" ] || die "minui.service missing - stock image layout changed"
[ -f "$UNIT_DIR/jelos-automount.service" ] || die "jelos-automount.service missing - stock image layout changed"

# 1) make the UI wait for the mount
if ! grep -q '^After=.*jelos-automount' "$UNIT_DIR/minui.service"; then
    sed -i '/^\[Unit\]/a After=jelos-automount.service\nWants=jelos-automount.service' "$UNIT_DIR/minui.service"
fi
grep -q '^After=.*jelos-automount' "$UNIT_DIR/minui.service" || die "failed to order minui.service after jelos-automount"

# 2) fix automount's dead ordering typo. Warn rather than die: if upstream ever
#    corrects it, the fix above still stands on its own.
if grep -q '^Before=autostart\.service$' "$UNIT_DIR/jelos-automount.service"; then
    sed -i 's/^Before=autostart\.service$/Before=jelos-autostart.service/' "$UNIT_DIR/jelos-automount.service"
else
    note "  (jelos-automount no longer has the Before=autostart.service typo - skipping)"
fi

note "repacking (lzo, 512K blocks, matching the stock image)"
rm -f "$WORK/SYSTEM.new"
mksquashfs "$WORK/root" "$WORK/SYSTEM.new" \
    -comp lzo -b 524288 -noappend -no-progress -no-recovery >/dev/null

NEW_SIZE=$(stat -c%s "$WORK/SYSTEM.new")
note "new SYSTEM is $((NEW_SIZE / 1048576)) MiB"

# The md5 file records a build-time path, not the on-card one. Keep the exact
# format or the boot-time check fails.
printf '%s  target/SYSTEM\n' "$(md5sum "$WORK/SYSTEM.new" | awk '{print $1}')" > "$WORK/SYSTEM.md5"

note "writing SYSTEM back into the boot partition"
mcopy -i "$WORK/boot.fat" -o "$WORK/SYSTEM.new" ::SYSTEM
mcopy -i "$WORK/boot.fat" -o "$WORK/SYSTEM.md5" ::SYSTEM.md5

note "verifying the written copy round-trips"
mcopy -i "$WORK/boot.fat" ::SYSTEM "$WORK/SYSTEM.check"
cmp -s "$WORK/SYSTEM.new" "$WORK/SYSTEM.check" || die "SYSTEM did not write back intact"

note "writing the boot partition back into the image"
dd if="$WORK/boot.fat" of="$WORK/disk.img" bs="$SECSZ" seek="$STARTSEC" conv=notrunc status=none

note "compressing to $OUT"
gzip -c "$WORK/disk.img" > "$OUT"

cat <<MSG

Done: $OUT

Write it to TF1, then put spruce on TF2 with a launcher at
  .system/rgb30/paks/MinUI.pak/launch.sh

Two things to know about a card built this way:

  DISTRONAME is still MOSS, so a genuine Moss update will happily install over
  this and silently undo the change. Do not accept one.

  spruce detection keys off OS_NAME="MOSSYSPRUCE" in /etc/os-release, which
  this image does not have. Either widen that check to accept MOSS, or the
  RGB30 will be detected as a Miyoo Flip - both are RK3566 and report the same
  cpuinfo.
MSG
