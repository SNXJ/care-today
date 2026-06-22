#!/usr/bin/env python3
"""生成 care-today 应用图标（爱心 + 心电脉冲）。
为 Android（legacy mipmap + adaptive 前景/背景）和 iOS（AppIcon 全套）输出 PNG。
设计：温暖米色渐变背景 + 玫瑰红爱心 + 白色心电线。
"""
import math
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AND = os.path.join(ROOT, "android/app/src/main/res")
IOS = os.path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset")

SS = 4  # 超采样倍数，绘制后缩小以获得平滑边缘

CREAM_TOP = (255, 246, 237)
CREAM_BOTTOM = (246, 221, 207)
ROSE = (184, 95, 85)
ROSE_DARK = (158, 76, 67)
WHITE = (255, 253, 249)


def heart_points(cx, cy, scale):
    pts = []
    for i in range(0, 361, 3):
        t = math.radians(i)
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * scale, cy - y * scale))
    return pts


def vgradient(size, top, bottom):
    img = Image.new("RGB", (1, size))
    for y in range(size):
        f = y / max(1, size - 1)
        img.putpixel((0, y), tuple(int(top[c] + (bottom[c] - top[c]) * f) for c in range(3)))
    return img.resize((size, size))


def draw_motif(d, size, cx, cy, heart_scale):
    """在给定画布上绘制爱心 + 心电脉冲。坐标基于 size（含超采样）。"""
    # 爱心
    pts = heart_points(cx, cy, heart_scale)
    d.polygon(pts, fill=ROSE)
    # 心电脉冲线（白色），横跨爱心中部
    w = heart_scale * 16  # 爱心半宽约
    lw = max(2, int(size * 0.022))
    midy = cy + heart_scale * 1.5
    x0 = cx - w * 0.78
    x1 = cx + w * 0.78
    span = x1 - x0
    line = [
        (x0, midy),
        (x0 + span * 0.30, midy),
        (x0 + span * 0.40, midy - heart_scale * 3.0),
        (x0 + span * 0.52, midy + heart_scale * 4.2),
        (x0 + span * 0.62, midy),
        (x1, midy),
    ]
    d.line(line, fill=WHITE, width=lw, joint="curve")
    for p in line:
        d.ellipse([p[0] - lw / 2, p[1] - lw / 2, p[0] + lw / 2, p[1] + lw / 2], fill=WHITE)


def full_icon(px, bg=True):
    """整张图标（背景 + 居中爱心），用于 legacy Android 与 iOS。"""
    s = px * SS
    if bg:
        img = vgradient(s, CREAM_TOP, CREAM_BOTTOM).convert("RGBA")
    else:
        img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_motif(d, s, s / 2, s * 0.46, s * 0.0175)
    return img.resize((px, px), Image.LANCZOS)


def foreground(px):
    """adaptive 前景：透明背景，爱心置于安全区（居中、约占 56%）。"""
    s = px * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # adaptive 画布 108dp，安全区中心约 66dp；爱心适当缩小
    draw_motif(d, s, s / 2, s * 0.47, s * 0.0125)
    return img.resize((px, px), Image.LANCZOS)


def background(px):
    return vgradient(px * SS, CREAM_TOP, CREAM_BOTTOM).resize((px, px), Image.LANCZOS)


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)


# —— Android legacy + adaptive ——
ANDROID = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}
for dpi, (legacy, adaptive) in ANDROID.items():
    base = os.path.join(AND, f"mipmap-{dpi}")
    save(full_icon(legacy), os.path.join(base, "ic_launcher.png"))
    save(foreground(adaptive), os.path.join(base, "ic_launcher_foreground.png"))
    save(background(adaptive), os.path.join(base, "ic_launcher_background.png"))

# adaptive-icon xml
anydpi = os.path.join(AND, "mipmap-anydpi-v26")
os.makedirs(anydpi, exist_ok=True)
xml = (
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
    "</adaptive-icon>\n"
)
with open(os.path.join(anydpi, "ic_launcher.xml"), "w") as f:
    f.write(xml)
with open(os.path.join(anydpi, "ic_launcher_round.xml"), "w") as f:
    f.write(xml)

# —— 闪屏 logo（透明背景的爱心，居中显示在米色窗口上）——
SPLASH = {"mdpi": 130, "hdpi": 195, "xhdpi": 260, "xxhdpi": 390, "xxxhdpi": 520}
for dpi, px in SPLASH.items():
    img = foreground(px)  # 复用前景（透明底 + 爱心心电）
    save(img, os.path.join(AND, f"drawable-{dpi}", "splash_logo.png"))

# —— iOS ——
IOS_SIZES = {
    "Icon-App-1024x1024@1x.png": 1024,
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
}
for name, px in IOS_SIZES.items():
    # iOS 不允许透明通道，转 RGB
    save(full_icon(px).convert("RGB"), os.path.join(IOS, name))

print("icons generated")
