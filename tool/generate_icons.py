#!/usr/bin/env python3
"""Draws the Shift Viewer app icon and writes every launcher size it needs.

The mark: a white clock face carrying a blue medical cross, wrapped by an open
arc that stands for the hours a shift covers — hospital plus shift, in the
app's own blue (the #3B82F6 seed the Material theme is built from).

The cross is blue rather than red on purpose: a red cross on white is the
protected Geneva Conventions emblem, not a free-to-use medical symbol.

Run it after changing the design; it overwrites the icons in place:

    python3 -m venv .venv && .venv/bin/pip install pillow
    .venv/bin/python tool/generate_icons.py
"""

from __future__ import annotations

import json
import math
import os
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent

# Gradient ends of the background, top to bottom.
BG_TOP = (59, 130, 246)     # #3B82F6 — the Material seed colour
BG_BOTTOM = (29, 78, 216)   # #1D4ED8
CROSS = (29, 78, 216)       # the face's cross, matching the deep end
WHITE = (255, 255, 255)

# Everything below is a fraction of the icon's width, so one description
# renders at every size.
FACE_RADIUS = 0.300         # the white clock face
ARC_RADIUS = 0.395          # centre line of the shift arc
ARC_WIDTH = 0.052
ARC_FROM, ARC_TO = -78, 205  # degrees, 0 = 3 o'clock, clockwise
CROSS_ARM = 0.208           # half length of a cross arm
CROSS_BAR = 0.118           # half width of a cross bar
CROSS_ROUND = 0.022

SUPERSAMPLE = 4
MAX_RENDER = 2048


def _gradient(size: int) -> Image.Image:
    """The background gradient, drawn as a two-pixel ramp and stretched."""
    ramp = Image.new("RGB", (1, 2))
    ramp.putpixel((0, 0), BG_TOP)
    ramp.putpixel((0, 1), BG_BOTTOM)
    return ramp.resize((size, size), Image.BILINEAR)


def _rounded_mask(size: int, radius: float) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=radius * size, fill=255
    )
    return mask


def _draw_mark(
    img: Image.Image, size: int, scale: float, arc: bool, punch: bool = False
) -> None:
    """Paints the clock face, the shift arc and the cross onto [img].

    With [punch] the cross is cut out of the face instead of being drawn in
    blue, which is what a themed (monochrome) launcher icon needs: it is tinted
    from the layer's alpha alone, so the cross has to be a hole.
    """
    draw = ImageDraw.Draw(img)
    c = size / 2

    def px(fraction: float) -> float:
        return fraction * size * scale

    if arc:
        r = px(ARC_RADIUS)
        w = px(ARC_WIDTH)
        draw.arc(
            (c - r, c - r, c + r, c + r),
            ARC_FROM,
            ARC_TO,
            fill=WHITE,
            width=max(1, round(w)),
        )
        # Pillow draws butt ends; a disc on each one rounds the arc off.
        for angle in (ARC_FROM, ARC_TO):
            ex = c + r * math.cos(math.radians(angle))
            ey = c + r * math.sin(math.radians(angle))
            draw.ellipse((ex - w / 2, ey - w / 2, ex + w / 2, ey + w / 2), fill=WHITE)

    face = px(FACE_RADIUS)
    draw.ellipse((c - face, c - face, c + face, c + face), fill=WHITE)

    arm, bar, rad = px(CROSS_ARM), px(CROSS_BAR), px(CROSS_ROUND)
    # ImageDraw writes pixels rather than compositing them, so a transparent
    # fill takes the cross back out of the face.
    fill = (0, 0, 0, 0) if punch else CROSS
    draw.rounded_rectangle((c - bar, c - arm, c + bar, c + arm), radius=rad, fill=fill)
    draw.rounded_rectangle((c - arm, c - bar, c + arm, c + bar), radius=rad, fill=fill)


def icon(
    size: int,
    *,
    corner: float = 0.22,
    scale: float = 1.0,
    background: bool = True,
    arc: bool = True,
    punch: bool = False,
) -> Image.Image:
    """One icon: [corner] rounds the background, [scale] shrinks the mark to
    leave the margin a launcher mask needs, [background] off yields a
    transparent foreground layer."""
    render = min(size * SUPERSAMPLE, MAX_RENDER)
    img = Image.new("RGBA", (render, render), (0, 0, 0, 0))
    if background:
        bg = _gradient(render).convert("RGBA")
        bg.putalpha(_rounded_mask(render, corner))
        img.alpha_composite(bg)
    _draw_mark(img, render, scale, arc, punch)
    return img.resize((size, size), Image.LANCZOS)


def write(img: Image.Image, path: str, *, opaque: bool = False) -> None:
    out = ROOT / path
    out.parent.mkdir(parents=True, exist_ok=True)
    if opaque:
        # The App Store rejects icons with an alpha channel.
        flat = Image.new("RGB", img.size, BG_BOTTOM)
        flat.paste(img, mask=img.split()[3])
        img = flat
    img.save(out)
    print(f"  {path}  {img.size[0]}x{img.size[1]}")


def main() -> None:
    print("web")
    # A 16px favicon cannot hold the arc, so the small one drops it.
    write(icon(32, corner=0.2, arc=False, scale=1.06), "web/favicon.png")
    for s in (192, 512):
        write(icon(s), f"web/icons/Icon-{s}.png")
        # Maskable icons get cropped to the launcher's own shape: square to the
        # edges, with the mark inside the safe circle.
        write(icon(s, corner=0.0, scale=0.72), f"web/icons/Icon-maskable-{s}.png")

    print("android (legacy launcher)")
    for bucket, s in (
        ("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)
    ):
        write(icon(s), f"android/app/src/main/res/mipmap-{bucket}/ic_launcher.png")

    print("android (adaptive foreground, 108dp layer)")
    # Android crops the 108dp layer to its central 72dp, so the mark has to sit
    # well inside it.
    for bucket, s in (
        ("mdpi", 108), ("hdpi", 162), ("xhdpi", 216), ("xxhdpi", 324),
        ("xxxhdpi", 432)
    ):
        write(
            icon(s, background=False, scale=0.68),
            f"android/app/src/main/res/mipmap-{bucket}/ic_launcher_foreground.png",
        )
        # The themed variant is tinted from its alpha, so it is the same mark
        # with the cross cut out rather than coloured in.
        write(
            icon(s, background=False, scale=0.68, punch=True),
            f"android/app/src/main/res/mipmap-{bucket}/ic_launcher_monochrome.png",
        )

    print("ios")
    # iOS applies its own rounded mask, so these stay square and opaque.
    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((ios / "Contents.json").read_text())
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        scale = int(entry["scale"].rstrip("x"))
        px_size = round(float(entry["size"].split("x")[0]) * scale)
        write(
            icon(px_size, corner=0.0, arc=px_size >= 40),
            f"ios/Runner/Assets.xcassets/AppIcon.appiconset/{filename}",
            opaque=True,
        )


if __name__ == "__main__":
    main()
