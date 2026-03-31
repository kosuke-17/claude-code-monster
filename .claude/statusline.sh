#!/bin/bash
# Claude Code Monster — RPG Status Line
# game-state/ のファイルを読んでRPG風ステータスを表示する

# stdin から Claude Code の JSON を読む（使わないが消費は必要）
cat > /dev/null

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SAVE_FILE="$PROJECT_DIR/game-state/save.md"
BATTLE_FILE="$PROJECT_DIR/game-state/battle-current.md"
MONSTERS_DIR="$PROJECT_DIR/.claude/agents/my-monsters"

# --- カラー定義 ---
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
MAGENTA='\033[35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# --- セーブデータが無ければ未開始表示 ---
if [ ! -f "$SAVE_FILE" ]; then
  echo -e "${DIM}🎮 Claude Code Monster — /new-game でぼうけんをはじめよう！${RESET}"
  exit 0
fi

# --- save.md パース ---
player_name=$(grep '^- Name:' "$SAVE_FILE" | head -1 | sed 's/^- Name: *//')
gold=$(grep '^- Gold:' "$SAVE_FILE" | head -1 | sed 's/^- Gold: *//')
location=$(grep '^- Location:' "$SAVE_FILE" | head -1 | sed 's/^- Location: *//')
badges=$(grep '^- Badges:' "$SAVE_FILE" | head -1 | sed 's/^- Badges: *//')
battles=$(grep '^- Total Battles:' "$SAVE_FILE" | head -1 | sed 's/^- Total Battles: *//')

# --- バッジ表示 ---
badge_display=""
if echo "$badges" | grep -q "みなと"; then
  badge_display="${badge_display}🏅"
else
  badge_display="${badge_display}○"
fi
if echo "$badges" | grep -q "いわやま"; then
  badge_display="${badge_display}🏅"
else
  badge_display="${badge_display}○"
fi
if echo "$badges" | grep -q "らいうん"; then
  badge_display="${badge_display}🏅"
else
  badge_display="${badge_display}○"
fi

# --- 先頭モンスター情報 ---
lead_file=$(ls "$MONSTERS_DIR"/1-*.md 2>/dev/null | head -1)
if [ -n "$lead_file" ]; then
  mon_name=$(head -1 "$lead_file" | sed 's/^# *//')
  mon_species=$(grep '^- Species:' "$lead_file" | head -1 | sed 's/^- Species: *//')
  mon_type=$(grep '^- Type:' "$lead_file" | head -1 | sed 's/^- Type: *//')
  mon_level=$(grep '^- Level:' "$lead_file" | head -1 | sed 's/^- Level: *//')
  mon_hp=$(grep '^- HP:' "$lead_file" | head -1 | sed 's/^- HP: *//')

  # HP をパース
  current_hp=$(echo "$mon_hp" | cut -d'/' -f1 | tr -d ' ')
  max_hp=$(echo "$mon_hp" | cut -d'/' -f2 | tr -d ' ')

  # タイプ絵文字
  case "$mon_type" in
    Fire)  type_icon="🔥" ;;
    Water) type_icon="💧" ;;
    Grass) type_icon="🌿" ;;
    Elec)  type_icon="⚡" ;;
    *)     type_icon="⭐" ;;
  esac

  # HPバー（10段階）
  if [ "$max_hp" -gt 0 ] 2>/dev/null; then
    filled=$(( current_hp * 10 / max_hp ))
    empty=$(( 10 - filled ))
    # HP割合でバーの色を変える
    hp_pct=$(( current_hp * 100 / max_hp ))
    if [ "$hp_pct" -ge 50 ]; then
      bar_color="$GREEN"
    elif [ "$hp_pct" -ge 25 ]; then
      bar_color="$YELLOW"
    else
      bar_color="$RED"
    fi
    bar="${bar_color}"
    for i in $(seq 1 $filled); do bar="${bar}█"; done
    for i in $(seq 1 $empty); do bar="${bar}░"; done
    bar="${bar}${RESET}"
  else
    bar="░░░░░░░░░░"
  fi

  mon_display="${type_icon} ${mon_name} Lv${mon_level} ${bar} ${current_hp}/${max_hp}"
else
  mon_display="${DIM}モンスターなし${RESET}"
fi

# --- バトル中かどうか ---
if [ -f "$BATTLE_FILE" ]; then
  battle_turn=$(grep '^- Turn:' "$BATTLE_FILE" | head -1 | sed 's/^- Turn: *//')
  opp_name=$(grep '^- Name:' "$BATTLE_FILE" | tail -1 | sed 's/^- Name: *//')
  opp_level=$(grep '^- Level:' "$BATTLE_FILE" | tail -1 | sed 's/^- Level: *//')
  battle_type=$(grep '^- Type:' "$BATTLE_FILE" | head -1 | sed 's/^- Type: *//')

  case "$battle_type" in
    wild)    bt_label="野生戦" ;;
    trainer) bt_label="トレーナー戦" ;;
    gym)     bt_label="ジム戦" ;;
    *)       bt_label="バトル" ;;
  esac

  # Line 1: バトル情報
  echo -e "${RED}${BOLD}⚔️ ${bt_label} Turn${battle_turn}${RESET} ${mon_display} ${DIM}vs${RESET} ${opp_name} Lv${opp_level}"
  # Line 2: プレイヤー情報
  echo -e "${DIM}📍${location} | 💰${gold}G | ${badge_display} | 🎮${battles}戦${RESET}"
else
  # Line 1: モンスター + 場所
  echo -e "${mon_display} ${DIM}|${RESET} 📍${location} ${DIM}|${RESET} 💰${YELLOW}${gold}G${RESET} ${DIM}|${RESET} ${badge_display} ${DIM}|${RESET} 🎮${battles}戦"
fi
