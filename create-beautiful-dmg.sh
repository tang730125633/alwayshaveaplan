#!/bin/bash

set -e

APP_NAME="AlwaysHaveAPlan"
VERSION="v1.1.1"
DMG_NAME="${APP_NAME}-${VERSION}-Installer"
SOURCE_APP="run/release/${APP_NAME}.app"
STAGING_DIR="dmg-staging"
FINAL_DMG="${DMG_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"

# 清理
echo "🧹 清理旧文件..."
rm -rf "${STAGING_DIR}"
rm -f "${FINAL_DMG}" temp.dmg

# 创建暂存目录
echo "📦 准备文件..."
mkdir -p "${STAGING_DIR}"
cp -r "${SOURCE_APP}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

# 创建背景图目录
mkdir -p "${STAGING_DIR}/.background"

# 创建精美的背景图
echo "🎨 创建精美背景图..."
python3 << 'PYTHON'
from PIL import Image, ImageDraw, ImageFont

# 创建背景图
width, height = 600, 450
image = Image.new('RGB', (width, height))
draw = ImageDraw.Draw(image)

# 绘制渐变背景（从浅蓝到白色）
for y in range(height):
    progress = y / height
    r = int(235 + (255 - 235) * progress)
    g = int(240 + (255 - 240) * progress)
    b = int(250 + (255 - 250) * progress)
    draw.line([(0, y), (width, y)], fill=(r, g, b))

# 添加装饰性圆圈（左上角）
for i in range(4):
    radius = 180 - i * 35
    alpha = 40 - i * 8
    draw.ellipse(
        [-80 - i*15, -80 - i*15, radius, radius],
        fill=None,
        outline=(255, 87, 67, alpha),
        width=3
    )

# 添加装饰性圆圈（右下角）
for i in range(4):
    radius = 180 - i * 35
    alpha = 40 - i * 8
    x_offset = width - 100 + i*15
    y_offset = height - 100 + i*15
    draw.ellipse(
        [x_offset, y_offset, x_offset + radius, y_offset + radius],
        fill=None,
        outline=(100, 150, 255, alpha),
        width=3
    )

# 添加顶部标题
try:
    title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
    subtitle_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 20)
    instruction_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 18)
except:
    title_font = subtitle_font = instruction_font = ImageFont.load_default()

# 标题
title = "Always Have a Plan"
bbox = draw.textbbox((0, 0), title, font=title_font)
title_width = bbox[2] - bbox[0]
title_x = (width - title_width) // 2
title_y = 35

# 标题阴影
draw.text((title_x + 2, title_y + 2), title, fill=(0, 0, 0, 40), font=title_font)
# 标题本身
draw.text((title_x, title_y), title, fill='#1A1A1A', font=title_font)

# 副标题
subtitle = "Stay intentional with your time"
bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
subtitle_width = bbox[2] - bbox[0]
subtitle_x = (width - subtitle_width) // 2
subtitle_y = title_y + 50

draw.text((subtitle_x, subtitle_y), subtitle, fill='#666666', font=subtitle_font)

# 底部安装说明
instruction1 = "Drag the app icon to Applications folder"
instruction2 = "to install"

bbox1 = draw.textbbox((0, 0), instruction1, font=instruction_font)
inst1_width = bbox1[2] - bbox1[0]
inst1_x = (width - inst1_width) // 2
inst1_y = height - 85

bbox2 = draw.textbbox((0, 0), instruction2, font=instruction_font)
inst2_width = bbox2[2] - bbox2[0]
inst2_x = (width - inst2_width) // 2
inst2_y = inst1_y + 28

# 绘制说明背景框
padding = 18
box_x1 = min(inst1_x, inst2_x) - padding
box_y1 = inst1_y - padding
box_x2 = max(inst1_x + inst1_width, inst2_x + inst2_width) + padding
box_y2 = inst2_y + 22 + padding

# 半透明白色背景
draw.rounded_rectangle(
    [box_x1, box_y1, box_x2, box_y2],
    radius=12,
    fill=(255, 255, 255, 220),
    outline=(200, 200, 200, 100),
    width=1
)

