#!/bin/sh
#
# Hand control to spruceOS on TF2.
#
# /mnt/SDCARD is a symlink to /storage/roms, baked into the image by this
# package (the rootfs is read-only, so it cannot be created here). TF2 itself
# is mounted by jelos-automount, which runs before the UI service.
#
# Keep this dumb. Everything spruce-specific belongs on the card, in
# .tmp_update/rgb30.sh -- the same split the Anbernic H700 hand-off uses.

SDCARD_PATH="/storage/roms"
ENTRY_PATH="/mnt/SDCARD/.tmp_update/rgb30.sh"
IMAGE_PATH="/usr/share/spruce"

# JELOS runs fsck -Mly over TF2 on every boot and leaves these behind in the
# card root, where users see them.
rm -f "$SDCARD_PATH"/FSCK*.REC 2>/dev/null

if [ ! -f "$ENTRY_PATH" ]; then
	[ -f "$IMAGE_PATH/missing.png" ] && ply-image "$IMAGE_PATH/missing.png"
	sleep 10
	poweroff
fi

# spruce's principal.sh has its own loop; this is the outer safety net, and
# mirrors the ::respawn: that the H700 line gets from inittab.
while [ -f "$ENTRY_PATH" ]; do
	/bin/sh "$ENTRY_PATH"
done
