#!/usr/bin/env bash
# =============================================================================
# TRS Browser — setup.sh
# Клонує Chromium, встановлює depot_tools, готує середовище для першого білду.
# Запускати ОДИН РАЗ на новій машині.
#
# Використання:
#   ./scripts/setup.sh
#   ./scripts/setup.sh --skip-sync   (якщо Chromium вже є)
# =============================================================================

set -euo pipefail

# ---------- кольори для виводу ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[TRS]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[!!]${NC}  $*"; }
error()   { echo -e "${RED}[ERR]${NC} $*"; exit 1; }

# ---------- версія Chromium ----------
# Зафіксована стабільна версія. Оновлювати свідомо через update.sh.
CHROMIUM_VERSION="124.0.6367.82"
DEPOT_TOOLS_DIR="$HOME/.depot_tools"
TRS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROMIUM_DIR="$TRS_ROOT/../chromium"   # поруч з trs-core, не всередині

SKIP_SYNC=false
[[ "${1:-}" == "--skip-sync" ]] && SKIP_SYNC=true

# =============================================================================
echo ""
echo -e "${BOLD}  Thereross (TRS) Browser — налаштування середовища${NC}"
echo -e "  Версія Chromium: ${CHROMIUM_VERSION}"
echo -e "  Потрібно місця: ~100 ГБ"
echo ""
# =============================================================================

# ---------- 1. Перевіряємо ОС ----------
info "Перевіряємо операційну систему..."
OS="$(uname -s)"
case "$OS" in
  Linux)   success "Linux — підтримується"; PLATFORM="linux" ;;
  Darwin)  success "macOS — підтримується"; PLATFORM="mac" ;;
  *)       error "Windows: запускай setup.bat, не цей скрипт" ;;
esac

# ---------- 2. Перевіряємо залежності ----------
info "Перевіряємо залежності..."

check_cmd() {
  if command -v "$1" &>/dev/null; then
    success "$1 знайдено ($(command -v "$1"))"
  else
    error "$1 не знайдено. Встанови: $2"
  fi
}

check_cmd git    "sudo apt install git / brew install git"
check_cmd python3 "sudo apt install python3 / brew install python3"
check_cmd curl   "sudo apt install curl / brew install curl"

# Linux: додаткові залежності
if [[ "$PLATFORM" == "linux" ]]; then
  info "Встановлюємо системні залежності Linux..."
  sudo apt-get update -q
  sudo apt-get install -y -q \
    build-essential \
    clang \
    ninja-build \
    lld \
    pkg-config \
    libgtk-3-dev \
    libnss3-dev \
    libdrm-dev \
    libxkbcommon-dev \
    || warn "Деякі пакети не встановились — перевір вручну"
  success "Системні залежності встановлено"
fi

# ---------- 3. depot_tools ----------
info "Встановлюємо depot_tools (інструменти Google для Chromium)..."

if [[ -d "$DEPOT_TOOLS_DIR" ]]; then
  warn "depot_tools вже є: $DEPOT_TOOLS_DIR. Оновлюємо..."
  cd "$DEPOT_TOOLS_DIR" && git pull --quiet
else
  git clone --quiet https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS_DIR"
  success "depot_tools клоновано"
fi

# Додаємо в PATH поточної сесії
export PATH="$DEPOT_TOOLS_DIR:$PATH"

# Підказка для постійного PATH
SHELL_RC="$HOME/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "depot_tools" "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo "# depot_tools для TRS Browser" >> "$SHELL_RC"
  echo "export PATH=\"\$HOME/.depot_tools:\$PATH\"" >> "$SHELL_RC"
  success "Додано depot_tools в $SHELL_RC"
fi

# ---------- 4. Клонуємо Chromium ----------
if [[ "$SKIP_SYNC" == true ]]; then
  warn "--skip-sync: пропускаємо клонування Chromium"
else
  info "Клонуємо Chromium $CHROMIUM_VERSION..."
  info "Це займе 30–90 хвилин залежно від інтернету..."
  
  mkdir -p "$CHROMIUM_DIR"
  cd "$CHROMIUM_DIR"

  if [[ ! -f ".gclient" ]]; then
    fetch --nohooks chromium
    success "Chromium cloned"
  else
    warn ".gclient вже є — пропускаємо fetch"
  fi

  cd src
  git fetch --tags --quiet
  git checkout "refs/tags/$CHROMIUM_VERSION" -b "trs-base-$CHROMIUM_VERSION" 2>/dev/null \
    || warn "Гілка вже існує, продовжуємо"

  # Синхронізуємо залежності (велика операція)
  gclient sync --with_branch_heads --with_tags -D
  success "Chromium $CHROMIUM_VERSION готовий"

  # ---------- 5. Хуки ----------
  info "Запускаємо хуки Chromium (clang, sysroot...)..."
  gclient runhooks
  success "Хуки виконано"
fi

# ---------- 6. Симлінкуємо наш код у Chromium ----------
info "Підключаємо TRS-код до Chromium дерева..."

CHROMIUM_SRC="$CHROMIUM_DIR/src"
TRS_VENDOR="$CHROMIUM_SRC/trs"

if [[ ! -L "$TRS_VENDOR" ]]; then
  ln -sf "$TRS_ROOT/src" "$TRS_VENDOR"
  success "Симлінк: chromium/src/trs -> trs-core/src"
else
  warn "Симлінк вже існує: $TRS_VENDOR"
fi

# ---------- 7. Генеруємо конфіг білду ----------
info "Генеруємо GN конфіг для debug-білду..."

mkdir -p "$CHROMIUM_SRC/out/TRS_Debug"
cat > "$CHROMIUM_SRC/out/TRS_Debug/args.gn" << 'GN_EOF'
# TRS Browser — debug build config
is_debug = true
is_component_build = true
symbol_level = 1
enable_nacl = false
blink_symbol_level = 0

# Бренд TRS
chrome_pgo_phase = 0
is_official_build = false

# Вмикаємо наші фічі
trs_enable_ai_engine = true
trs_enable_ua_shield = true
trs_enable_edu_workspace = true
GN_EOF

cd "$CHROMIUM_SRC"
gn gen out/TRS_Debug
success "GN конфіг згенеровано: out/TRS_Debug/args.gn"

# ---------- 8. Готово ----------
echo ""
echo -e "${GREEN}${BOLD}  Середовище TRS готове!${NC}"
echo ""
echo -e "  Наступні кроки:"
echo -e "  ${BOLD}1.${NC} Зібрати браузер:"
echo -e "     ${BLUE}./scripts/build.sh debug${NC}"
echo ""
echo -e "  ${BOLD}2.${NC} Запустити після білду:"
echo -e "     ${BLUE}$CHROMIUM_DIR/src/out/TRS_Debug/chrome${NC}"
echo ""
echo -e "  ${BOLD}3.${NC} Почати кодити:"
echo -e "     ${BLUE}trs-core/src/browser/trs_browser_main.cc${NC}"
echo ""
