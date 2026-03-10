#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[diag] repo: $ROOT_DIR"

echo "[diag] python: $(python3 --version 2>/dev/null || echo missing)"
echo "[diag] pip: $(python3 -m pip --version 2>/dev/null || echo missing)"

if command -v west >/dev/null 2>&1; then
  echo "[diag] west: $(west --version)"
else
  echo "[diag] west: missing"
fi

# network sanity checks for known endpoints
check_url() {
  local name="$1"
  local url="$2"
  if curl -I -sS --max-time 10 "$url" >/tmp/phase2_diag_head.out 2>/tmp/phase2_diag_head.err; then
    local status
    status="$(head -n 1 /tmp/phase2_diag_head.out)"
    echo "[diag] $name: ok ($status)"
  else
    local err
    err="$(tr '\n' ' ' </tmp/phase2_diag_head.err | sed 's/  */ /g')"
    echo "[diag] $name: fail ($err)"
  fi
}

check_url "github" "https://github.com"
check_url "pypi" "https://pypi.org/simple/west/"

echo "[diag] Suggested next steps:"
echo "  1) Ensure proxy/network allows github.com and pypi.org"
echo "  2) Install west: python3 -m pip install --user west"
echo "  3) Run: ./scripts/phase2_methodA_runbook.sh"
