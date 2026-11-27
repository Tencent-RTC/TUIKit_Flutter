#!/bin/bash
# 批量把 iOS Assets.xcassets 的素材导出为 Flutter package 的素材目录。
#
# 用法: ./export_ios_assets.sh <Assets.xcassets 路径> <目标 assets 目录>
#
# 规则:
#   - imageset 内为 .svg: 按 svg 的 width（无则取 24）导出 1x/2x/3x PNG。
#   - imageset 内为 .png: 按 Contents.json 的 scale 放到对应倍图目录。
# 已存在的产物会被覆盖。

set -euo pipefail

SRC_XCASSETS="$1"
DEST_DIR="$2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$SRC_XCASSETS" ]; then
  echo "xcassets not found: $SRC_XCASSETS" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

for imageset in "$SRC_XCASSETS"/*.imageset; do
  [ -d "$imageset" ] || continue
  name="$(basename "$imageset" .imageset)"

  svg="$(find "$imageset" -maxdepth 1 -name '*.svg' | head -1)"
  if [ -n "$svg" ]; then
    width="$(sed -n 's/.*<svg[^>]*[^-]width="\([0-9]*\)".*/\1/p' "$svg" | head -1)"
    "$SCRIPT_DIR/svg_to_png.sh" "$svg" "$DEST_DIR" "${width:-24}" "$name" >/dev/null
    echo "svg  -> $name (${width:-24}pt)"
    continue
  fi

  for png in "$imageset"/*.png; do
    [ -f "$png" ] || continue
    base="$(basename "$png")"
    case "$base" in
      *@3x.png) mkdir -p "$DEST_DIR/3.0x"; cp "$png" "$DEST_DIR/3.0x/$name.png" ;;
      *@2x.png) mkdir -p "$DEST_DIR/2.0x"; cp "$png" "$DEST_DIR/2.0x/$name.png" ;;
      *) cp "$png" "$DEST_DIR/$name.png" ;;
    esac
  done
  echo "png  -> $name"
done
