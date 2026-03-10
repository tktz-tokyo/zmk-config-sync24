# Phase2 Method A 実装手順（zmk-naginata 本体）

この手順は、S5（薙刀入力中に MO/LT でレイヤー遷移できない）を
**Layer key 常時パススルー**で解消するための実装ステップです。

## 1. 対象ブランチ

- リポジトリ: `tktz-tokyo/zmk-naginata`
- ブランチ: `fix/s5-layer-passthrough`

## 2. 変更ポイント探索

fork 側で次の文字列を検索し、薙刀入力のイベント処理関数を特定する。

```bash
rg -n "process|event|keycode|modifier|layer|naginata|combo|state" src app include
```

レイヤー制御判定に使える情報（behavior 名や keycode 種別）を探す。

```bash
rg -n "MO|LT|TO|TG|LAYER|momentary|layer-tap" src app include
```

## 3. 実装ルール（Method A）

1. `LAYER_CONTROL` 判定を最優先に置く
2. `MO/LT/TO/TG` は薙刀バッファへ入れず、そのまま ZMK 標準処理へ流す
3. その後に `MODIFIER` 判定、最後に `NAGINATA_TARGET` 判定

### 擬似コード

```c
if (is_layer_control(event)) {
    flush_or_keep_buffer_by_policy();   // 仕様を固定（commit/cancel）
    return PASS_TO_ZMK;
}

if (is_modifier(event)) {
    handle_modifier_with_buffer_policy();
    return PASS_TO_ZMK;
}

return process_naginata_target(event);
```

## 4. バッファポリシー

`MO/LT` 押下時の未確定バッファはどちらかに固定する。

- 方針A: commit 後に layer 遷移
- 方針B: cancel 後に layer 遷移

※ どちらを採用したかを PR本文に明記する。

## 5. 検証項目

- [ ] 薙刀中でも `MO(Num)` で Num レイヤーへ遷移できる
- [ ] `LT` hold でも遷移できる
- [ ] レイヤー離脱後に薙刀状態が破綻しない
- [ ] `Cmd+Tab` が従来通り使える
- [ ] HJ/FG トグルに副作用がない

## 6. SYNC24 反映

修正commit作成後、`config/west.yml` の `zmk-naginata` `revision` を更新する。

## 7. 実行補助スクリプト

- SYNC24側の前提確認とビルド確認は `scripts/phase2_methodA_runbook.sh` を使用。
- `west` 未導入環境では、必要コマンドを案内して終了する。
