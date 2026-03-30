# game-state/battles/ — バトルりれき

> しゅうりょうしたバトルのログがほぞんされるディレクトリ。
> バトルしゅうりょうじに `battle-current.md` がここにリネームされる。

## めいめいきそく

```
{3けたつうばん}-{けっか}.md
```

| けっか | いみ |
|--------|------|
| victory | しょうり |
| defeat | はいぼく |
| escape | とうそう |
| captured | ほかくせいこう |

れい: `001-victory.md`, `002-captured.md`, `003-defeat.md`

## つかいかた

- バトルのふりかえりにつかえる
- `/reset-game` でぜんけんさくじょされる
- git ではかんりしない（.gitignore にふくむ）
