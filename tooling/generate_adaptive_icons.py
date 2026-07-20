"""Generate Android adaptive launcher foreground + legacy mipmaps from playstore.png."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(r"C:\Users\pc\Desktop\AppIcons\playstore.png")
LOGO = ROOT / "assets" / "images" / "logo.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

LEGACY_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

FOREGROUND_SIZES = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}


def fit_foreground(source: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    # Keep logo inside adaptive safe zone (~66%) with a little breathing room.
    inner = int(size * 0.78)
    resized = source.convert("RGBA").resize((inner, inner), Image.Resampling.LANCZOS)
    offset = (size - inner) // 2
    canvas.paste(resized, (offset, offset), resized)
    return canvas


def fit_legacy(source: Image.Image, size: int) -> Image.Image:
    return source.convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)


def make_monochrome(source: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inner = int(size * 0.72)
    resized = source.convert("RGBA").resize((inner, inner), Image.Resampling.LANCZOS)
    mono = Image.new("RGBA", (inner, inner), (0, 0, 0, 0))
    px = resized.load()
    mpx = mono.load()
    for y in range(inner):
        for x in range(inner):
            _, _, _, alpha = px[x, y]
            if alpha > 24:
                mpx[x, y] = (255, 255, 255, alpha)
    offset = (size - inner) // 2
    canvas.paste(mono, (offset, offset), mono)
    return canvas


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"Missing source icon: {SRC}")

    source = Image.open(SRC)

    for folder, size in FOREGROUND_SIZES.items():
        out_dir = RES / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        fit_foreground(source, size).save(out_dir / "ic_launcher_foreground.png")

    for folder, size in LEGACY_SIZES.items():
        out_dir = RES / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        fit_legacy(source, size).save(out_dir / "ic_launcher.png")

    nodpi = RES / "drawable-nodpi"
    nodpi.mkdir(parents=True, exist_ok=True)
    fit_foreground(source, 432).save(nodpi / "ic_launcher_foreground.png")

    mono_src = Image.open(LOGO) if LOGO.exists() else source
    make_monochrome(mono_src, 432).save(nodpi / "ic_launcher_monochrome.png")
    print("Adaptive icon assets generated.")


if __name__ == "__main__":
    main()
