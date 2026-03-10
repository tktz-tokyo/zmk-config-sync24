# Phase2 ソース解析ステータス（zmk-naginata）

ユーザー要望: `zmk-naginata/src` を読んで、同時押し判定とキー処理フローを整理する。

## 現在の実行結果

- `modules/lib/zmk-naginata` がこの環境に存在せず、直接解析は未実施。
- そのため、まず `west update` でモジュールを実体化する必要がある。

## 進めた内容

- `scripts/phase2_extract_naginata_flow.sh` を追加。
  - モジュール存在時に `src/include` を走査し、
    - イベント処理
    - 同時押し判定
    - レイヤー制御
    の候補シンボルを抽出して `docs/phase2_naginata_source_flow.md` を生成する。

## 次アクション

1. `west` が使える環境で `west update` 実行
2. `./scripts/phase2_extract_naginata_flow.sh` 実行
3. 生成された `docs/phase2_naginata_source_flow.md` の手動追記セクションを埋める
