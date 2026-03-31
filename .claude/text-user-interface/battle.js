#!/usr/bin/env node
// Claude Code Monster - Pokemon-style TUI Status Line

const fs = require("fs");
const path = require("path");

const PROJ = path.resolve(__dirname, "..");
const SAVE = path.join(PROJ, "game-state/save.md");
const BATTLE = path.join(PROJ, "game-state/battle-current.md");
const MONSTERS_DIR = path.join(PROJ, ".claude/agents/my-monsters");

// ── Colors ──
const c = {
  R: "\x1b[31m",
  G: "\x1b[32m",
  Y: "\x1b[33m",
  B: "\x1b[34m",
  M: "\x1b[35m",
  C: "\x1b[36m",
  W: "\x1b[37m",
  BR: "\x1b[91m",
  BG: "\x1b[92m",
  BY: "\x1b[93m",
  BB: "\x1b[94m",
  BM: "\x1b[95m",
  BC: "\x1b[96m",
  BW: "\x1b[97m",
  BOLD: "\x1b[1m",
  DIM: "\x1b[2m",
  RESET: "\x1b[0m",
};

// ── Helpers ──
function readFile(p) {
  try {
    return fs.readFileSync(p, "utf-8");
  } catch {
    return null;
  }
}

function parseField(text, key) {
  const m = text.match(new RegExp(`^- ${key}:\\s*(.+)`, "m"));
  return m ? m[1].trim() : "";
}

function parseSection(text, heading) {
  const re = new RegExp(`## ${heading}\\n([\\s\\S]*?)(?=\\n## |$)`);
  const m = text.match(re);
  return m ? m[1] : "";
}

function hpBar(cur, max, width) {
  const pct = max > 0 ? Math.floor((cur * 100) / max) : 0;
  const color = pct >= 50 ? c.BG : pct >= 25 ? c.BY : c.BR;
  let filled = Math.floor((pct * width) / 100);
  if (filled < 1 && cur > 0) filled = 1;
  const empty = width - filled;
  return color + "━".repeat(filled) + c.DIM + c.W + "─".repeat(empty) + c.RESET;
}

function xpBar(cur, max, width) {
  const pct = max > 0 ? Math.floor((cur * 100) / max) : 0;
  const filled = Math.floor((pct * width) / 100);
  const empty = width - filled;
  return c.BC + "━".repeat(filled) + c.DIM + c.W + "─".repeat(empty) + c.RESET;
}

function typeIcon(type) {
  return { Fire: "🔥", Water: "💧", Grass: "🌿", Elec: "⚡" }[type] || "◻️";
}

function statusIcons(status) {
  if (!status) return "";
  let out = "";
  if (status.includes("やけど")) out += ` 🔥${c.R}やけど${c.RESET}`;
  if (status.includes("マヒ")) out += ` ⚡${c.BY}まひ${c.RESET}`;
  if (status.includes("うずまき")) out += ` 🌀${c.BC}うずまき${c.RESET}`;
  if (status.includes("パラサイト")) out += ` 🌿${c.BG}パラサイト${c.RESET}`;
  if (status.includes("チャージ")) out += ` ⚡${c.BY}チャージ${c.RESET}`;
  return out;
}

