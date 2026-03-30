# State Contract — セーブデータ規約

> **このファイルはゲームの永続状態を管理する全ファイルの読み書きフォーマットを定義する。**
> GMはこのきやくに げんみつにしたがって ファイルをそうさすること。
> フォーマットを崩すとセッション間でデータが壊れる。

---

## 1. ファイル構成

```
game-state/
├── save.md                     # プレイヤーじょうほう・もちもの・しんこうじょうきょう
├── battle-current.md           # バトルちゅうのいちじじょうたい（バトルちゅうのみそんざい）
└── battles/                    # バトルりれき（しゅうりょうしたバトルをほぞん）
    ├── README.md
    ├── 001-victory.md
    ├── 002-victory.md
    └── 003-defeat.md ...

.claude/agents/my-monsters/             # てもちモンスター（1たい = 1ファイル、さいだい3たい）
├── README.md
├── 1-{nickname}.md
├── 2-{nickname}.md
└── 3-{nickname}.md
```

### ステートのせきむぶんり

| じょうほう | かんりさき |
|-----------|----------|
| プレイヤーめい・しょじきん・ばしょ・バッジ・アイテム・フラグ | `game-state/save.md` |
| てもちモンスターのぜんこたいデータ | `.claude/agents/my-monsters/{N}-{nickname}.md` |
| バトルちゅうのいちじじょうたい | `game-state/battle-current.md` |
| バトルりれき（しゅうりょうずみ） | `game-state/battles/{つうばん}-{けっか}.md` |

---

## 2. save.md のスキーマ

```markdown
# Save Data

## Player
- Name: [プレイヤー名]
- Gold: [所持金]
- Location: [現在地]
- Badges: [バッジ名をカンマ区切り、なければ "なし"]
- Total Battles: [累計バトル数]

## Items
- [アイテム名]: [個数]
- [アイテム名]: [個数]

## Story Flags
- [フラグ名]: [true/false]
```

> **注意: save.md にモンスター情報は含まない。** 手持ちモンスターは `.claude/agents/my-monsters/` の個別ファイルを参照すること。

### フィールド詳細

| フィールド | 型 | 制約 |
|-----------|------|------|
| Name | 文字列 | プレイヤーが自由に設定 |
| Gold | 整数 | 0以上 |
| Location | 文字列 | game-master.md のワールドマップに存在する場所名 |
| Badges | カンマ区切り文字列 | みなとバッジ, いわやまバッジ, らいうんバッジ のいずれか |
| Total Battles | 整数 | 0以上、バトル終了ごとに +1 |

### Story Flags

| フラグ名 | 意味 |
|---------|------|
| starter_chosen | 御三家を選択済み |
| gym1_cleared | 第1ジムクリア済み |
| gym2_cleared | 第2ジムクリア済み |
| gym3_cleared | 第3ジムクリア済み（= ゲームクリア） |

---

## 3. モンスター個体ファイルのスキーマ

**場所:** `.claude/agents/my-monsters/{スロット番号}-{ニックネーム}.md`

### 命名規則

- `{スロット番号}`: `1`, `2`, `3`（1 = 先頭 = バトルに出る）
- `{ニックネーム}`: ローマ字小文字。ニックネーム未設定時は種族名のローマ字
- 例: `1-hinoko.md`, `2-goratsuki.md`, `3-fire-boy.md`

### ファイルフォーマット

```markdown
# {表示名（ニックネーム or 種族名）}

## Identity
- Species: {種族名（.claude/agents/monsters-guide/ の名前）}
- Type: {Fire / Water / Grass / Elec / Normal}
- Caught At: {捕獲/選択した場所}

## Stats
- Level: {N}
- XP: {現在値} / {次レベルまで}
- HP: {現在} / {最大}
- ATK: +{N}
- DEF: +{N}
- SPD: +{N}

## Moves
1. {技名} (PP: {現在}/{最大})
2. {技名} (PP: {現在}/{最大})
3. {技名} (PP: {現在}/{最大})
4. {技名} (PP: {現在}/{最大})

## Condition
- Status: {正常 / やけど / マヒ / うずまき / etc.}
- Notes: {自由メモ欄}
```

### フィールド詳細

