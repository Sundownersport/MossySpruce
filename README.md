# MossySpruce

MossySpruce is the OS subsystem for [spruceOS](https://github.com/spruceUI/spruceOS) on the
Powkiddy RGB30. It is a fork of [Moss](https://github.com/shauninman/Moss), which is itself a
pared down fork of [JELOS](https://github.com/JustEnoughLinuxOS/distribution).

It lives on TF1 and does one job: bring the hardware up and hand control to spruceOS on TF2.

## How the hand-off works

```
jelos-automount.service  ->  mounts TF2 at /storage/roms
jelos-autostart.service  ->  starts $UI_SERVICE  (spruce.service on RK3566)
spruce.service           ->  /usr/bin/start_spruce.sh
start_spruce.sh          ->  /mnt/SDCARD/.tmp_update/rgb30.sh   (on TF2)
```

`/mnt/SDCARD` is a symlink to `/storage/roms`, baked into the image by
`packages/ui/spruce`. spruceOS refers to `/mnt/SDCARD` in roughly 1850 places, and the rootfs is
a read-only squashfs, so the link has to exist in the image rather than be created at boot. With
it in place spruceOS runs unmodified.

Everything device-specific belongs on the card in `.tmp_update/rgb30.sh`, not here. This mirrors
how spruceOS is bootstrapped on the Anbernic H700 line.

## Why the name change

JELOS refuses to install an update built by a differently-named distro, which stops a MossySpruce
image and a Moss or JELOS image from being flashed over each other and breaking both. Shaun renamed
his fork to Moss for exactly this reason; MossySpruce takes a third name for the same one. If you
fork this, rename it again.

## Building

`.github/workflows/build-rk3566.yaml` builds the RK3566 image on a GitHub-hosted runner. Trigger it
from the Actions tab. Upstream JELOS builds every platform on self-hosted infrastructure; this
builds only what the RGB30 needs.

## Licenses

JELOS software is Apache 2.0, copyright 2021-present Fewtarius. JELOS branding and images are
CC BY-NC-SA 4.0 and are not reused here. Bundled components are provided under their own licenses;
see the `licenses` folder.
