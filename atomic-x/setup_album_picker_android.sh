#!/bin/bash

# AlbumPicker 集成脚本
# 用于快速复制 Android Compose 端的 AlbumPicker 代码到 Flutter 插件

set -e

echo "=========================================="
echo "AlbumPicker 集成脚本"
echo "=========================================="

# 定义路径
ANDROID_COMPOSE_BASE="../../android_compose/src/main"
ANDROID_COMPOSE_SRC="$ANDROID_COMPOSE_BASE/java/io/trtc/tuikit/atomicx/albumpicker"
ANDROID_COMPOSE_BASECOMPONENT="$ANDROID_COMPOSE_BASE/java/io/trtc/tuikit/atomicx/basecomponent"
ANDROID_COMPOSE_RES="$ANDROID_COMPOSE_BASE/res/values/themes.xml"
ANDROID_COMPOSE_RES_ALBUM="$ANDROID_COMPOSE_BASE/res-album-picker"

FLUTTER_ANDROID_BASE="./android/src/main"
FLUTTER_ANDROID_DST="$FLUTTER_ANDROID_BASE/kotlin/io/trtc/tuikit/atomicx/albumpicker"
FLUTTER_ANDROID_BASECOMPONENT="$FLUTTER_ANDROID_BASE/kotlin/io/trtc/tuikit/atomicx/basecomponent"
FLUTTER_ANDROID_RES="$FLUTTER_ANDROID_BASE/res"
FLUTTER_ANDROID_RES_ALBUM="$FLUTTER_ANDROID_BASE/res-album-picker"

# 检查源目录是否存在
if [ ! -d "$ANDROID_COMPOSE_SRC" ]; then
    echo "❌ 错误: 找不到源目录 $ANDROID_COMPOSE_SRC"
    echo "请确保在正确的目录下执行此脚本"
    exit 1
fi

# 创建目标目录
echo "📁 创建目标目录..."
mkdir -p "$FLUTTER_ANDROID_DST"
mkdir -p "$FLUTTER_ANDROID_BASECOMPONENT"
mkdir -p "$FLUTTER_ANDROID_RES/values"
mkdir -p "$FLUTTER_ANDROID_RES_ALBUM"

