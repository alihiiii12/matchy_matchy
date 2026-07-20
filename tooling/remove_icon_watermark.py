"""Remove ChatGPT watermark from app icon and regenerate launcher assets."""
from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(
    r"C:\Users\pc\.cursor\projects\c-Users-pc-Desktop-voice-to-txt\assets"
    r"\c__Users_pc_AppData_Roaming_Cursor_User_workspaceStorage_203847efd64de0cc4377097f1bdd44f5_images_appIcon-2cd03090-cc5f-40dd-baf6-3253e6d6eda0.png"
)
APP_ICONS = Path(r"C:\Users\pc\Desktop\AppIcons")
PLAYSTORE = APP_ICONS / "playstore.png"
APPSTORE = APP_ICONS / "appstore.png"


def remove_watermark(image: Image.Image) -> Image.Image:
    rgb = np.array(image.convert("RGB"))
    h, w = rgb.shape[:2]

    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)
    corner = gray[h - int(h * 0.12) :, w - int(w * 0.30) :]

    # Watermark text is brighter than the dark gradient in that corner.
    _, bright = cv2.threshold(corner, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    bright = cv2.dilate(bright, np.ones((3, 3), np.uint8), iterations=1)

    mask = np.zeros((h, w), dtype=np.uint8)
    mask[h - int(h * 0.12) :, w - int(w * 0.30) :] = bright

    if mask.sum() == 0:
        mask[h - int(h * 0.10) :, w - int(w * 0.24) :] = 255

    cleaned = cv2.inpaint(rgb, mask, inpaintRadius=5, flags=cv2.INPAINT_TELEA)
    return Image.fromarray(cleaned, mode="RGB")


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"Missing source icon: {SRC}")

    cleaned = remove_watermark(Image.open(SRC))
    save_png(cleaned, PLAYSTORE)
    save_png(cleaned, APPSTORE)
    print(f"Saved cleaned icon to {PLAYSTORE}")


if __name__ == "__main__":
    main()