| フィールド | 型 | 制約 |
|-----------|------|------|
| Species | 文字列 | .claude/agents/monsters-guide/ に存在する種族名のみ |
| Type | 文字列 | Fire / Water / Grass / Elec / Normal |
| Caught At | 文字列 | 捕獲した場所（御三家は「はじまりの町」） |
| Level | 整数 | 1〜15 |
| XP | "現在値 / 必要値" | 必要値 = 次レベル × 4 |
| HP | "現在 / 最大" | 現在 ≤ 最大、最大 = 基本HP + (Lv-1) + 進化ボーナス |
| ATK/DEF/SPD | "+N" 形式 | .claude/agents/monsters-guide/ の値。進化後は進化形の値 |
| Status | 文字列 | バトル外では常に「正常」 |
| Moves | 番号付きリスト | 最大4つ。skills/move-list/SKILL.md に存在する技名のみ |
| Notes | 文字列 | 任意。空欄可 |

### パーティ順序の取得

```bash
ls .claude/agents/my-monsters/[0-9]*.md | sort
```

ソート結果の先頭が Slot 1（バトルに出るモンスター）。

### パーティ操作

| 操作 | ファイル処理 |
|------|------------|
| 御三家選択 | `1-{nickname}.md` を新規作成 |
| 捕獲 | `{次の空き番号}-{nickname}.md` を新規作成 |
| 並び替え | プレフィックス番号をリネームで入れ替え |
| レベルアップ | ファイル内 Stats / Moves を更新 |
| 進化 | ファイル内 Identity / Stats / Moves を更新。**ファイル名は変えない** |
| 回復 | ファイル内 HP → MaxHP, PP → 最大, Status → 正常 |
| 技忘れ/習得 | ファイル内 Moves を更新 |

---

## 4. battle-current.md のスキーマ

```markdown
# Battle State

## Battle Info
- Type: [wild / trainer / gym]
- Opponent: [トレーナー名。野生の場合は "wild"]
- Turn: [現在ターン数]

## Player Active
- File: [.claude/agents/my-monsters/{ファイル名}]
- Name: [モンスター名]
- HP: [現在HP] / [MaxHP]
- ATK: [現在ATK（状態異常修正込み）]
- DEF: [現在DEF]
- SPD: [現在SPD（状態異常修正込み）]
- Status Effects: [なし / やけど / マヒ / うずまき / パラサイト / チャージアップ]
- Moves Used: [技名]:[残PP], [技名]:[残PP], ...
- Last Move: [前ターンに使った技名。シールド連続使用チェック用]

## Opponent Active
- Name: [モンスター名]
- Level: [レベル]
- HP: [現在HP] / [MaxHP]
- ATK: [現在ATK（状態異常修正込み）]
- DEF: [現在DEF]
- SPD: [現在SPD（状態異常修正込み）]
- Status Effects: [なし / やけど / マヒ / うずまき / パラサイト / チャージアップ]
- Moves: [技1]:[残PP], [技2]:[残PP], ...
- Last Move: [前ターンの技名]

## Opponent Remaining
- [モンスター名] Lv[N] HP:[現在HP]/[MaxHP]
- [次のモンスター...]

## Battle Log
- Turn [N]: [プレイヤー行動] / [相手行動] / [結果サマリ]
```

> battle-current.md の Player Active には `File:` フィールドがある。これにより、バトル終了時にどのモンスターファイルを更新すべきかが明確になる。

---

## 5. 読み書きルール

### 読み込み

1. **プレイヤー情報:** `save.md` を読む
2. **手持ちモンスター:** `.claude/agents/my-monsters/` の全 .md ファイル（README.md を除く）を読む
3. **バトル中:** 上記に加えて `battle-current.md` を読む

### 書き込みタイミング

