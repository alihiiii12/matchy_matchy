# -*- coding: utf-8 -*-
import fitz
import json
from pathlib import Path

path = Path(r"C:\Users\pc\Desktop\ملخص_المحاضرة_صفحات_1_26_مبادئ_التسويق.pdf")
doc = fitz.open(path)
out = []
out.append(f"pages={doc.page_count}")

for i in range(doc.page_count):
    p = doc[i]
    out.append(f"\n=== PAGE {i+1} ===")
    # render page 0 as pixmap sample for colors - get drawings
    text = p.get_text("text")
    out.append("TEXT_SAMPLE:")
    out.append(text[:2500])
    d = p.get_text("dict")
    fonts = set()
    colors = set()
    sizes = set()
    for b in d["blocks"]:
        if b.get("type") != 0:
            continue
        for line in b.get("lines", []):
            for sp in line.get("spans", []):
                fonts.add(sp.get("font", ""))
                colors.add(sp.get("color"))
                sizes.add(round(sp.get("size", 0), 1))
    out.append(f"FONTS: {sorted(fonts)}")
    out.append(f"SIZES: {sorted(sizes)}")
    out.append(f"COLORS: {sorted(colors)}")

Path(r"C:\Users\pc\StudioProjects\zadak\tooling\pdf_analysis.txt").write_text("\n".join(out), encoding="utf-8")
print("done")
