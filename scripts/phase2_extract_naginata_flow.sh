#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

MOD_DIR="modules/lib/zmk-naginata"
OUT="docs/phase2_naginata_source_flow.md"

if [ ! -d "$MOD_DIR" ]; then
  echo "[error] $MOD_DIR not found. Run 'west update' in a network-enabled environment first." >&2
  exit 2
fi

SRC_FILES=$(rg --files "$MOD_DIR" | rg '/src/|/include/' || true)

{
  echo "# zmk-naginata ソース解析: キー判定と同時押し処理フロー"
  echo
  echo "生成日時: $(date -Iseconds)"
  echo
  echo "## 1. 解析対象ファイル"
  echo
  if [ -n "$SRC_FILES" ]; then
    echo "$SRC_FILES" | sed 's/^/- `/' | sed 's/$/`/'
  else
    echo "- （src/include配下のファイルを検出できませんでした）"
  fi

  echo
  echo "## 2. 主要シンボル抽出"
  echo
  echo "### 2-1. イベント/キー処理に関する候補"
  rg -n "process|event|key|press|release|combo|state|layer|modifier" "$MOD_DIR"/src "$MOD_DIR"/include 2>/dev/null || true

  echo
  echo "### 2-2. 同時押し（combo/chord）に関する候補"
  rg -n "combo|chord|simult|simul|timeout|hold|tap" "$MOD_DIR"/src "$MOD_DIR"/include 2>/dev/null || true

  echo
  echo "### 2-3. レイヤー制御（MO/LT/TO/TG等）に関する候補"
  rg -n "MO|LT|TO|TG|layer|momentary|layer-tap" "$MOD_DIR"/src "$MOD_DIR"/include 2>/dev/null || true

  echo
  echo "## 3. フロー整理（手動追記セクション）"
  echo
  cat <<'MANUAL'
以下を実コード読解で埋める:

1. 物理キー押下イベントの入口関数
2. Naginata対象キーの判定関数
3. 同時押し（コンボ/コード）判定ロジックとタイミング
4. modifierキー受理とバッファ確定/キャンセル条件
5. layer制御キーの処理順（S5修正前後の差分）
6. 例: Cmd+C, MO(Num) での実際の分岐フロー
MANUAL
} > "$OUT"

echo "[done] wrote $OUT"
