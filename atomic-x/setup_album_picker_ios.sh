#!/bin/bash

# AlbumPicker iOS 集成脚本
# 用于快速复制 iOS SwiftUI 端的 AlbumPicker 代码到 Flutter 插件

set -e

echo "=========================================="
echo "AlbumPicker iOS 集成脚本"
echo "=========================================="

# 定义路径
IOS_SWIFTUI_BASE="../../ios_swiftui"
IOS_SWIFTUI_SRC="$IOS_SWIFTUI_BASE/Sources/AlbumPicker"
IOS_SWIFTUI_STRINGS="$IOS_SWIFTUI_BASE/Resources/strings/AlbumPickerLocalizable.bundle"

FLUTTER_IOS_BASE="./ios"
FLUTTER_IOS_CLASSES="$FLUTTER_IOS_BASE/Classes"
FLUTTER_IOS_ALBUMPICKER="$FLUTTER_IOS_CLASSES/AlbumPicker"
FLUTTER_IOS_RESOURCES="$FLUTTER_IOS_BASE/Assets"

# 检查源目录是否存在
if [ ! -d "$IOS_SWIFTUI_SRC" ]; then
    echo "❌ 错误: 找不到源目录 $IOS_SWIFTUI_SRC"
    echo "请确保在正确的目录下执行此脚本"
    exit 1
fi

# 创建目标目录
echo "📁 创建目标目录..."
mkdir -p "$FLUTTER_IOS_ALBUMPICKER"
mkdir -p "$FLUTTER_IOS_RESOURCES"

# 1. 复制 AlbumPicker Swift 代码
echo "📋 复制 AlbumPicker Swift 代码..."
cp -r "$IOS_SWIFTUI_SRC"/* "$FLUTTER_IOS_ALBUMPICKER/"
echo "✅ AlbumPicker Swift 代码复制成功"

# 2. 复制国际化字符串文件
echo "📋 复制国际化字符串文件..."
if [ -d "$IOS_SWIFTUI_STRINGS" ]; then
    cp -r "$IOS_SWIFTUI_STRINGS" "$FLUTTER_IOS_RESOURCES"
    echo "✅ 国际化字符串文件复制成功"
else
    echo "⚠️  警告: 找不到 $IOS_SWIFTUI_STRINGS"
fi

# 检查是否成功
if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 所有文件复制成功！"
    echo "=========================================="
    echo ""
    echo "已复制的 AlbumPicker Swift 文件："
    find "$FLUTTER_IOS_ALBUMPICKER" -type f -name "*.swift" | sed 's/^/  - /'
    echo ""
    echo "已复制的国际化资源文件："
    find "$FLUTTER_IOS_STRINGS" -type f -name "*.strings" 2>/dev/null | sed 's/^/  - /' || echo "  (无)"
    echo ""
    echo "=========================================="
    echo "下一步操作："
    echo "1. 创建 AlbumPickerPlugin.swift 和 AlbumPickerHandler.swift"
    echo "2. 更新 AtomicXPlugin.swift 注册 AlbumPicker 模块"
    echo "3. 检查 atomic_x.podspec 是否包含必要的依赖"
    echo "   - s.dependency 'Photos'"
    echo "   - s.dependency 'AVFoundation'"
    echo "4. 更新 Dart 层代码支持 iOS"
    echo "5. 运行 pod install"
    echo "6. 编译并测试"
    echo ""
    echo "详细文档请查看: ALBUM_PICKER_IOS_INTEGRATION.md"
    echo "=========================================="
else
    echo "❌ 复制失败，请检查错误信息"
    exit 1
fi
