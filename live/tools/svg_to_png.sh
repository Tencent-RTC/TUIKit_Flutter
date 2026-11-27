#!/bin/bash
# 已弃用：不要再用本脚本导出图标素材。
#
# 图标与矢量素材统一从 Ardot 直接导出 PNG 多倍图（scale 1/2/3），Ardot 节点尺寸即显示尺寸。
# 本脚本从 iOS SVG 转换，且只接受单一 base_size、强制方形画布：
# 非正方形素材（如 34×26）会被放进 34×34 画布，Flutter 端 BoxFit.contain 再按短边缩放，
# 实测导致图标比设计小约 24%。仅保留用于查阅历史转换方式。
#
# 把 iOS 资源里的 SVG 导出为 Flutter 使用的多倍图 PNG。
#
# 用法: ./svg_to_png.sh <src.svg> <dest_dir> <base_size> [dest_name]
#   base_size 为 1x 逻辑像素边长（通常取 SVG 的 width/height）。
# 产物: <dest_dir>/<name>.png、<dest_dir>/2.0x/<name>.png、<dest_dir>/3.0x/<name>.png
#
# 用 Chrome headless 直接渲染 SVG（保留透明通道），渲染前把 SVG 的
# width/height 改写为目标像素并保证存在 viewBox，从而等比缩放。
# 不使用 qlmanage：它会输出不透明白底缩略图。

set -euo pipefail

CHROME="${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

SRC="$1"
DEST_DIR="$2"
BASE_SIZE="$3"
NAME="${4:-$(basename "${SRC%.svg}")}"

if [ ! -f "$SRC" ]; then
  echo "svg not found: $SRC" >&2
  exit 1
fi
if [ ! -x "$CHROME" ]; then
  echo "chrome not found: $CHROME (set CHROME_BIN)" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

SRC_WIDTH="$(sed -n 's/.*<svg[^>]*[^-]width="\([0-9.]*\)".*/\1/p' "$SRC" | head -1)"
SRC_HEIGHT="$(sed -n 's/.*<svg[^>]*[^-]height="\([0-9.]*\)".*/\1/p' "$SRC" | head -1)"
HAS_VIEWBOX="$(grep -c 'viewBox' "$SRC" || true)"

render() {
  local size="$1"
  local out="$2"
  local scaled="$TMP_DIR/scaled_$size.svg"
  mkdir -p "$(dirname "$out")"

  python3 - "$SRC" "$scaled" "$size" "${SRC_WIDTH:-}" "${SRC_HEIGHT:-}" "$HAS_VIEWBOX" <<'PY'
import re
import sys

src, dest, size, src_w, src_h, has_viewbox = sys.argv[1:7]
text = open(src, encoding='utf-8').read()
match = re.search(r'<svg\b[^>]*>', text)
if not match:
    raise SystemExit('no <svg> tag: %s' % src)
tag = match.group(0)

if has_viewbox == '0':
    if not src_w or not src_h:
        raise SystemExit('svg without viewBox and size: %s' % src)
    tag = tag[:-1] + ' viewBox="0 0 %s %s">' % (src_w, src_h)

tag = re.sub(r'\swidth="[^"]*"', '', tag, count=1)
tag = re.sub(r'\sheight="[^"]*"', '', tag, count=1)
tag = tag[:-1] + ' width="%s" height="%s">' % (size, size)
open(dest, 'w', encoding='utf-8').write(text[:match.start()] + tag + text[match.end():])
PY

  "$CHROME" \
    --headless \
    --disable-gpu \
    --hide-scrollbars \
    --force-device-scale-factor=1 \
    --default-background-color=00000000 \
    --window-size="$size,$size" \
    --screenshot="$out" \
    "file://$scaled" >/dev/null 2>&1
  if [ ! -f "$out" ]; then
    echo "render failed: $SRC" >&2
    exit 1
  fi
}

render "$BASE_SIZE" "$DEST_DIR/$NAME.png"
render "$((BASE_SIZE * 2))" "$DEST_DIR/2.0x/$NAME.png"
render "$((BASE_SIZE * 3))" "$DEST_DIR/3.0x/$NAME.png"

echo "exported $NAME (${BASE_SIZE}pt) -> $DEST_DIR"
