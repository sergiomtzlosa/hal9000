#!/usr/bin/env python3
"""Generate original HAL 9000 fan-project artwork and a macOS .icns.

Development dependencies: Pillow and numpy.  The generated PNG/ICNS files are
committed so end users never need either package to build the app.

This script deliberately uses only original geometric artwork: a dark rounded
housing, metallic bezels, a red lens, aperture blades, and a bright pupil.
No film stills, logos, or traced assets are used.
"""

from __future__ import annotations

import math
import subprocess
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter
except ImportError as exc:  # pragma: no cover - developer tooling only
    print("make_icon.py requires Pillow and numpy: python3 -m pip install pillow numpy", file=sys.stderr)
    raise SystemExit(1) from exc


ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
RESOURCES = ROOT / "HAL9000" / "Resources"
ICONSET = RESOURCES / "AppIcon.iconset"
SIZE = 2048


def hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def radial_layer(
    size: int,
    center: tuple[float, float],
    radius: float,
    inner: str,
    outer: str,
    power: float = 1.0,
    alpha_power: float = 1.0,
) -> Image.Image:
    """Return an RGBA radial gradient with a soft extent at ``radius``."""
    y, x = np.mgrid[0:size, 0:size]
    distance = np.sqrt((x - center[0]) ** 2 + (y - center[1]) ** 2) / max(1.0, radius)
    t = np.clip(distance, 0.0, 1.0) ** power
    inner_rgb = np.array(hex_rgb(inner), dtype=np.float32)
    outer_rgb = np.array(hex_rgb(outer), dtype=np.float32)
    rgb = inner_rgb[None, None, :] * (1.0 - t[..., None]) + outer_rgb[None, None, :] * t[..., None]
    alpha = np.clip((1.0 - np.clip(distance, 0.0, 1.0)) * 255.0, 0.0, 255.0) ** alpha_power
    rgba = np.dstack((rgb, alpha)).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def smoothstep(edge0: float, edge1: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - edge0) / max(1e-6, edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def lens_image(size: int, center: tuple[float, float], radius: float) -> Image.Image:
    y, x = np.mgrid[0:size, 0:size]
    distance = np.sqrt((x - center[0]) ** 2 + (y - center[1]) ** 2) / radius
    d = np.clip(distance, 0.0, 1.0)

    stops = [
        (0.00, (255, 72, 45)),
        (0.16, (255, 42, 26)),
        (0.38, (190, 18, 10)),
        (0.66, (100, 9, 5)),
        (0.88, (49, 5, 3)),
        (1.00, (16, 2, 2)),
    ]
    rgb = np.zeros((size, size, 3), dtype=np.float32)
    for i in range(len(stops) - 1):
        p0, c0 = stops[i]
        p1, c1 = stops[i + 1]
        mask = (d >= p0) & (d <= p1)
        if not np.any(mask):
            continue
        local = (d[mask] - p0) / max(1e-6, p1 - p0)
        c0a = np.array(c0, dtype=np.float32)
        c1a = np.array(c1, dtype=np.float32)
        rgb[mask] = c0a[None, :] * (1.0 - local[:, None]) + c1a[None, :] * local[:, None]

    # A soft off-centre optical hotspot makes the lens feel like glass.
    hx, hy = center[0] - radius * 0.18, center[1] - radius * 0.22
    hot = np.exp(-(((x - hx) ** 2 + (y - hy) ** 2) / (radius * radius * 0.10)))
    rgb += hot[..., None] * np.array((70, 15, 8), dtype=np.float32)[None, None, :]

    # Slight edge darkening.
    edge = smoothstep(0.72, 1.0, d)
    rgb *= (1.0 - 0.48 * edge)[..., None]

    alpha = (1.0 - smoothstep(0.985, 1.0, d)) * 255.0
    rgba = np.dstack((np.clip(rgb, 0, 255), np.clip(alpha, 0, 255))).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def make_master() -> Image.Image:
    size = SIZE
    center = (size * 0.5, size * 0.5)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Rounded-square background.
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    radius = int(size * 0.215)
    bg_draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=(5, 6, 7, 255))

    # A faint cool centre lift and a heavy vignette.
    cool = radial_layer(size, center, size * 0.72, "#11161A", "#050607", power=1.25)
    bg.alpha_composite(cool)

    y, x = np.mgrid[0:size, 0:size]
    dx = (x - center[0]) / (size * 0.5)
    dy = (y - center[1]) / (size * 0.5)
    radial = np.sqrt(dx * dx + dy * dy)
    vignette = np.clip((radial - 0.38) / 0.74, 0.0, 1.0) ** 1.7
    bg_rgb = np.array(bg.convert("RGB"), dtype=np.float32)
    bg_rgb *= (1.0 - 0.72 * vignette)[..., None]
    bg = Image.fromarray(np.dstack((np.clip(bg_rgb, 0, 255), np.array(bg.getchannel("A")))).astype(np.uint8), "RGBA")
    canvas.alpha_composite(bg)

    # Constrained red halo behind the housing.
    halo = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow = radial_layer(size, center, size * 0.44, "#FF2A1A", "#3A0503", power=1.45)
    glow_alpha = np.array(glow.getchannel("A"), dtype=np.float32)
    glow_alpha = np.clip(glow_alpha.astype(np.float32) * 0.36, 0, 255).astype(np.uint8)
    glow.putalpha(Image.fromarray(glow_alpha))
    halo = halo.filter(ImageFilter.GaussianBlur(size * 0.018))
    halo.alpha_composite(glow)
    canvas.alpha_composite(halo)

    # Outer housing and bezel.  The bezel is a carefully layered set of radial
    # gradients rather than a traced film prop.
    bezel = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(bezel)
    outer_r = size * 0.432
    inner_r = size * 0.336
    draw.ellipse(
        (center[0] - outer_r, center[1] - outer_r, center[0] + outer_r, center[1] + outer_r),
        fill=(8, 10, 12, 255),
    )
    draw.ellipse(
        (center[0] - inner_r, center[1] - inner_r, center[0] + inner_r, center[1] + inner_r),
        fill=(3, 4, 5, 255),
    )

    # Metallic ring with fine concentric grooves and a top-left key light.
    y, x = np.mgrid[0:size, 0:size]
    dist = np.sqrt((x - center[0]) ** 2 + (y - center[1]) ** 2)
    ring_mask = (dist >= inner_r) & (dist <= outer_r)
    groove = 0.78 + 0.22 * (0.5 + 0.5 * np.cos((dist - inner_r) * 0.34))
    light = np.clip(0.55 + 0.42 * (-(x - center[0]) - (y - center[1])) / (2.0 * outer_r), 0.28, 1.25)
    metal = np.zeros((size, size, 3), dtype=np.float32)
    metal[..., 0] = 42.0 * light * groove
    metal[..., 1] = 47.0 * light * groove
    metal[..., 2] = 51.0 * light * groove
    ring_rgba = np.dstack((
        np.clip(metal, 0, 255),
        np.where(ring_mask, 255, 0),
    )).astype(np.uint8)
    bezel.alpha_composite(Image.fromarray(ring_rgba, "RGBA"))

    # Inner and outer rim highlights.
    draw = ImageDraw.Draw(bezel)
    for inset, color, width in [
        (inner_r + 3, (129, 140, 145, 90), 5),
        (inner_r + 12, (31, 36, 39, 220), 9),
        (outer_r - 8, (82, 91, 96, 110), 4),
        (outer_r - 2, (4, 5, 6, 230), 8),
    ]:
        box = (center[0] - inset, center[1] - inset, center[0] + inset, center[1] + inset)
        draw.ellipse(box, outline=color, width=max(1, int(width)))
    canvas.alpha_composite(bezel)

    # Fine concentric iris rings.
    rings = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ring_draw = ImageDraw.Draw(rings)
    for i, r in enumerate([0.095, 0.132, 0.172, 0.218, 0.268, 0.310]):
        rr = size * r
        color = (255, 63, 36, 36) if i % 2 == 0 else (70, 5, 3, 100)
        ring_draw.ellipse(
            (center[0] - rr, center[1] - rr, center[0] + rr, center[1] + rr),
            outline=color,
            width=max(1, int(size * 0.0016)),
        )
    canvas.alpha_composite(rings)

    # Aperture blades: eight overlapping wedge shapes, rendered in dark red.
    blades = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    blade_draw = ImageDraw.Draw(blades)
    blade_inner = size * 0.075
    blade_outer = size * 0.306
    for i in range(8):
        a0 = math.radians(i * 45.0 - 90.0)
        a1 = math.radians((i + 1) * 45.0 - 90.0 - 11.0)
        points = [
            (center[0] + math.cos(a0) * blade_inner, center[1] + math.sin(a0) * blade_inner),
            (center[0] + math.cos(a0 + 0.19) * blade_outer, center[1] + math.sin(a0 + 0.19) * blade_outer),
            (center[0] + math.cos(a1) * blade_outer, center[1] + math.sin(a1) * blade_outer),
            (center[0] + math.cos(a1 - 0.05) * blade_inner, center[1] + math.sin(a1 - 0.05) * blade_inner),
        ]
        blade_draw.polygon(points, fill=(29, 3, 2, 132))
        blade_draw.line(points + [points[0]], fill=(170, 19, 10, 54), width=max(1, int(size * 0.0014)))
    blades = blades.filter(ImageFilter.GaussianBlur(size * 0.0022))
    canvas.alpha_composite(blades)

    # Lens, with the aperture assembly layered over it.
    lens = lens_image(size, center, size * 0.329)
    canvas.alpha_composite(lens)

    # Re-apply the thin iris rings above the lens for depth.
    canvas.alpha_composite(rings)

    # Very subtle blade edges above the lens.
    canvas.alpha_composite(blades)

    # Bright pupil and hotspot.
    pupil = radial_layer(size, center, size * 0.058, "#FF8B67", "#5D0904", power=1.2)
    canvas.alpha_composite(pupil)
    pupil_draw = ImageDraw.Draw(canvas)
    inner = size * 0.028
    pupil_draw.ellipse(
        (center[0] - inner, center[1] - inner, center[0] + inner, center[1] + inner),
        fill=(255, 220, 196, 238),
    )
    highlight = radial_layer(
        size,
        (center[0] - size * 0.012, center[1] - size * 0.018),
        size * 0.019,
        "#FFFFFF",
        "#FFD1B8",
        power=1.0,
    )
    canvas.alpha_composite(highlight)

    # Specular arc, top-left.
    spec = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    spec_draw = ImageDraw.Draw(spec)
    arc_r = size * 0.385
    spec_draw.arc(
        (center[0] - arc_r, center[1] - arc_r, center[0] + arc_r, center[1] + arc_r),
        start=146,
        end=230,
        fill=(220, 232, 238, 62),
        width=max(2, int(size * 0.006)),
    )
    spec = spec.filter(ImageFilter.GaussianBlur(size * 0.004))
    canvas.alpha_composite(spec)

    # Sparse sensor grain and a final vignette inside the rounded square.
    arr = np.array(canvas, dtype=np.float32)
    rng = np.random.default_rng(9000)
    grain = rng.normal(0.0, 2.6, (size, size, 1))
    arr[..., :3] = np.clip(arr[..., :3] + grain, 0, 255)
    y, x = np.mgrid[0:size, 0:size]
    dx = (x - center[0]) / (size * 0.5)
    dy = (y - center[1]) / (size * 0.5)
    vignette = np.clip((np.sqrt(dx * dx + dy * dy) - 0.40) / 0.72, 0.0, 1.0) ** 1.5
    arr[..., :3] *= (1.0 - 0.34 * vignette)[..., None]
    final = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")

    # Mask to the rounded square so Finder sees a proper macOS icon shape.
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    final.putalpha(Image.composite(final.getchannel("A"), Image.new("L", (size, size), 0), mask))
    return final


def write_iconset(master: Image.Image) -> None:
    ICONSET.mkdir(parents=True, exist_ok=True)
    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    for name, px in sizes.items():
        master.resize((px, px), Image.Resampling.LANCZOS).save(ICONSET / name)
    subprocess.run(
        ["iconutil", "-c", "icns", str(ICONSET), "-o", str(RESOURCES / "HAL9000.icns")],
        check=True,
    )


def main() -> int:
    DOCS.mkdir(parents=True, exist_ok=True)
    RESOURCES.mkdir(parents=True, exist_ok=True)

    master = make_master()
    # Supersampled render at 2048, then the documented 1024 master.
    master_1024 = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    master_1024.save(DOCS / "hal-eye.png")
    write_iconset(master_1024)
    print(f"Wrote {DOCS / 'hal-eye.png'}")
    print(f"Wrote {RESOURCES / 'HAL9000.icns'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
