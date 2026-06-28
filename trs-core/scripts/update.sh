#!/usr/bin/env bash
# =============================================================================
# TRS Browser — update.sh
# Синхронізує з новою версією upstream Chromium.
# Запускати коли виходить нова стабільна версія Chrome.
#
# Використання:
#   ./scripts/update.sh 125.0.6422.60
# =============================================================================

set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${BLUE}[TRS]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[!!]${NC}  $*"; }
error()   { echo -e "${RED}[ERR]${NC} $*"; exit 1; }

NEW_VERSION="${1:-}"
[[ -z "$NEW_VERSION" ]] && error "Вкажи версію: ./scripts/update.sh 125.0.6422.60"

TRS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROMIUM_SRC="$TRS_ROOT/../chromium/src"
export PATH="$HOME/.depot_tools:$PATH"

info "Оновлення Chromium до версії $NEW_VERSION"
warn "Це може зламати патчі TRS. Перевір конфлікти після оновлення."

cd "$CHROMIUM_SRC"

# Зберігаємо поточні зміни TRS
info "Зберігаємо TRS-зміни в stash..."
git stash push -m "trs-changes-before-update-$NEW_VERSION"

# Оновлюємо до нової версії
git fetch --tags
git checkout "refs/tags/$NEW_VERSION" -b "trs-base-$NEW_VERSION"

# Синхронізуємо залежності
info "Синхронізуємо залежності..."
gclient sync --with_branch_heads --with_tags -D

# Повертаємо TRS-зміни
info "Відновлюємо TRS-зміни..."
git stash pop || warn "Є конфлікти! Вирішуй вручну в trs/src/"

# Регенеруємо конфіг
gn gen out/TRS_Debug
gn gen out/TRS_Release 2>/dev/null || true

success "Оновлення до $NEW_VERSION завершено"
info "Запусти ./scripts/build.sh debug щоб перевірити що все компілюється"