# 1. 复制 AlbumPicker Kotlin 代码
echo "📋 复制 AlbumPicker Kotlin 代码..."
cp -r "$ANDROID_COMPOSE_SRC"/* "$FLUTTER_ANDROID_DST/"

# 2. 复制 BaseComponent 文件和文件夹
echo "📋 复制 BaseComponent 文件和文件夹..."

# 复制 FullScreenDialog.kt
if [ -f "$ANDROID_COMPOSE_BASECOMPONENT/FullScreenDialog.kt" ]; then
    cp "$ANDROID_COMPOSE_BASECOMPONENT/FullScreenDialog.kt" "$FLUTTER_ANDROID_BASECOMPONENT/"
    echo "✅ FullScreenDialog.kt 复制成功"
else
    echo "⚠️  警告: 找不到 $ANDROID_COMPOSE_BASECOMPONENT/FullScreenDialog.kt"
fi

# 复制 config 文件夹
if [ -d "$ANDROID_COMPOSE_BASECOMPONENT/config" ]; then
    mkdir -p "$FLUTTER_ANDROID_BASECOMPONENT/config"
    cp -r "$ANDROID_COMPOSE_BASECOMPONENT/config"/* "$FLUTTER_ANDROID_BASECOMPONENT/config/"
    echo "✅ config 文件夹复制成功"
else
    echo "⚠️  警告: 找不到 $ANDROID_COMPOSE_BASECOMPONENT/config"
fi

# 复制 theme 文件夹
if [ -d "$ANDROID_COMPOSE_BASECOMPONENT/theme" ]; then
    mkdir -p "$FLUTTER_ANDROID_BASECOMPONENT/theme"
    cp -r "$ANDROID_COMPOSE_BASECOMPONENT/theme"/* "$FLUTTER_ANDROID_BASECOMPONENT/theme/"
    echo "✅ theme 文件夹复制成功"
else
    echo "⚠️  警告: 找不到 $ANDROID_COMPOSE_BASECOMPONENT/theme"
fi

# 复制 utils 文件夹
if [ -d "$ANDROID_COMPOSE_BASECOMPONENT/utils" ]; then
    mkdir -p "$FLUTTER_ANDROID_BASECOMPONENT/utils"
    cp -r "$ANDROID_COMPOSE_BASECOMPONENT/utils"/* "$FLUTTER_ANDROID_BASECOMPONENT/utils/"
    echo "✅ utils 文件夹复制成功"
else
    echo "⚠️  警告: 找不到 $ANDROID_COMPOSE_BASECOMPONENT/utils"
fi

# 3. 复制 themes.xml
echo "📋 复制 themes.xml..."
if [ -f "$ANDROID_COMPOSE_RES" ]; then
    cp "$ANDROID_COMPOSE_RES" "$FLUTTER_ANDROID_RES/values/themes.xml"
    echo "✅ themes.xml 复制成功"
else
    echo "⚠️  警告: 找不到 $ANDROID_COMPOSE_RES"
fi

# 4. 复制 res-album-picker 文件夹
echo "📋 复制 res-album-picker 资源文件夹..."
if [ -d "$ANDROID_COMPOSE_RES_ALBUM" ]; then
    cp -r "$ANDROID_COMPOSE_RES_ALBUM"/* "$FLUTTER_ANDROID_RES_ALBUM/"
    echo "✅ res-album-picker 复制成功"
else
    echo "⚠️  警告: 找不到 $ANDROID_COMPOSE_RES_ALBUM"
fi

# 检查是否成功
if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 所有文件复制成功！"
    echo "=========================================="
    echo ""
    echo "已复制的 AlbumPicker Kotlin 文件："
    find "$FLUTTER_ANDROID_DST" -type f -name "*.kt" | sed 's/^/  - /'
    echo ""
    echo "已复制的 BaseComponent 文件："
    if [ -f "$FLUTTER_ANDROID_BASECOMPONENT/FullScreenDialog.kt" ]; then
        echo "  - $FLUTTER_ANDROID_BASECOMPONENT/FullScreenDialog.kt"
    fi
    if [ -d "$FLUTTER_ANDROID_BASECOMPONENT/config" ]; then
        find "$FLUTTER_ANDROID_BASECOMPONENT/config" -type f -name "*.kt" | sed 's/^/  - /'
    fi
    if [ -d "$FLUTTER_ANDROID_BASECOMPONENT/theme" ]; then
        find "$FLUTTER_ANDROID_BASECOMPONENT/theme" -type f -name "*.kt" | sed 's/^/  - /'
    fi
    if [ -d "$FLUTTER_ANDROID_BASECOMPONENT/utils" ]; then
        find "$FLUTTER_ANDROID_BASECOMPONENT/utils" -type f -name "*.kt" | sed 's/^/  - /'
    fi
    echo ""
    echo "已复制的资源文件："
    echo "  - $FLUTTER_ANDROID_RES/values/themes.xml"
    find "$FLUTTER_ANDROID_RES_ALBUM" -type f | sed 's/^/  - /'
    echo ""
    echo "=========================================="
    echo "下一步操作："
    echo "1. 检查 android/build.gradle 是否包含必要的依赖"
    echo "   - implementation(\"com.tencent.liteav.tuikit:tuicore:8.6.7021\")"
    echo "   - implementation(\"androidx.appcompat:appcompat:1.7.0\")"
    echo "   - apply plugin: \"kotlin-parcelize\""
    echo "2. 检查 android/build.gradle 的 sourceSets 配置"
    echo "   - main.res.srcDirs = [\"src/main/res\", \"src/main/res-album-picker\"]"
    echo "3. 检查 AndroidManifest.xml 是否声明了权限和 Activity"
    echo "4. 运行 flutter pub get"
    echo "5. 编译并测试"
    echo ""
    echo "详细文档请查看: ALBUM_PICKER_INTEGRATION.md"
    echo "=========================================="
else
    echo "❌ 复制失败，请检查错误信息"
    exit 1
fi