function aaSprite(species, indent) {
  const lines = {
    ヒノコ: [
      `${c.BR}╭─╮${c.RESET}`,
      `${c.BR}(${c.BY}◕${c.BR}ᴗ${c.BY}◕${c.BR})${c.RESET}`,
      `${c.DIM}${c.R}/|${c.RESET}${c.BR}▲${c.DIM}${c.R}|\\${c.RESET}`,
    ],
    エンカザン: [
      `${c.BR}╭─╮${c.RESET}`,
      `${c.BR}(${c.BY}◕${c.BR}ᴗ${c.BY}◕${c.BR})${c.RESET}`,
      `${c.DIM}${c.R}/|${c.RESET}${c.BR}▲${c.DIM}${c.R}|\\${c.RESET}`,
    ],
    ミズチ: [
      `${c.BB}╭─╮${c.RESET}`,
      `${c.BB}(${c.BC}◕${c.BB}ω${c.BC}◕${c.BB})${c.RESET}`,
      `${c.DIM}${c.B}~|${c.RESET}${c.BB}◇${c.DIM}${c.B}|~${c.RESET}`,
    ],
    リュウカイ: [
      `${c.BB}╭─╮${c.RESET}`,
      `${c.BB}(${c.BC}◕${c.BB}ω${c.BC}◕${c.BB})${c.RESET}`,
      `${c.DIM}${c.B}~|${c.RESET}${c.BB}◇${c.DIM}${c.B}|~${c.RESET}`,
    ],
    ツボミン: [
      `${c.BG}╭🌱╮${c.RESET}`,
      `${c.BG}(${c.G}◕${c.BG}‿${c.G}◕${c.BG})${c.RESET}`,
      `${c.DIM}${c.G}~|${c.RESET}${c.BG}♣${c.DIM}${c.G}|~${c.RESET}`,
    ],
    ハナサウル: [
      `${c.BG}╭🌱╮${c.RESET}`,
      `${c.BG}(${c.G}◕${c.BG}‿${c.G}◕${c.BG})${c.RESET}`,
      `${c.DIM}${c.G}~|${c.RESET}${c.BG}♣${c.DIM}${c.G}|~${c.RESET}`,
    ],
    モリヌシ: [
      `${c.BG}╭🌱╮${c.RESET}`,
      `${c.BG}(${c.G}◕${c.BG}‿${c.G}◕${c.BG})${c.RESET}`,
      `${c.DIM}${c.G}~|${c.RESET}${c.BG}♣${c.DIM}${c.G}|~${c.RESET}`,
    ],
    ゴロツキ: [
      `${c.DIM}${c.W}╭─╮${c.RESET}`,
      `${c.W}(${c.R}°${c.W}ω${c.R}°${c.W})${c.RESET}`,
      `${c.DIM}${c.W}/|${c.RESET}${c.W}人${c.DIM}|\\${c.RESET}`,
    ],
    ビリネズ: [
      `${c.BY}⚡╭─╮${c.RESET}`,
      `${c.BY}(${c.BW}·${c.BY}ω${c.BW}·${c.BY})${c.RESET}`,
      `${c.DIM}${c.BY}~│${c.RESET}${c.BY}△${c.DIM}│~${c.RESET}`,
    ],
  };
  const sprite = lines[species] || [
    `${c.DIM}╭─╮${c.RESET}`,
    `${c.W}(°□°)${c.RESET}`,
    `${c.DIM}/| |\\${c.RESET}`,
  ];
  sprite.forEach((l) => process.stdout.write(indent + l + "\n"));
}

function parseHpField(text) {
  const m = text.match(/^- HP:\s*(\d+)\s*\/\s*(\d+)/m);
  return m ? [parseInt(m[1]), parseInt(m[2])] : [0, 0];
}

function parseXpField(text) {
  const m = text.match(/^- XP:\s*(\d+)\s*\/\s*(\d+)/m);
  return m ? [parseInt(m[1]), parseInt(m[2])] : [0, 0];
}

// ── Main ──
const saveText = readFile(SAVE);
if (!saveText) {
  process.stdout.write(`${c.DIM}🎮 No save data${c.RESET}\n`);
  process.exit(0);
}

const player = parseField(saveText, "Name");
const gold = parseField(saveText, "Gold");
const location = parseField(saveText, "Location");
const badges = parseField(saveText, "Badges");
const badgeN = badges === "なし" ? 0 : badges.split(",").length;
const badgeIcons = [1, 2, 3].map((i) => (i <= badgeN ? "🏅" : "·")).join("");

