#!/usr/bin/env python3
"""Render preview images of the showcase from the desktop simulator.

Usage: make_media.py <out_dir>
Builds sim/sim if needed, then writes into <out_dir>:
  scene_<n>_<name>.png   sheet of eight stills (round mask applied, as on the display)
  scene_<n>_<name>.gif   five seconds of the scene, 20 frames per second
  all_scenes.png         one still of each scene side by side
Needs Pillow and a C++ compiler.
"""
import glob, os, subprocess, sys, tempfile
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
SIM_DIR = os.path.join(HERE, "..", "sim")
SIM = os.path.join(SIM_DIR, "sim")
NAMES = ["hello", "climate", "sound", "time", "colour", "warp"]
BEST = [4, 5, 5, 4, 5, 6]  # which still of each scene goes on the overview
BG = (24, 24, 28)

out = sys.argv[1]
os.makedirs(out, exist_ok=True)
subprocess.run(["c++", "-O2", "-std=c++17", "-I..", "sim.cpp", "-o", "sim"], cwd=SIM_DIR, check=True)

mask = Image.new("L", (240, 240), 0)
ImageDraw.Draw(mask).ellipse((0, 0, 239, 239), fill=255)


def rounded(path):
    tile = Image.new("RGB", (240, 240), BG)
    tile.paste(Image.open(path).convert("RGB"), (0, 0), mask)
    return tile


with tempfile.TemporaryDirectory() as tmp:
    subprocess.run([SIM, "shots", tmp], check=True)
    overview = Image.new("RGB", (6 * 248 + 8, 256), BG)
    for s, name in enumerate(NAMES):
        files = sorted(glob.glob(f"{tmp}/s{s}_f*.ppm"))
        sheet = Image.new("RGB", (4 * 248 + 8, 2 * 248 + 8), BG)
        for i, f in enumerate(files):
            sheet.paste(rounded(f), (8 + (i % 4) * 248, 8 + (i // 4) * 248))
        sheet.save(f"{out}/scene_{s + 1}_{name}.png")
        overview.paste(rounded(files[BEST[s]]), (8 + s * 248, 8))
    overview.save(f"{out}/all_scenes.png")

for s, name in enumerate(NAMES):
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run([SIM, "frames", tmp, str(s), "5", "20"], check=True)
        frames = [rounded(f) for f in sorted(glob.glob(f"{tmp}/f*.ppm"))]
        frames[0].save(f"{out}/scene_{s + 1}_{name}.gif", save_all=True, append_images=frames[1:], duration=50,
                       loop=0, optimize=True)
print("wrote", out)
