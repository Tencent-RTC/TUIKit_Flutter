#!/usr/bin/env bash
#
# atomic_x_core 发布脚本。
#
# 思路：备份 -> 原地改源码 ->
# dry-run -> 确认 -> pub publish -> 恢复。所有改动都是暂时的，脚本正常
# 或异常退出（trap EXIT）都会自动还原工作区，跟日常开发无冲突。
#
# 发布产物里会移除 Chat 相关目录/文件，并同步删掉 barrel 里对应的 export。
# pubspec.yaml 的 dependencies 不动。
#
# 用法示例：
#   ./publish.sh --exclude-chat                            # dry-run，问是否发
#   ./publish.sh --exclude-chat --dry-run-only             # 只 dry-run，不问不发
#   ./publish.sh --exclude-chat --package-name atomic_x_live_kit
#   ./publish.sh --exclude-chat --publish                  # dry-run 后直接发
#
# 环境变量覆盖（CI 场景更方便）：
#   ATOMIC_ENGINE_EXCLUDE_CHAT=true
#   ATOMIC_ENGINE_PACKAGE_NAME=atomic_x_live_kit
#   ATOMIC_ENGINE_AUTO_PUBLISH=true

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# --- 参数 --------------------------------------------------------------------
EXCLUDE_CHAT="${ATOMIC_ENGINE_EXCLUDE_CHAT:-false}"
PACKAGE_NAME="${ATOMIC_ENGINE_PACKAGE_NAME:-}"
AUTO_PUBLISH="${ATOMIC_ENGINE_AUTO_PUBLISH:-false}"
DRY_RUN_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --exclude-chat)          EXCLUDE_CHAT=true; shift ;;
    --package-name)          PACKAGE_NAME="$2"; shift 2 ;;
    --package-name=*)        PACKAGE_NAME="${1#*=}"; shift ;;
    --publish)               AUTO_PUBLISH=true; shift ;;
    --dry-run-only)          DRY_RUN_ONLY=true; shift ;;
    -h|--help)
      sed -n '3,23p' "$0"; exit 0 ;;
    *)
      echo_error "未知参数：$1"; exit 64 ;;
  esac
done

# --- 定位包根目录 -------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f pubspec.yaml ] || [ ! -f lib/atomicxcore.dart ]; then
  echo_error "脚本必须放在 atomic_x_core 包根目录（有 pubspec.yaml 和 lib/atomicxcore.dart）"
  exit 1
fi

# --- pre-flight：确保本地测试用二进制没残留在会被打包的目录 ------------------
# 这些目录仅供本地开发调试使用（本地编的 LiteAV 13.5.x / AtomicXCore.xcframework
# 等 Maven 未发布版本）；发布到 pub.dev 会：
#   1. 违反 LiteAV 商业 SDK license；
#   2. 撑爆 pub.dev 单包 100MB 上限；
#   3. 泄露内部编译产物给外部客户。
# .pubignore 曾用来兜底，但"悄悄过滤"不如"主动拦截"安全——这里明确 abort，
# 迫使发布者手工确认。
LOCAL_BINARY_DIRS=(
  android/libs
  android/src/main/jniLibs
  ios/Frameworks
)

violations=()
for d in "${LOCAL_BINARY_DIRS[@]}"; do
  if [ -d "$d" ] && [ -n "$(find "$d" -type f ! -name '.gitkeep' 2>/dev/null | head -1)" ]; then
    violations+=("$d")
  fi
done