| イベント | save.md | monster files | battle-current.md |
|---------|---------|---------------|-----------|
| ターン終了 | — | — | HP, PP, じょうたい, ログこうしん |
| モンスターせんとうふのう | — | — | こうぞくモンスターじょうほうこうしん |
| バトルしゅうりょう（しょうり） | Gold, Battles +1 | XP, Lv, HP, わざ（さんかしたぜんたいに） | → `battles/{つうばん}-victory.md` にほぞん |
| バトルしゅうりょう（はいぼく） | Goldげんしょう, Location | HPはんぶんかいふく（ぜんたい） | → `battles/{つうばん}-defeat.md` にほぞん |
| バトルしゅうりょう（とうそう） | — | — | → `battles/{つうばん}-escape.md` にほぞん |
| ほかくせいこう | ボールしょうひ | しんファイルさくせい | → `battles/{つうばん}-captured.md` にほぞん |
| かいふく（まち） | — | ぜんファイル: HP/PPぜんかいふく, Statusせいじょう | — |
| アイテムこうにゅう | Goldげんしょう, Itemsこうしん | — | — |
| レベルアップ | — | Level, XP, MaxHP, わざ | — |
| しんか | — | Species, HP, ATK/DEF/SPD, わざ | — |
| いどう | Location | — | — |
| バッジかくとく | Badges, Flags | — | — |
| ならびかえ | — | ファイルリネーム | — |

### バトルりれきのめいめいきそく

```
game-state/battles/{3けたつうばん}-{けっか}.md
```

- **つうばん:** 001 からじゅんばんにふる。`ls game-state/battles/[0-9]*.md | wc -l` + 1 でつぎのばんごうをけってい
- **けっか:** `victory` / `defeat` / `escape` / `captured`
- れい: `001-victory.md`, `002-captured.md`, `003-defeat.md`

### バトルしゅうりょうじのしょり

1. battle-current.md のさいしゅうじょうたいをかくてい（Battle Log かんりょう）
2. battle-current.md を `game-state/battles/{つうばん}-{けっか}.md` に **リネーム**（コピーではなくいどう）
3. モンスターファイル・save.md をこうしん

### 書き込み手順

1. **対象ファイルを読む**（最新状態を取得）
2. **メモリ上で更新を計算する**
3. **ファイル全体を書き直す**（部分更新ではなく全置換）
4. **書き込み後に読み直して検証する**

> ⚠️ **差分更新は禁止。** 必ずファイル全体を再生成すること。

---

## 6. PP の管理

- PP はバトル単位でカウントする
- バトル開始時、全技のPPは最大値にリセットされる
- 町での回復時も全技のPPは最大値にリセットされる
- PP が 0 の技は使用できない（プレイヤーに選択肢として提示しない）
- 全技の PP が 0 になった場合、「わるあがき」（Normal, 1d4, Hit+0, 反動: 与ダメの半分）を使用

---

## 7. 初期状態テンプレート

### save.md（new-game 時に生成）

```markdown
# Save Data

## Player
- Name: [入力された名前]
- Gold: 300
- Location: はじまりの町
- Badges: なし
- Total Battles: 0

## Items
- いやしグラス: 3
- トラップボール: 5

## Story Flags
- starter_chosen: true
- gym1_cleared: false
- gym2_cleared: false
- gym3_cleared: false
```

### モンスターファイル（new-game 時に御三家を生成）

例: ヒノコを選択、ニックネーム「アカマル」の場合 → `.claude/agents/my-monsters/1-akamaru.md`

```markdown
# アカマル

## Identity
- Species: ヒノコ
- Type: Fire
- Caught At: はじまりの町

## Stats
- Level: 1
- XP: 0 / 8
- HP: 18 / 18
- ATK: +2
- DEF: +1
- SPD: +2

## Moves
1. フレアバイト (PP: 15/15)
2. タックル (PP: 15/15)

## Condition
- Status: 正常
- Notes:
```

### 捕獲時のファイル生成例

ゴロツキ Lv3 を捕獲、ニックネームなし → `.claude/agents/my-monsters/2-goratsuki.md`

```markdown
# ゴロツキ

## Identity
- Species: ゴロツキ
- Type: Normal
- Caught At: ルート1

## Stats
- Level: 3
- XP: 0 / 16
- HP: 22 / 30
- ATK: +1
- DEF: +2
- SPD: +1

## Moves
1. タックル (PP: 15/15)
2. シールド (PP: 3/3)

## Condition
- Status: 正常
- Notes:
```

> 捕獲時の HP はバトル中の残りHP のまま記録する。PP は全回復。
