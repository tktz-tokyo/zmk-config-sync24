# zmk-naginata不具合修正とSYNC24統合の進め方

このドキュメントは、以下2点を同時に進めるための実行計画です。

1. zmk-naginata の「Commandキー絡みで日本語入力が崩れる」不具合を改善する
2. 改善済み zmk-naginata をこの `zmk-config-sync24` に安全に統合する

## 前提（このリポジトリの現在構成）

- ZMK本体は `config/west.yml` で `v0.3` を参照している
- ビルド対象は `build.yaml` で left/right/settings_reset
- 実運用キーマップは `config/sync24.keymap` にある
- 対象OSは **macOS / iOS**（優先検証対象）
- かな/英数切り替えは **HJ同時押し=かな（LANG1） / FG同時押し=英数（LANG2）** を既存実装として維持する

## 全体方針


## ブランチ戦略（重要）

- **`feat/n-phase4` を統合作業の起点ブランチにする**（現時点で最も開発が進んでいるため）。
- 本リポジトリ側では新規作業ブランチを `feat/n-phase4` から切り、以下の順で積み上げる。
  1. `chore/naginata-west-pin`（依存追加・pin）
  2. `feat/naginata-keymap-min`（最小キーマップ統合）
  3. `feat/naginata-keymap-tune`（最適化・運用調整）
- `main` 直積みは避け、`feat/n-phase4` に順次マージして検証を進める。

### zmk-naginata 側との整合ルール

- 上流にPRがある場合は、**merge commit ではなく修正を含む commit hash を pin** する。
- 上流未マージ期間は fork を利用し、`west.yml` では branch 参照ではなく commit 固定にする。
- pin 更新時は「何を解決したcommitか」をコミットメッセージに明記する。






### フォーク元の決定: `eswai/zmk-naginata`

`zmk-naginata` は **eswai リポジトリを起点に fork** して進める。
理由は、現行最新版追従ではなく、実運用で安定していた系列（v16相当）を基準に修正するため。

運用ルール:

- SYNC24 には fork の **branch ではなく commit hash** を pin する
- まず「v16相当の基準commit」を固定し、その上に Command 不具合修正commit を積む
- pin 更新時は `west.yml` 更新コミットに「基準commit / 修正commit / 目的」を明記する

#### 初回セットアップ手順（実務）

1. GitHub で `eswai/zmk-naginata` を自身アカウントへ fork
2. fork 側で `fix/cmd-ime-v16-base` ブランチを作成
3. v16相当の基準commitをタグまたはメモで固定
4. Command不具合修正を実装して commit
5. SYNC24 側 `config/west.yml` に fork remote/project を追加し commit hash pin
6. left/right ビルドと macOS/iOS 回帰を実施



#### 取り込み確認ステータス（SYNC24 側）

現在は `config/west.yml` に `naginata-fork` と `zmk-naginata` を登録済み。  
`zmk-naginata` は **commit `71c0070` 固定** で取り込んでいる。

- remote: `naginata-fork` (`https://github.com/tktz-tokyo`)
- project: `zmk-naginata` (`path: modules/lib/zmk-naginata`)
- revision(pin): `71c0070`

確認コマンド（反映後）:

```bash
rg -n "naginata-fork|zmk-naginata|revision:" config/west.yml
```

#### `west.yml` 反映例（テンプレ）

```yaml
manifest:
  remotes:
    - name: zmkfirmware
      url-base: https://github.com/zmkfirmware
    - name: naginata-fork
      url-base: https://github.com/<your-account>
  projects:
    - name: zmk
      remote: zmkfirmware
      revision: v0.3
      import: app/west.yml
    - name: zmk-naginata
      remote: naginata-fork
      revision: <commit-hash>
      path: modules/lib/zmk-naginata
```

> 注意: `<your-account>` と `<commit-hash>` は固定値を使う。branch 名は使わない。

### ZMK `main` 移行時の対策（必須）

過去に `revision: main` で SYNC24 がビルド不能になったため、当面は `v0.3` を維持します。
`main` へ上げる場合は、次を満たしたときのみ別ブランチで実施します。

1. `chore/zmk-main-migration` ブランチを作成して隔離
2. left/right 両方で `west build` が通ることを確認
3. `config/sync24.keymap` の互換性崩れ（behavior / binding）を解消
4. 既存運用（FG=LANG2, HJ=LANG1）が維持されることを実機確認
5. 問題発生時は `revision: v0.3` に即時ロールバックできる状態を保持

### 方針A: まず上流（zmk-naginata）を直し、その後にSYNC24へ取り込む

今回のような入力法ロジックの不具合は、キーマップの回避策だけでなく、
実装側のイベント処理修正が必要になる可能性が高いです。
そのため、**先に zmk-naginata 側で再現・修正・検証**を行い、
その修正を pin した形で本リポジトリに取り込むのが最も安全です。

---

## フェーズ1: 不具合の再現条件を固定する（最重要）

### 1-1. 再現シナリオを具体化する

最低でも次を明文化してください（Issueテンプレ化推奨）:

