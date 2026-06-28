#!/usr/bin/env bash
# =============================================================================
# TRS Browser — build.sh
# Збирає браузер у режимі debug або release.
#
# Використання:
#   ./scripts/build.sh debug
#   ./scripts/build.sh release
#   ./scripts/build.sh debug --jobs 8   (кількість паралельних завдань)
# =============================================================================

set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${BLUE}[TRS]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}  $*"; }
error()   { echo -e "${RED}[ERR]${NC} $*"; exit 1; }

MODE="${1:-debug}"
JOBS="${3:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

TRS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROMIUM_SRC="$TRS_ROOT/../chromium/src"

[[ -d "$CHROMIUM_SRC" ]] || error "Chromium не знайдено. Спочатку запусти: ./scripts/setup.sh"
export PATH="$HOME/.depot_tools:$PATH"

case "$MODE" in
  debug)
    OUT_DIR="out/TRS_Debug"
    info "Збираємо DEBUG білд (швидше, з символами дебагу)..."
    ;;
  release)
    OUT_DIR="out/TRS_Release"
    info "Збираємо RELEASE білд (повільніше, оптимізований)..."
    
    mkdir -p "$CHROMIUM_SRC/$OUT_DIR"
    cat > "$CHROMIUM_SRC/$OUT_DIR/args.gn" << 'GN_EOF'
is_debug = false
is_official_build = true
symbol_level = 0
enable_nacl = false
chrome_pgo_phase = 0
trs_enable_ai_engine = true
trs_enable_ua_shield = true
trs_enable_edu_workspace = true
GN_EOF
    cd "$CHROMIUM_SRC"
    gn gen "$OUT_DIR"
    ;;
  *)
    error "Невідомий режим: $MODE. Використовуй: debug або release"
    ;;
esac

cd "$CHROMIUM_SRC"

START_TIME=$(date +%s)
info "Починаємо білд з $JOBS потоками..."
info "Перший білд займає 1–3 години. Наступні — набагато швидше."

autoninja -C "$OUT_DIR" chrome -j "$JOBS"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
MINUTES=$(( ELAPSED / 60 ))

echo ""
success "Білд завершено за ${MINUTES} хв!"
echo -e "  Запуск: ${BLUE}$CHROMIUM_SRC/$OUT_DIR/chrome${NC}"
echo ""
