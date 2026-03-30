# game-state/battles/ — バトル履歴

> 終了したバトルのログが保存されるディレクトリ。
> バトル終了時に `battle-current.md` がここにリネームされる。

## 命名規則

```
{3桁通番}-{結果}.md
```

| 結果 | 意味 |
|--------|------|
| victory | 勝利 |
| defeat | 敗北 |
| escape | 逃走 |
| captured | 捕獲成功 |

例: `001-victory.md`, `002-captured.md`, `003-defeat.md`

## 使い方

- バトルの振り返りに使える
- `/reset-game` で全件削除される
- git では管理しない（.gitignore に含む）
