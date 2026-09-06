import os
from PIL import Image

src_img_path = r"C:\Users\geert\.gemini\antigravity-ide\brain\276bc800-55df-4ff0-9c55-2bf4bb1ff7d5\padel_app_icon_1788717614458.jpg"
repo_dir = r"c:\Users\geert\Documents\Github\7segment"

img = Image.open(src_img_path).convert("RGBA")

# 512x512 icon
img_512 = img.resize((512, 512), Image.Resampling.LANCZOS)
img_512.save(os.path.join(repo_dir, "icon-512.png"), "PNG")
print("Saved icon-512.png")

# 192x192 icon
img_192 = img.resize((192, 192), Image.Resampling.LANCZOS)
img_192.save(os.path.join(repo_dir, "icon-192.png"), "PNG")
print("Saved icon-192.png")

# 180x180 Apple Touch Icon
img_180 = img.resize((180, 180), Image.Resampling.LANCZOS)
img_180.save(os.path.join(repo_dir, "apple-touch-icon.png"), "PNG")
print("Saved apple-touch-icon.png")

# 64x64 favicon.png
img_64 = img.resize((64, 64), Image.Resampling.LANCZOS)
img_64.save(os.path.join(repo_dir, "favicon.png"), "PNG")
print("Saved favicon.png")

# favicon.ico
img_ico = img.resize((32, 32), Image.Resampling.LANCZOS)
img_ico.save(os.path.join(repo_dir, "favicon.ico"), format="ICO")
print("Saved favicon.ico")