- OS（**macOS / iOS** を必須、必要なら他OSは参考）
- 入力方式（かな/英数の切り替え方法、IME種類）
- 切り替え操作（**HJ=かな / FG=英数**）を含めた再現シーケンス
- どの修飾キーで壊れるか（Command単体 / Command+他キー / 左右差）
- MO(Num) や layer-tap hold 中のレイヤー遷移可否
- 期待挙動と実際挙動
- 再現手順（10回中何回再現するか）

### 1-2. ログ採取方法を決める

- ZMK Studio / USBログを使って、
  「物理キーイベント」→「naginata状態遷移」→「最終送出キーコード」の順で追えるようにする
- 入力崩れが起きる直前のイベント列を保存する

成果物:

- 再現手順書（Failing scenario）
  - 本リポジトリでは `docs/phase1_naginata_repro_and_logging.md` を起票済み
- 最小再現キーマップ（必要なら）

---

## フェーズ2: zmk-naginata側で修正する

### 2-1. 原因仮説（典型パターン）

Commandキー絡みの不具合は、次のどれかが多いです。

- 修飾キー押下で、naginataの未確定バッファを適切にflush/cancelできていない
- modifier状態遷移のタイミングで、合成判定が誤って継続してしまう
- 左右modifierの差異を吸収できていない
- key-up順序依存のバグ（押下順と離上順が逆転したときに破綻）
- MO/layerキーがnaginata入力バッファに吸収され、レイヤー遷移イベントが落ちる

### 2-2. 修正の設計指針

- **状態機械を明示化**する
  - 未確定入力中に `MOD_CMD` 系イベントが来たらどうするか（commit / cancel / passthrough）を仕様化
- **境界条件を固定**する
  - chord確定前にmodifierが混ざった場合の処理
  - modifier押下中の同時打鍵扱い
  - MO / LT / TO などレイヤー制御キーは常にパススルーする仕様を定義
- **後方互換**を意識する
  - Command以外（Ctrl/Alt/Shift）への副作用を回帰確認

### 2-3. テスト設計

少なくとも以下を自動または半自動で検証:

- 通常の薙刀入力が壊れない
- **FG/HJ同時押しによる英数/かな切り替えが従来通り動作する**
- Commandショートカット中は意図通りnaginata判定が停止/確定される
- Command解除後に状態が正常復帰する
- 左右Commandで挙動差がない
- 薙刀入力中でも MO(Num) / LT hold でNumレイヤーへ遷移できる

成果物:

- zmk-naginata側PR（再現ケース + 修正 + 回帰テスト）

---

## フェーズ3: SYNC24へ統合する

### 3-1. 依存の取り込み方式

`config/west.yml` に zmk-naginata プロジェクトを追加し、
**修正を含む commit/tag に pin** します（floating branch運用は避ける）。

実務上は次の順で進める:

1. `feat/n-phase4` を最新化
2. そこから `chore/naginata-west-pin` を作成
3. `west.yml` に `zmk-naginata` を追加し、対象 commit を固定
4. left/right のビルドが通ることを確認して `feat/n-phase4` へ戻す

### 3-2. キーマップ統合

`config/sync24.keymap` 側で以下を段階的に行う:

1. include と behavior定義を追加
2. 既存コンボ（LANG1/LANG2切替）との責務を整理
3. base/num/function/util 各レイヤーで干渉確認

現状の `FG/HJ` コンボ（`FG=LANG2`, `HJ=LANG1`）は既存運用として維持し、
薙刀状態制御との二重管理を避ける責務分離を行う。

### 3-3. ビルド/実機確認

- left/right のビルド通過
- BT接続時・USB接続時それぞれで再現テスト
- **macOS**: Commandショートカット（コピー/貼り付け/アプリ切替）中のかな英数遷移確認
- **iOS**: ハードウェアキーボード接続時のかな英数遷移とCommand系ショートカット確認
- 既存ショートカット（Command系）と日本語入力の往復テスト
- Numレイヤー遷移（MO/LT hold）が成立することを確認

---

## リスクと回避策

- リスク: 上流未マージの差分を長期運用して追従コストが増える
  - 回避: まず上流PR提出、暫定的には fork commit pin
- リスク: レイヤー構成の複雑化で保守性低下
  - 回避: 「日本語入力制御レイヤー」と「一般ショートカット」を分離
- リスク: OS/IME差分で再発
  - 回避: macOSを基準にしつつ、主要OSで最低限の回帰項目を固定

---

## 推奨する進行順（実務）

1. 不具合再現手順を1ページに固定
2. zmk-naginata側で最小修正PRを作る
3. 修正commitを `west.yml` に pin してSYNC24へ導入
4. `sync24.keymap` に段階統合（まずは最小）
5. 実機で回帰試験し、問題なければ追加最適化

この順序なら、「原因がzmk-naginata本体か、SYNC24統合層か」を切り分けやすく、
戻しも容易です。


## フェーズ1結果サマリ（最新）

- S1: PASS（macOS / iOS）
- S2: FAIL（`Command + C` 意図時に薙刀変換影響で `Command + H` が先行し、アプリが非表示）
- S3: 条件付きPASS（トグル最終状態が英数ならCommand使用可）
- S4: PASS（左右差なし）
- S5: FAIL（`MO` / `LT` が無視され、Numレイヤーに遷移しない）

このため、フェーズ2では **S2 と S5 を修正の主対象** とする。