# 绘制说明文字
draw.text((inst1_x, inst1_y), instruction1, fill='#2C3E50', font=instruction_font)
draw.text((inst2_x, inst2_y), instruction2, fill='#2C3E50', font=instruction_font)

# 添加箭头指示（从左到右）
arrow_y = height // 2
arrow_start_x = int(width * 0.35)
arrow_end_x = int(width * 0.65)
arrow_color = '#FF5743'

# 绘制箭头线
draw.line(
    [(arrow_start_x, arrow_y), (arrow_end_x, arrow_y)],
    fill=arrow_color,
    width=4
)

# 绘制箭头头部
arrow_size = 18
draw.polygon(
    [
        (arrow_end_x, arrow_y),
        (arrow_end_x - arrow_size, arrow_y - arrow_size//2),
        (arrow_end_x - arrow_size, arrow_y + arrow_size//2)
    ],
    fill=arrow_color
)

# 保存
image.save('dmg-staging/.background/background.png')
print("✅ 精美背景图创建成功")
PYTHON

# 创建 DMG
echo "🔨 创建 DMG..."
hdiutil create -volname "${VOLUME_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov -format UDRW \
    -size 100m \
    temp.dmg

# 挂载 DMG
echo "📂 挂载 DMG..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen temp.dmg | \
    egrep '^/dev/' | sed 1q | awk '{print $1}')
MOUNT_DIR="/Volumes/${VOLUME_NAME}"

echo "设备: ${DEVICE}"
echo "挂载点: ${MOUNT_DIR}"
echo "等待挂载完成..."
sleep 5

# 确保 Finder 已启动
echo "🎨 启动 Finder..."
open -a Finder
sleep 2

# 配置 Finder 窗口 - 分步执行，增加等待时间
echo "🎨 配置 Finder 窗口（第1步：打开窗口）..."
osascript << APPLESCRIPT1
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        delay 2
    end tell
end tell
APPLESCRIPT1

sleep 3

echo "🎨 配置 Finder 窗口（第2步：设置视图）..."
osascript << APPLESCRIPT2
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 550}
        delay 1
    end tell
end tell
APPLESCRIPT2

sleep 2

echo "🎨 配置 Finder 窗口（第3步：设置图标和背景）..."
osascript << APPLESCRIPT3
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set text size of viewOptions to 14

        -- 设置背景图
        set background picture of viewOptions to file ".background:background.png"

        delay 2
    end tell
end tell
APPLESCRIPT3

sleep 3

echo "🎨 配置 Finder 窗口（第4步：设置图标位置）..."
osascript << APPLESCRIPT4
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        -- 设置图标位置
        set position of item "${APP_NAME}.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}

        delay 2

        -- 刷新窗口
        close
        delay 1
        open

        update without registering applications
        delay 3
    end tell
end tell
APPLESCRIPT4

echo "等待 Finder 完全更新..."
sleep 5

# 隐藏背景文件夹
chflags hidden "${MOUNT_DIR}/.background" 2>/dev/null || true

# 设置权限
chmod -Rf go-w "${MOUNT_DIR}" 2>/dev/null || true
sync
sync

# 卸载
echo "💾 卸载 DMG..."
hdiutil detach "${DEVICE}"
sleep 3

# 转换为压缩的只读 DMG
echo "🗜️  压缩 DMG..."
hdiutil convert temp.dmg -format UDZO -imagekey zlib-level=9 -o "${FINAL_DMG}"

# 清理
echo "🧹 清理临时文件..."
rm -f temp.dmg
rm -rf "${STAGING_DIR}"

echo ""
echo "✅ 精美的 DMG 安装包创建完成！"
echo "📦 文件: ${FINAL_DMG}"
ls -lh "${FINAL_DMG}"
echo ""
echo "🎯 特性："
echo "  - 🎨 精美渐变背景"
echo "  - 📝 清晰的安装说明"
echo "  - 📅 全新日历图标（128x128）"
echo "  - ➡️  箭头指示拖拽方向"
echo "  - 💎 专业的视觉效果"
