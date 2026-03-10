#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <new-naginata-commit>"
  exit 1
fi

NEW_REV="$1"

# very basic commit-ish validation: 7-40 hex chars
if ! [[ "$NEW_REV" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
  echo "[error] revision must look like a git commit hash (7-40 hex chars): $NEW_REV"
  exit 1
fi

FILE="config/west.yml"
if [ ! -f "$FILE" ]; then
  echo "[error] $FILE not found"
  exit 1
fi

OLD_REV="$(awk '/name: zmk-naginata/{flag=1;next} flag && /revision:/{print $2; exit}' "$FILE")"
if [ -z "$OLD_REV" ]; then
  echo "[error] could not locate zmk-naginata revision in $FILE"
  exit 1
fi

python - <<PY
from pathlib import Path
p = Path("$FILE")
t = p.read_text()
old = "revision: $OLD_REV"
new = "revision: $NEW_REV"
if old not in t:
    raise SystemExit("target revision line not found")
p.write_text(t.replace(old, new, 1))
PY

echo "[done] zmk-naginata revision updated: $OLD_REV -> $NEW_REV"
echo "[next] verify: rg -n 'zmk-naginata|revision:' config/west.yml"
