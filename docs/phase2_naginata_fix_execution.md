# Phase 2 実行チェックリスト: zmk-naginata 修正（S2 / S5）

このファイルは、Phase 1 の実測結果を受けて、実装フェーズを止まらず進めるための実行用チェックリストです。

対象不具合:
- S2: `Cmd+C` 意図時に薙刀側へ吸収され、実質 `Cmd+H` が先行する
- S5: 薙刀入力中は `MO` / `LT` が無視され、Numレイヤーへ遷移しない

## 0. 前提

- fork: `tktz-tokyo/zmk-naginata`
- ベースcommit: `71c0070`
- SYNC24側は `config/west.yml` で commit pin 運用

## 1. 実装方針（最小差分）

### A. Modifier優先（S2）
- Command/Ctrl/Alt/GUI 押下中は薙刀合成判定に入れない
- 未確定バッファがあれば、modifier押下時に commit か cancel を明示実行
- key-down / key-up の順序逆転でも状態破綻しないようにする

### B. Layer key 常時パススルー（S5）
- `MO` / `LT` / `TO` / `TG` などのレイヤー制御は薙刀バッファへ入れない
- レイヤー遷移イベントを常に先に通す
- レイヤー解除時に薙刀状態が汚染されないことを保証

## 2. 実装チェック項目

- [ ] modifier押下中は薙刀合成を無効化できる
- [ ] `Cmd+C` が `Cmd+H` 化しない
- [ ] `Cmd+Tab` が従来通り動作
- [ ] 薙刀入力中でも `MO(Num)` で数字レイヤーに入れる
- [ ] `LT` hold でも同様にレイヤー遷移できる
- [ ] HJ/FG切替は既存どおり維持

## 3. 検証コマンド（SYNC24側）

```bash
rg -n "naginata-fork|zmk-naginata|revision:" config/west.yml
```

修正commit作成後:

```bash
# revision を修正commitへ更新
# 例: revision: <new-commit>
```

## 4. 受け入れ条件（DoD）

- S1: PASS
- S2: PASS（`Cmd+C` が意図どおり）
- S3: PASS（英数状態でCommand系問題なし）
- S4: PASS（左右差なし）
- S5: PASS（MO/LTでNum遷移可能）

## 5. 実装順序の原則

- S5は **zmk-naginata本体でのレイヤーキー常時パススルー実装** を先に行う。
- `sync24.keymap` 側での回避策先行は行わない。
- 詳細設計は `docs/phase2_s5_layer_passthrough_design.md` を参照。

## 6. Method A 実装手順（詳細）

- 実装詳細は `docs/phase2_methodA_implementation_steps.md` を参照。
- 本体修正（fork）→ `west.yml` pin 更新 → S1〜S5 回帰 の順で進める。

## 7. 上流PRドラフト作成

- `scripts/phase2_prepare_upstream_pr.sh` を実行して、`docs/phase2_upstream_pr_draft.md` を生成する。
- 生成物をベースに fork/upstream PR 本文を作成する。
