# zmk-naginata ソース解析フロー（同時押し判定とキー判定）

このドキュメントは、`zmk-naginata` の `src/include` を読んで
**「どのイベント入口で、どの順番で、何を判定しているか」**を
追跡するための作業フローをまとめたものです。

> 現在のこの環境では `modules/lib/zmk-naginata` が未展開のため、
> 実コードに対する関数名レベルの確定版フローは未記入です。
> まず `west update` が必要です。

## 1. 解析の目的

- S2: Command 修飾時に薙刀ターゲットキーが先に処理される問題の原因特定
- S5: 薙刀中に `MO/LT` 等のレイヤー制御が無視される問題の原因特定
- Method A（Layer key パススルー）を実装する位置を確定

## 2. 解析対象（埋める場所）

`west update` 後、以下を埋める。

- `modules/lib/zmk-naginata/src/...`
- `modules/lib/zmk-naginata/include/...`

## 3. 解析手順（実行コマンド）

### 3-1. 自動抽出

```bash
./scripts/phase2_extract_naginata_flow.sh
```

このスクリプトで以下を抽出する。

- `src/include` のファイル一覧
- イベント処理・キー判定候補シンボル
- 同時押し（combo/chord/simul）関連候補
- レイヤー制御（MO/LT/TO/TG）関連候補

### 3-2. 手動読解（関数トレース）

次の観点で「呼び出し順」を追う。

1. キー押下/離上イベントの入口関数
2. 薙刀対象キーかどうかの判定関数
3. 同時押し判定の時間窓・バッファ更新の関数
4. modifier（Cmd/Shift/Ctrl/Alt）判定と分岐
5. layer control（MO/LT/TO/TG）判定と分岐
6. 最終的に ZMK 標準へ流す条件

## 4. フローテンプレート（確定版をここに追記）

```text
[physical key event]
  -> [zmk-naginata event entry]
      -> [classify: layer_control ?]
          -> yes: [buffer policy: commit/cancel] -> [pass to ZMK]
          -> no
      -> [classify: modifier ?]
          -> yes: [modifier handling + buffer policy] -> [pass to ZMK]
          -> no
      -> [classify: naginata target ?]
          -> yes: [naginata buffer/chord resolution] -> [emit kana sequence]
          -> no: [pass to ZMK]
```

## 5. 期待する実装修正ポイント（Method A）

- 最上流に `LAYER_CONTROL` 判定を置く
- `MO/LT/TO/TG` は薙刀バッファに入れず即パススルー
- 次に `MODIFIER` 判定
- 最後に薙刀対象キー処理

## 6. 検証観点（S2/S5）

- S2: `Cmd+C` 入力時に `Cmd+H` などへ化けない
- S2: `Cmd+Tab` は従来通り動作
- S5: 薙刀中でも `MO(Num)` / `LT(Num, *)` で数レイヤーに遷移
- HJ/FG の英数・かな切替が維持される
- 左右 Command で差分が出ない

## 7. 現状ステータス

- この環境では `west` と外部取得が制約され、`zmk-naginata` の実コード読解は未完。
- ただし、抽出スクリプトと本ドキュメントを追加済みのため、
  モジュール展開後は同じ手順で即座に関数フローを確定可能。
