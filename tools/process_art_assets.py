#!/usr/bin/env python3
"""Split BURN art sheets into transparent gameplay sprites. Original generated assets only."""
from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image, ImageFilter, ImageOps

SRC = Path("/opt/cursor/artifacts/assets")
DST = Path("/workspace/assets")
WORK = Path("/workspace/assets/_src")
WORK.mkdir(parents=True, exist_ok=True)


def copy_sources() -> None:
    for p in SRC.glob("*.png"):
        shutil.copy2(p, WORK / p.name)


def remove_bg(img: Image.Image, mode: str = "dark") -> Image.Image:
    """Make near-background pixels transparent."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            lum = (r + g + b) / 3.0
            if mode == "dark":
                # Dark/charcoal sheet backgrounds
                if lum < 28 and max(r, g, b) < 40:
                    px[x, y] = (r, g, b, 0)
                elif lum < 42 and abs(r - g) < 8 and abs(g - b) < 8:
                    # Soften near-bg gray
                    fade = int(a * ((lum - 28) / 14.0))
                    px[x, y] = (r, g, b, max(0, min(255, fade)))
            elif mode == "mask":
                # Keep bright as white mask alpha
                alpha = int(max(0, min(255, (lum - 40) * 1.4)))
                px[x, y] = (255, 255, 255, alpha)
            elif mode == "light_checker":
                # For sheets that might have light bg — keep content
                if lum > 245 and abs(r - g) < 6 and abs(g - b) < 6:
                    px[x, y] = (r, g, b, 0)
    return rgba


def autocrop(img: Image.Image, pad: int = 8) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    bbox = img.split()[-1].getbbox()
    if not bbox:
        return img
    l, t, r, b = bbox
    l = max(0, l - pad)
    t = max(0, t - pad)
    r = min(img.width, r + pad)
    b = min(img.height, b + pad)
    return img.crop((l, t, r, b))


def fit_square(img: Image.Image, size: int = 256) -> Image.Image:
    img = autocrop(img)
    # Preserve aspect inside square canvas
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    img.thumbnail((size - 16, size - 16), Image.Resampling.LANCZOS)
    x = (size - img.width) // 2
    y = (size - img.height) // 2
    canvas.paste(img, (x, y), img)
    return canvas


def split_2x2(path: Path, out_dir: Path, names: list[str], bg_mode: str = "dark", size: int = 256) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    img = Image.open(path).convert("RGBA")
    # Soften checker / vignette edges first
    cleaned = remove_bg(img, bg_mode)
    w, h = cleaned.size
    mid_x, mid_y = w // 2, h // 2
    # Small inset to avoid grid lines
    inset = max(4, min(w, h) // 80)
    quads = [
        (inset, inset, mid_x - inset, mid_y - inset),
        (mid_x + inset, inset, w - inset, mid_y - inset),
        (inset, mid_y + inset, mid_x - inset, h - inset),
        (mid_x + inset, mid_y + inset, w - inset, h - inset),
    ]
    written = []
    for name, box in zip(names, quads):
        cell = cleaned.crop(box)
        cell = remove_bg(cell, bg_mode)
        cell = fit_square(cell, size)
        out = out_dir / f"{name}.png"
        cell.save(out, "PNG")
        written.append(out)
        print(f"  wrote {out} ({cell.size})")
    return written


def save_env(path: Path, out: Path, size=(720, 1280)) -> None:
    img = Image.open(path).convert("RGB")
    # Cover crop to portrait
    tw, th = size
    scale = max(tw / img.width, th / img.height)
    nw, nh = int(img.width * scale), int(img.height * scale)
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - tw) // 2
    top = (nh - th) // 2
    img = img.crop((left, top, left + tw, top + th))
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "PNG")
    print(f"  env {out}")


def save_brand(path: Path, out: Path, size=256) -> None:
    img = remove_bg(Image.open(path), "dark")
    img = fit_square(img, size)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "PNG")
    print(f"  brand {out}")


def main() -> None:
    copy_sources()
    print("Splitting materials…")
    split_2x2(
        WORK / "paper_variants_sheet.png",
        DST / "materials/paper",
        ["sheet", "folded", "stack", "torn"],
    )
    split_2x2(
        WORK / "wood_variants_sheet.png",
        DST / "materials/wood",
        ["plank", "log", "branch", "crate"],
    )
    split_2x2(
        WORK / "grass_variants_sheet.png",
        DST / "materials/grass",
        ["clump", "patch", "tuft", "blades"],
    )
    split_2x2(
        WORK / "fabric_variants_sheet.png",
        DST / "materials/fabric",
        ["strip", "folded", "hanging", "bundle"],
    )
    split_2x2(
        WORK / "oil_variants_sheet.png",
        DST / "materials/oil",
        ["puddle", "trail", "droplet", "spill"],
    )
    split_2x2(
        WORK / "plastic_variants_sheet.png",
        DST / "materials/plastic",
        ["bottle", "container", "sheet", "block"],
    )
    split_2x2(
        WORK / "metal_variants_sheet.png",
        DST / "materials/metal",
        ["can", "plate", "sheet", "beam"],
    )
    split_2x2(
        WORK / "glass_variants_sheet.png",
        DST / "materials/glass",
        ["bottle", "panel", "shard", "jar"],
    )

    print("Splitting fire…")
    split_2x2(
        WORK / "flame_variants_sheet.png",
        DST / "fire/flames",
        ["small", "medium", "large", "side"],
        bg_mode="dark",
        size=192,
    )
    split_2x2(
        WORK / "ember_smoke_burst_sheet.png",
        DST / "fire/embers",
        ["embers", "smoke_soft", "smoke_thick", "burst"],
        bg_mode="dark",
        size=192,
    )
    # Copy named aliases into smoke/bursts
    (DST / "fire/smoke").mkdir(parents=True, exist_ok=True)
    (DST / "fire/bursts").mkdir(parents=True, exist_ok=True)
    shutil.copy2(DST / "fire/embers/smoke_soft.png", DST / "fire/smoke/soft.png")
    shutil.copy2(DST / "fire/embers/smoke_thick.png", DST / "fire/smoke/thick.png")
    shutil.copy2(DST / "fire/embers/burst.png", DST / "fire/bursts/fireball.png")
    shutil.copy2(DST / "fire/embers/embers.png", DST / "fire/embers/cluster.png")

    print("Burn masks…")
    split_2x2(
        WORK / "burn_masks_sheet.png",
        DST / "fire/burn_masks",
        ["hole_irregular", "crack", "multihole", "edge_eat"],
        bg_mode="mask",
        size=256,
    )

    print("Environments…")
    save_env(WORK / "env_workshop.png", DST / "environments/workshop/backdrop.png")
    save_env(WORK / "env_forest.png", DST / "environments/forest/backdrop.png")
    save_env(WORK / "env_warehouse.png", DST / "environments/warehouse/backdrop.png")

    print("UI…")
    save_brand(WORK / "ui_brand_flame.png", DST / "ui/branding/flame_mark.png", 256)
    # Keep button sheet as reference art; UI remains code-drawn for crisp text
    shutil.copy2(WORK / "ui_buttons_sheet.png", DST / "ui/buttons/reference_sheet.png")

    print("DONE")


if __name__ == "__main__":
    main()
