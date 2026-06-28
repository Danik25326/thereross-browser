#!/usr/bin/env bash
# =============================================================================
# TRS Browser — brand.sh
# Замінює назви/брендинг Chrome → Thereross (TRS) у ресурсах Chromium.
# Запускати ОДИН РАЗ після setup.sh.
#
# Використання:
#   ./scripts/brand.sh
# =============================================================================

set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; NC='\033[0m'
info()    { echo -e "${BLUE}[TRS]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}  $*"; }

TRS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROMIUM_SRC="$TRS_ROOT/../chromium/src"

[[ -d "$CHROMIUM_SRC" ]] || { echo "Спочатку запусти setup.sh"; exit 1; }

info "Починаємо ребрендинг Chrome → Thereross..."

# Файли де безпечно міняти назву продукту
BRAND_FILES=(
  "chrome/app/chromium_strings.grd"
  "chrome/app/generated_resources.grd"
  "chrome/common/chrome_constants.cc"
)

for file in "${BRAND_FILES[@]}"; do
  filepath="$CHROMIUM_SRC/$file"
  if [[ -f "$filepath" ]]; then
    # Backup
    cp "$filepath" "$filepath.trs-backup"
    # Заміна
    sed -i 's/Chromium/Thereross/g; s/Google Chrome/Thereross/g' "$filepath"
    success "Оновлено: $file"
  fi
done

# Копіюємо іконки TRS
info "Копіюємо іконки TRS..."
ICON_DST="$CHROMIUM_SRC/chrome/app/theme/chromium"
mkdir -p "$ICON_DST"

for size in 16 32 128 256; do
  src_icon="$TRS_ROOT/resources/icons/trs_logo_${size}.png"
  if [[ -f "$src_icon" ]]; then
    cp "$src_icon" "$ICON_DST/product_logo_${size}.png"
    success "Іконка ${size}px скопійована"
  else
    info "Іконка ${size}px відсутня — використається стандартна Chromium"
  fi
done

success "Ребрендинг завершено!"
info "Тепер збери браузер: ./scripts/build.sh debug"
