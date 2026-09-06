#!/usr/bin/env python3
from pathlib import Path
import shutil
import subprocess

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE_SVG = ROOT / "AppIcon.svg"
SOURCE_PNG = ROOT / "AppIcon.png"
ICONSET = ROOT / "AppIcon.iconset"
ROOT_ICNS = ROOT / "AppIcon.icns"
RESOURCE_ICNS = ROOT / "Sources" / "App" / "Resources" / "AppIcon.icns"


def save_iconset(source: Image.Image) -> None:
    if ICONSET.exists():
        shutil.rmtree(ICONSET)
    ICONSET.mkdir()
    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]
    for pixels, name in sizes:
        source.resize((pixels, pixels), Image.Resampling.LANCZOS).save(ICONSET / name)


def main() -> None:
    subprocess.run(
        ["sips", "-s", "format", "png", str(SOURCE_SVG), "--out", str(SOURCE_PNG)],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    source = Image.open(SOURCE_PNG).convert("RGBA")
    if source.size != (1024, 1024):
        source = source.resize((1024, 1024), Image.Resampling.LANCZOS)
        source.save(SOURCE_PNG)

    save_iconset(source)
    subprocess.run(["iconutil", "-c", "icns", str(ICONSET), "-o", str(ROOT_ICNS)], check=True)
    shutil.copy2(ROOT_ICNS, RESOURCE_ICNS)
    print(f"Wrote {SOURCE_PNG}")
    print(f"Wrote {ROOT_ICNS}")
    print(f"Wrote {RESOURCE_ICNS}")


if __name__ == "__main__":
    main()
