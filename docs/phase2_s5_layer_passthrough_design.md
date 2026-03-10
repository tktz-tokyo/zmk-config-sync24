# Phase 2 設計メモ: S5（薙刀入力中のレイヤー遷移不能）

## 問題

現象: 薙刀入力中は `MO`/`LT` などのレイヤー制御キーが無視され、デフォルトレイヤー以外へ遷移できない。  
影響: NumやUtilレイヤーに入れないため、ショートカット・数字入力の運用が破綻する。

## 方針（keymap回避ではなく、naginata側で直す）

- `config/sync24.keymap` の特例回避ではなく、**zmk-naginata のイベント処理でレイヤー制御キーを常時パススルー**する。
- これにより、薙刀入力中でも `MO/LT/TO/TG` を通常のZMKレイヤー処理へ渡す。

## 実装アイデア（zmk-naginata側）

### 1) キー種別分類を導入

入力イベントを下記に分類:

- `NAGINATA_TARGET`: 薙刀合成対象キー
- `MODIFIER`: Command/Ctrl/Alt/Shift など
- `LAYER_CONTROL`: MO/LT/TO/TG など
- `OTHER`: それ以外

### 2) 判定順序を固定

1. `LAYER_CONTROL` を最優先で判定
2. 該当時は薙刀バッファ処理を通さず即パススルー
3. 次に `MODIFIER` 判定（必要に応じてバッファ commit/cancel）
4. 最後に `NAGINATA_TARGET` 合成処理

### 3) バッファ整合ルール

- `LAYER_CONTROL` 押下時に未確定バッファがある場合:
  - 方針A: 直前入力を commit してからレイヤー遷移
  - 方針B: 直前入力を cancel してレイヤー遷移
- どちらを採るかを仕様として固定し、テストを合わせる。

## 最小受け入れ条件

- 薙刀入力中に `MO(Num)` 押下でNumレイヤーへ遷移できる
- `LT` holdでも同様に遷移できる
- レイヤー解除後、薙刀入力状態が破綻しない
- 既存の HJ/FG 切替と Command 系挙動に副作用がない

## 実装手順（推奨）

1. `zmk-naginata` fork で `fix/s5-layer-passthrough` を作成
2. `LAYER_CONTROL` 判定と優先パスを追加
3. S5 の最小再現で確認
4. SYNC24 側 `config/west.yml` の `revision` を修正commitへ更新
5. left/right 実機で S1〜S5 回帰