if [ ${#violations[@]} -gt 0 ]; then
  echo_error "以下目录里检测到本地测试用二进制，发布前必须清空："
  for d in "${violations[@]}"; do
    echo_error "  - $d/"
    find "$d" -type f ! -name '.gitkeep' 2>/dev/null | head -3 | sed 's/^/      /'
    file_count=$(find "$d" -type f ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$file_count" -gt 3 ]; then
      echo_error "      ...还有 $((file_count - 3)) 个文件"
    fi
  done
  echo_error ""
  echo_error "参考做法：手动 rm -rf 上述目录，或 git stash 相关改动后重跑本脚本。"
  exit 1
fi

# --- 备份 & 恢复 -------------------------------------------------------------
# Chat 排除清单
CHAT_PATHS=(
  lib/api/contact
  lib/api/conversation
  lib/api/group
  lib/api/message
  lib/api/search
  lib/impl/contact
  lib/impl/conversation
  lib/impl/group
  lib/impl/message
  lib/impl/search
  lib/impl/common/chat_util.dart
)

# 会被修改的文件（除 CHAT_PATHS 外）
MUTABLE_FILES=(
  lib/atomicxcore.dart
  pubspec.yaml
)

# 备份文件放在包根目录。
# 优点：位置显眼、异常残留时肉眼可见、方便手动恢复。
# 已在 .pubignore 里排除，不会被打包上传；.gitignore 也应加避免误 commit。
BACKUP_TAR="./.publish_backup.tar.gz"

if [ -e "$BACKUP_TAR" ]; then
  echo_error "检测到已存在备份文件：$BACKUP_TAR"
  echo_error "这通常意味着上一次脚本异常退出未能恢复工作区。"
  echo_error "请先人工检查（tar tzf $BACKUP_TAR 查看内容），确认无误后手动删除或恢复，再重新运行。"
  exit 1
fi

RESTORED=false

restore_workspace() {
  if [ "$RESTORED" = true ]; then
    return
  fi
  RESTORED=true
  if [ ! -f "$BACKUP_TAR" ]; then
    return
  fi
  echo_info "恢复工作区..."
  # 先把可能残留的目录全部清掉（脚本删过、tar 里又是空目录/文件的情况）
  for p in "${CHAT_PATHS[@]}"; do
    rm -rf "$p"
  done
  tar xzf "$BACKUP_TAR" -C .
  rm -f "$BACKUP_TAR"
  echo_info "工作区已恢复。"
}
trap restore_workspace EXIT INT TERM

# 只备份存在的路径，避免 tar 报错
BACKUP_LIST=()
for p in "${CHAT_PATHS[@]}" "${MUTABLE_FILES[@]}"; do
  if [ -e "$p" ]; then
    BACKUP_LIST+=("$p")
  fi
done

if [ ${#BACKUP_LIST[@]} -gt 0 ]; then
  echo_info "备份 ${#BACKUP_LIST[@]} 个文件/目录 -> $BACKUP_TAR"
  tar czf "$BACKUP_TAR" "${BACKUP_LIST[@]}"
fi

# --- 应用变体 -----------------------------------------------------------------
if [ "$EXCLUDE_CHAT" = "true" ]; then
  echo_info "变体：EXCLUDE_CHAT=true，开始移除 Chat 相关源码..."
  removed=0
  for p in "${CHAT_PATHS[@]}"; do
    if [ -e "$p" ]; then
      rm -rf "$p"
      echo_info "  已删除：$p"
      removed=$((removed + 1))
    fi
  done
  echo_info "共删除 $removed 个路径。"

  echo_info "同步移除 lib/atomicxcore.dart 里的 Chat export..."
  # 只删 export 行，避免误伤其它内容
  sed -i '' \
    -e "/^export 'api\/contact\//d" \
    -e "/^export 'api\/conversation\//d" \
    -e "/^export 'api\/group\//d" \
    -e "/^export 'api\/message\//d" \
    -e "/^export 'api\/search\//d" \
    -e "/^export 'impl\/common\/chat_util\.dart';/d" \
    lib/atomicxcore.dart
  echo_info "  barrel 已更新。"
else
  echo_info "未指定 --exclude-chat，本次不移除任何 Chat 代码。"
fi

# --- 可选：改包名 -------------------------------------------------------------
if [ -n "$PACKAGE_NAME" ]; then
  echo_info "改 pubspec name -> $PACKAGE_NAME"
  # 仅替换首行 name: 声明，不会碰到 dependencies 里的其它 name 字段
  sed -i '' "s/^name: .*/name: $PACKAGE_NAME/" pubspec.yaml
fi

# --- dry-run -----------------------------------------------------------------
echo_info "执行 flutter pub publish --dry-run ..."
set +e
flutter pub publish --dry-run
DRY_RUN_CODE=$?
set -e

if [ $DRY_RUN_CODE -ne 0 ]; then
  echo_warning "dry-run 返回非 0（${DRY_RUN_CODE}），请人工检查上方输出。"
  # 不直接 exit，让用户自己决定是否强行发；但脚本默认结束，工作区照常恢复。
fi

if [ "$DRY_RUN_ONLY" = true ]; then
  echo_info "--dry-run-only 已完成。"
  exit $DRY_RUN_CODE
fi

# --- 确认 & 发布 -------------------------------------------------------------
if [ "$AUTO_PUBLISH" != "true" ]; then
  echo ""
  echo_warning "请确认上面的 dry-run 输出。"
  read -r -p "是否继续发布? (y/n): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo_info "已取消发布。"
    exit 0
  fi
fi

if [ $DRY_RUN_CODE -ne 0 ]; then
  echo_error "dry-run 未通过（${DRY_RUN_CODE}），拒绝发布。修完再重试。"
  exit $DRY_RUN_CODE
fi

echo_info "开始 flutter pub publish ..."
flutter pub publish

echo_info "发布完成。"
