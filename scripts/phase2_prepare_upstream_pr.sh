#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

OUT="docs/phase2_upstream_pr_draft.md"
DATE_STR="$(date +%F)"

cat > "$OUT" <<'MD'
# zmk-naginata S2/S5 Fix Draft (__DATE__)

## Summary

This draft is prepared from SYNC24 Phase1/Phase2 records to open/update upstream PR for Method A.

- Scope:
  - S2: Command shortcut interaction (`Cmd+C` path)
  - S5: Layer control passthrough (`MO/LT` during Naginata input)
- Strategy:
  - Method A: prioritize `LAYER_CONTROL` passthrough before Naginata composition.

## Reproduction Findings (from SYNC24)

- S1: PASS (macOS/iOS)
- S2: FAIL (`Cmd+C` intent can be absorbed by Naginata path)
- S3: Conditional PASS (when final toggle state is alnum)
- S4: PASS (no left/right Command difference)
- S5: FAIL (`MO/LT` ignored; cannot move to Num layer)

## Proposed Implementation Rules

1. Classify events as:
   - `LAYER_CONTROL`
   - `MODIFIER`
   - `NAGINATA_TARGET`
   - `OTHER`
2. Process order:
   1) `LAYER_CONTROL` passthrough (highest priority)
   2) `MODIFIER` handling with explicit buffer policy
   3) `NAGINATA_TARGET` composition
3. Document chosen buffer policy on layer-key press:
   - commit-before-layer or cancel-before-layer

## Acceptance Criteria

- [ ] `MO(Num)` works during Naginata input
- [ ] `LT` hold also transitions to layer
- [ ] `Cmd+C` no longer maps into unintended hide behavior
- [ ] `Cmd+Tab` remains usable
- [ ] HJ/FG toggle behavior unchanged

## Validation Plan

- Run S1-S5 regression scenarios on macOS/iOS.
- Update SYNC24 `config/west.yml` pin to tested commit after upstream fix validation.
MD

python - <<PY
from pathlib import Path
p=Path("$OUT")
t=p.read_text().replace("__DATE__","$DATE_STR")
p.write_text(t)
PY

echo "[done] wrote $OUT"
