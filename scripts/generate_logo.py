from __future__ import annotations

from pathlib import Path
from math import pi

from PIL import Image, ImageDraw, ImageFont

SIZE = 768
OUTPUT = Path('assets/images/logo.png')
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

background = Image.new('RGB', (SIZE, SIZE), (245, 241, 235))
draw = ImageDraw.Draw(background)

# Circular badge mask
center = SIZE / 2
outer_radius = SIZE * 0.45
inner_radius = SIZE * 0.42

outer_bbox = [
    center - outer_radius,
    center - outer_radius,
    center + outer_radius,
    center + outer_radius,
]
inner_bbox = [
    center - inner_radius,
    center - inner_radius,
    center + inner_radius,
    center + inner_radius,
]

# Outer ring
ring_color = (8, 46, 75)
draw.ellipse(outer_bbox, fill=ring_color)

# Inner gradient
from PIL import ImageChops

inner = Image.new('RGB', (SIZE, SIZE))
for y in range(SIZE):
    t = y / (SIZE - 1)
    r = int(16 + (20 - 16) * t)
    g = int(55 + (142 - 55) * t)
    b = int(94 + (166 - 94) * t)
    ImageDraw.Draw(inner).line([(0, y), (SIZE, y)], fill=(r, g, b))

mask = Image.new('L', (SIZE, SIZE), 0)
ImageDraw.Draw(mask).ellipse(inner_bbox, fill=255)
background.paste(inner, mask=mask)

inner_draw = ImageDraw.Draw(background)

# Horizon strip
horizon_y = int(center + inner_radius * 0.25)
inner_draw.rectangle(
    [center - inner_radius, horizon_y, center + inner_radius, horizon_y + 40],
    fill=(115, 169, 79),
)

# Skyline silhouettes
skyline_base = horizon_y
buildings = [
    (-0.35, 0.32),
    (-0.15, 0.45),
    (0.05, 0.28),
]
for offset, height in buildings:
    width = inner_radius * 0.28
    left = center + offset * inner_radius - width / 2
    right = left + width
    top = skyline_base - inner_radius * height
    inner_draw.rectangle([left, top, right, skyline_base], fill=(20, 52, 82))

# Bridge
bridge_left = center + inner_radius * 0.1
bridge_right = center + inner_radius * 0.55
bridge_top = skyline_base - inner_radius * 0.2
bridge_bottom = skyline_base + 12
inner_draw.rectangle([bridge_left, bridge_top, bridge_right, skyline_base], fill=(17, 59, 90))
# Bridge arches
arch_radius = inner_radius * 0.09
for i in range(3):
    arch_center = bridge_left + (i + 0.6) * arch_radius * 1.6
    bbox = [
        arch_center - arch_radius,
        skyline_base - arch_radius * 0.3,
        arch_center + arch_radius,
        skyline_base + arch_radius,
    ]
    inner_draw.pieslice(bbox, 0, 180, fill=(10, 41, 70))

# Tree
tree_trunk = [
    center + inner_radius * 0.55 - 12,
    skyline_base - 40,
    center + inner_radius * 0.55 + 12,
    skyline_base + 10,
]
inner_draw.rectangle(tree_trunk, fill=(19, 52, 63))
tree_top = [
    center + inner_radius * 0.55 - 55,
    skyline_base - 95,
    center + inner_radius * 0.55 + 55,
    skyline_base - 5,
]
inner_draw.ellipse(tree_top, fill=(114, 175, 94))

# Stars
star_positions = [
    (-0.45, -0.3),
    (-0.15, -0.45),
    (0.25, -0.3),
    (0.38, -0.55),
]
for x, y in star_positions:
    px = center + x * inner_radius
    py = center + y * inner_radius
    size = 10
    inner_draw.ellipse([px - size, py - size, px + size, py + size], fill=(233, 243, 255))

# Satellite
sat_center = (center - inner_radius * 0.15, center - inner_radius * 0.35)
sat_w, sat_h = inner_radius * 0.22, inner_radius * 0.08
sx, sy = sat_center
# Body
inner_draw.rectangle([
    sx - sat_w * 0.2,
    sy - sat_h * 0.5,
    sx + sat_w * 0.2,
    sy + sat_h * 0.5,
], fill=(233, 243, 255))
# Panels
inner_draw.rectangle([
    sx - sat_w * 0.5,
    sy - sat_h * 0.4,
    sx - sat_w * 0.25,
    sy + sat_h * 0.4,
], fill=(209, 229, 255))
inner_draw.rectangle([
    sx + sat_w * 0.25,
    sy - sat_h * 0.4,
    sx + sat_w * 0.5,
    sy + sat_h * 0.4,
], fill=(209, 229, 255))

# Satellite orbit arc
arc_bbox = [
    center - inner_radius * 1.1,
    center - inner_radius * 1.1,
    center + inner_radius * 1.1,
    center + inner_radius * 1.1,
]
inner_draw.arc(arc_bbox, start=300, end=350, width=6, fill=(233, 243, 255))

# Lower globe grid impression
grid_box = [
    center - inner_radius,
    center,
    center + inner_radius,
    center + inner_radius,
]
inner_draw.arc(grid_box, start=200, end=340, width=8, fill=(7, 35, 60))
inner_draw.line(
    [
        (center - inner_radius * 0.6, center + inner_radius * 0.5),
        (center + inner_radius * 0.6, center + inner_radius * 0.5),
    ],
    fill=(7, 35, 60),
    width=6,
)

# Text label
font_path = 'C:/Windows/Fonts/arialbd.ttf'
try:
    font = ImageFont.truetype(font_path, 72)
except OSError:
    font = ImageFont.load_default()

text = 'EG SOLUTION'
bbox = font.getbbox(text)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
text_x = center - text_width / 2
text_y = horizon_y + 40
inner_draw.text((text_x, text_y), text, font=font, fill=(233, 243, 255))

background.save(OUTPUT)
print(f'Created {OUTPUT}')
