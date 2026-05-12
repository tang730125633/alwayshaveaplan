#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import shutil
import subprocess


ROOT = Path(__file__).resolve().parent
ICONSET = ROOT / "AppIcon.iconset"
SOURCE_PNG = ROOT / "AppIcon.png"
ROOT_ICNS = ROOT / "AppIcon.icns"
RESOURCE_ICNS = ROOT / "Sources" / "App" / "Resources" / "AppIcon.icns"


def rounded_rect_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def vertical_gradient(size, top, bottom):
    img = Image.new("RGBA", (size, size), top)
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        eased = t * t * (3 - 2 * t)
        color = tuple(int(top[i] * (1 - eased) + bottom[i] * eased) for i in range(4))
        for x in range(size):
            px[x, y] = color
    return img


def shadow(layer_size, bbox, radius, blur, offset, opacity):
    layer = Image.new("RGBA", (layer_size, layer_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(bbox, radius=radius, fill=(0, 0, 0, opacity))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    shifted = Image.new("RGBA", (layer_size, layer_size), (0, 0, 0, 0))
    shifted.alpha_composite(layer, offset)
    return shifted


def get_font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            pass
    return ImageFont.load_default()


def draw_soft_grid(draw, size):
    # Reserved for future texture; currently intentionally blank for small-size clarity.
    return


def draw_icon(size=1024):
    scale = size / 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    bg = vertical_gradient(
        size,
        (36, 47, 64, 255),
        (21, 28, 42, 255),
    )
    bg_draw = ImageDraw.Draw(bg)
    # Keep the background quiet; app icons need to stay legible at 16px.
    draw_soft_grid(bg_draw, size)

    # Warm focus glow.
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        tuple(int(v * scale) for v in (480, 30, 1180, 760)),
        fill=(255, 99, 76, 42),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(int(90 * scale)))
    bg.alpha_composite(glow)

    mask = rounded_rect_mask(size, int(218 * scale))
    img.alpha_composite(bg)
    img.putalpha(mask)

    draw = ImageDraw.Draw(img)

    # Backing plan sheets.
    back_bbox = tuple(int(v * scale) for v in (232, 206, 804, 814))
    img.alpha_composite(shadow(size, back_bbox, int(92 * scale), int(34 * scale), (0, int(28 * scale)), 88))
    draw.rounded_rectangle(back_bbox, radius=int(92 * scale), fill=(214, 225, 235, 238))

    mid_bbox = tuple(int(v * scale) for v in (198, 250, 840, 846))
    img.alpha_composite(shadow(size, mid_bbox, int(88 * scale), int(26 * scale), (0, int(20 * scale)), 74))
    draw.rounded_rectangle(mid_bbox, radius=int(88 * scale), fill=(246, 249, 250, 255))

    # Main card.
    card_bbox = tuple(int(v * scale) for v in (184, 164, 840, 824))
    img.alpha_composite(shadow(size, card_bbox, int(96 * scale), int(42 * scale), (0, int(34 * scale)), 120))
    draw.rounded_rectangle(card_bbox, radius=int(96 * scale), fill=(255, 255, 252, 255))

    # Calendar header.
    header_bbox = tuple(int(v * scale) for v in (184, 164, 840, 322))
    draw.rounded_rectangle(header_bbox, radius=int(96 * scale), fill=(255, 94, 74, 255))
    draw.rectangle(tuple(int(v * scale) for v in (184, 246, 840, 336)), fill=(255, 94, 74, 255))
    draw.line(tuple(int(v * scale) for v in (228, 336, 796, 336)), fill=(227, 231, 234, 255), width=int(3 * scale))

    # Binding rings.
    for cx in (342, 682):
        x = int(cx * scale)
        y = int(170 * scale)
        ring_w = int(40 * scale)
        ring_h = int(118 * scale)
        draw.rounded_rectangle(
            (x - ring_w // 2, y - int(54 * scale), x + ring_w // 2, y + ring_h // 2),
            radius=int(18 * scale),
            fill=(121, 133, 147, 255),
        )
        draw.rounded_rectangle(
            (x - int(13 * scale), y - int(42 * scale), x + int(13 * scale), y + int(46 * scale)),
            radius=int(12 * scale),
            fill=(241, 245, 248, 255),
        )

    # Today marker.
    font = get_font(int(250 * scale), bold=True)
    text = "✓"
    bbox = draw.textbbox((0, 0), text, font=font)
    tx = int(512 * scale - (bbox[2] - bbox[0]) / 2)
    ty = int(392 * scale - (bbox[3] - bbox[1]) / 2 - bbox[1])
    draw.text((tx, ty), text, fill=(28, 45, 65, 255), font=font)

    # Plan timeline rows.
    row_y = [620, 692, 764]
    row_colors = [(48, 179, 130, 255), (255, 190, 76, 255), (91, 145, 255, 255)]
    for y, color in zip(row_y, row_colors):
        cy = int(y * scale)
        draw.ellipse(
            tuple(int(v * scale) for v in (288, y - 17, 322, y + 17)),
            fill=color,
        )
        draw.rounded_rectangle(
            tuple(int(v * scale) for v in (354, y - 13, 736, y + 13)),
            radius=int(13 * scale),
            fill=(219, 226, 231, 255),
        )
        draw.rounded_rectangle(
            tuple(int(v * scale) for v in (354, y - 13, 522 + (y - 620) * 1.6, y + 13)),
            radius=int(13 * scale),
            fill=(149, 161, 173, 255),
        )

    # Top glass highlight and outer rim.
    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(highlight)
    hdraw.rounded_rectangle(
        tuple(int(v * scale) for v in (46, 38, 978, 500)),
        radius=int(186 * scale),
        fill=(255, 255, 255, 28),
    )
    highlight.putalpha(Image.composite(highlight.getchannel("A"), Image.new("L", (size, size), 0), mask))
    img.alpha_composite(highlight)
    draw.rounded_rectangle(
        tuple(int(v * scale) for v in (24, 24, 1000, 1000)),
        radius=int(210 * scale),
        outline=(255, 255, 255, 28),
        width=int(3 * scale),
    )

    return img


def save_iconset(source):
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
    for px, name in sizes:
        resized = source.resize((px, px), Image.Resampling.LANCZOS)
        resized.save(ICONSET / name)


def main():
    source = draw_icon()
    source.save(SOURCE_PNG)
    save_iconset(source)
    subprocess.run(["iconutil", "-c", "icns", str(ICONSET), "-o", str(ROOT_ICNS)], check=True)
    RESOURCE_ICNS.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT_ICNS, RESOURCE_ICNS)
    print(f"Wrote {SOURCE_PNG}")
    print(f"Wrote {ROOT_ICNS}")
    print(f"Wrote {RESOURCE_ICNS}")


if __name__ == "__main__":
    main()
