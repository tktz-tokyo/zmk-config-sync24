#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[phase2] Repository: $ROOT_DIR"

check() {
  local label="$1"
  local cmd="$2"
  echo "- $label"
  bash -lc "$cmd"
}

# 1) Static pin checks (always available)
check "CI workflow pin is v0.3" "grep -n 'build-user-config.yml@v0.3' .github/workflows/build.yml"
check "west manifest has naginata fork and pin" "grep -nE 'naginata-fork|zmk-naginata|revision: 71c0070' config/west.yml"

# 2) Tooling check
if ! command -v west >/dev/null 2>&1; then
  echo "[warn] west command is not available in this environment."
  echo "[next] Install west, then run:"
  echo "       west update"
  echo "       west build -s zmk/app -d build/left -b seeeduino_xiao_ble -- -DSHIELD=sync24_left"
  echo "       west build -s zmk/app -d build/right -b seeeduino_xiao_ble -- -DSHIELD=sync24_right"
  exit 0
fi

# 3) Materialize modules and verify fork checkout
check "west update" "west update"

if [ ! -d modules/lib/zmk-naginata/.git ] && [ ! -f modules/lib/zmk-naginata/CMakeLists.txt ]; then
  echo "[error] modules/lib/zmk-naginata not found after west update."
  exit 1
fi

check "show naginata HEAD" "git -C modules/lib/zmk-naginata rev-parse --short HEAD"

# 4) Build checks
check "build left" "west build -s zmk/app -d build/left -b seeeduino_xiao_ble -- -DSHIELD=sync24_left"
check "build right" "west build -s zmk/app -d build/right -b seeeduino_xiao_ble -- -DSHIELD=sync24_right"

echo "[done] Phase2 Method A runbook checks completed."
