#!/bin/bash

# 创建临时文件夹
mkdir -p dmg-temp
cp -r run/release/AlwaysHaveAPlan.app dmg-temp/

# 创建应用程序文件夹的符号链接
ln -s /Applications dmg-temp/Applications

# 创建 DMG
hdiutil create -volname "AlwaysHaveAPlan" \
  -srcfolder dmg-temp \
  -ov -format UDZO \
  AlwaysHaveAPlan-v1.2.1-Installer.dmg

# 清理临时文件
rm -rf dmg-temp

echo "✅ DMG 安装包创建完成！"
