#!/usr/bin/env python3
"""Print shell assignments locating the boot partition of a disk image.

Used by both mod-moss-image.sh and the workflow that verifies its output.
It lives in one file because the two had separate copies of this logic, the
verify copy matched on the GPT partition name only, and it found nothing on a
runner whose sfdisk does not report one.

Emits OFF, SZ, STARTSEC and SECSZ for `eval`.
"""
import json
import subprocess
import sys

EFI_GUID = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B"


def main(image):
    raw = subprocess.run(
        ["sfdisk", "-J", image], capture_output=True, text=True, check=True
    ).stdout
    table = json.loads(raw)["partitiontable"]
    sector = table.get("sectorsize", 512)
    parts = table["partitions"]

    # Try each identifier in turn rather than trusting one: sfdisk reports the
    # type as a GUID on GPT and a hex code on MBR, and only sometimes reports a
    # human-readable name.
    def by_type(p):
        return p.get("type", "").upper() in (EFI_GUID, "EF", "0XEF", "C")

    def by_name(p):
        return "EFI System" in p.get("name", "")

    for match in (by_type, by_name):
        found = [p for p in parts if match(p)]
        if len(found) == 1:
            break
    else:
        # Last resort: the boot partition is the largest one, by a wide margin
        # on these images. Better than guessing an offset.
        found = [max(parts, key=lambda p: p["size"])]
        print("# warning: fell back to largest-partition heuristic", file=sys.stderr)

    if len(found) != 1:
        sys.exit("could not identify a single boot partition (found %d)" % len(found))

    p = found[0]
    print("OFF=%d" % (p["start"] * sector))
    print("SZ=%d" % (p["size"] * sector))
    print("STARTSEC=%d" % p["start"])
    print("SECSZ=%d" % sector)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: locate-boot-part.py <disk.img>")
    main(sys.argv[1])