// ══════════════════════════════════════════
// BATTLE MODE
// ══════════════════════════════════════════
const battleText = readFile(BATTLE);
if (battleText) {
  const turn = parseField(battleText, "Turn");
  const bt = parseField(battleText, "Type");

  const playerSection = parseSection(battleText, "Player Active");
  const opponentSection = parseSection(battleText, "Opponent Active");

  const pFile = parseField(battleText, "File");
  const pName = parseField(playerSection, "Name");
  const [pCur, pMax] = parseHpField(playerSection);
  const pStatus = parseField(playerSection, "Status Effects");

  let pSpecies = pName,
    pLv = "?",
    pType = "Normal",
    pXpCur = 0,
    pXpMax = 1;
  const monsterFileText = readFile(path.join(PROJ, pFile));
  if (monsterFileText) {
    pSpecies = parseField(monsterFileText, "Species");
    pLv = parseField(monsterFileText, "Level");
    pType = parseField(monsterFileText, "Type");
    [pXpCur, pXpMax] = parseXpField(monsterFileText);
  }

  const oName = parseField(opponentSection, "Name");
  const oLv = parseField(opponentSection, "Level");
  const [oCur, oMax] = parseHpField(opponentSection);
  const oStatus = parseField(opponentSection, "Status Effects");

  const btLabel =
    bt === "gym"
      ? `${c.BR}${c.BOLD}⚔ GYM BATTLE${c.RESET}`
      : bt === "trainer"
        ? `${c.BY}${c.BOLD}⚔ TRAINER BATTLE${c.RESET}`
        : `${c.BG}${c.BOLD}⚔ WILD BATTLE${c.RESET}`;

  const w = process.stdout;
  w.write(
    `${btLabel}  ${c.DIM}Turn ${turn}${c.RESET}                          ${c.DIM}💰${gold}G ${badgeIcons}${c.RESET}\n`,
  );

  const oSI = statusIcons(oStatus);
  w.write(`                         ┌──────────────────────┐\n`);
  w.write(
    `                         │ ${c.BOLD}${c.W}${oName}${c.RESET} ${c.DIM}Lv${oLv}${c.RESET}${oSI} │\n`,
  );
  w.write(
    `                         │ HP ${hpBar(oCur, oMax, 12)} ${c.W}${oCur}/${oMax}${c.RESET} │\n`,
  );
  w.write(`                         └──────────────────────┘\n`);

  aaSprite(oName, "                              ");

  w.write(`${c.DIM}─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─${c.RESET}\n`);

  aaSprite(pSpecies, "  ");

  const pSI = statusIcons(pStatus);
  w.write(`  ┌──────────────────────────┐\n`);
  w.write(
    `  │ ${typeIcon(pType)} ${c.BOLD}${c.BW}${pName}${c.RESET} ${c.DIM}Lv${pLv}${c.RESET}${pSI}         │\n`,
  );
  w.write(
    `  │ HP ${hpBar(pCur, pMax, 12)} ${c.BW}${pCur}/${pMax}${c.RESET}       │\n`,
  );
  w.write(
    `  │ XP ${xpBar(pXpCur, pXpMax, 12)} ${c.DIM}${pXpCur}/${pXpMax}${c.RESET}       │\n`,
  );
  w.write(`  └──────────────────────────┘\n`);

  // ══════════════════════════════════════════
  // FIELD MODE
  // ══════════════════════════════════════════
} else {
  process.stdout.write(
    `🎮 ${c.BOLD}${c.BW}${player}${c.RESET}  📍${c.BC}${location}${c.RESET}  💰${c.BY}${gold}G${c.RESET}  ${badgeIcons}\n\n`,
  );

  let files;
  try {
    files = fs
      .readdirSync(MONSTERS_DIR)
      .filter((f) => /^\d.*\.md$/.test(f) && f !== "README.md")
      .sort();
  } catch {
    files = [];
  }

  for (const f of files) {
    const text = readFile(path.join(MONSTERS_DIR, f));
    if (!text) continue;
    const name = text.split("\n")[0].replace(/^# /, "");
    const species = parseField(text, "Species");
    const type = parseField(text, "Type");
    const lv = parseField(text, "Level");
    const [curHp, maxHp] = parseHpField(text);
    const [xpCur, xpMax] = parseXpField(text);

    aaSprite(species, "  ");
    process.stdout.write(
      `  ${typeIcon(type)} ${c.BOLD}${name}${c.RESET} Lv${lv}  HP ${hpBar(curHp, maxHp, 10)} ${curHp}/${maxHp}`,
    );
    if (xpCur !== undefined && xpMax !== undefined) {
      process.stdout.write(`  XP ${c.DIM}${xpCur}/${xpMax}${c.RESET}`);
    }
    process.stdout.write("\n");
  }
}
