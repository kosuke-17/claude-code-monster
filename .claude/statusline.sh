#!/bin/bash
# Claude Code Monster - Pokemon-style TUI Status Line

PROJ="/Users/okamurakosuke/claude-code-monster"
SAVE="$PROJ/game-state/save.md"
BATTLE="$PROJ/game-state/battle-current.md"
MONSTERS_DIR="$PROJ/.claude/agents/my-monsters"
IMG_DIR="$PROJ/images/monsters"
CHAFA=$(which chafa 2>/dev/null)

# Colors
R='\033[31m'; G='\033[32m'; Y='\033[33m'; B='\033[34m'; M='\033[35m'; C='\033[36m'; W='\033[37m'
BR='\033[91m'; BG='\033[92m'; BY='\033[93m'; BB='\033[94m'; BM='\033[95m'; BC='\033[96m'; BW='\033[97m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

if [ ! -f "$SAVE" ]; then
  echo -e "${DIM}🎮 No save data${RESET}"
  exit 0
fi

# ── Parse save.md ──
PLAYER=$(grep "^- Name:" "$SAVE" | sed 's/- Name: //')
GOLD=$(grep "^- Gold:" "$SAVE" | sed 's/- Gold: //')
LOCATION=$(grep "^- Location:" "$SAVE" | sed 's/- Location: //')
BADGES=$(grep "^- Badges:" "$SAVE" | sed 's/- Badges: //')

if [ "$BADGES" = "なし" ]; then BADGE_N=0
else BADGE_N=$(echo "$BADGES" | tr ',' '\n' | wc -l | tr -d ' '); fi

BADGE_ICONS=""
for i in 1 2 3; do
  if [ "$i" -le "$BADGE_N" ]; then BADGE_ICONS+="🏅"; else BADGE_ICONS+="·"; fi
done

# ── HP bar helper ──
hp_bar() {
  local cur=$1 max=$2 width=$3
  local pct=0 color filled empty bar=""
  if [ "$max" -gt 0 ] 2>/dev/null; then pct=$((cur * 100 / max)); fi
  if [ "$pct" -ge 50 ]; then color="$BG"
  elif [ "$pct" -ge 25 ]; then color="$BY"
  else color="$BR"; fi
  filled=$((pct * width / 100))
  if [ "$filled" -lt 1 ] && [ "$cur" -gt 0 ]; then filled=1; fi
  empty=$((width - filled))
  bar+="$color"
  for ((j=0; j<filled; j++)); do bar+="━"; done
  bar+="${DIM}${W}"
  for ((j=0; j<empty; j++)); do bar+="─"; done
  bar+="${RESET}"
  echo -en "$bar"
}

# ── XP bar ──
xp_bar() {
  local cur=$1 max=$2 width=$3
  local pct=0 filled empty bar=""
  if [ "$max" -gt 0 ] 2>/dev/null; then pct=$((cur * 100 / max)); fi
  filled=$((pct * width / 100))
  empty=$((width - filled))
  bar+="${BC}"
  for ((j=0; j<filled; j++)); do bar+="━"; done
  bar+="${DIM}${W}"
  for ((j=0; j<empty; j++)); do bar+="─"; done
  bar+="${RESET}"
  echo -en "$bar"
}

# ── Type icon ──
type_icon() {
  case "$1" in
    Fire)  echo -n "🔥" ;;
    Water) echo -n "💧" ;;
    Grass) echo -n "🌿" ;;
    Elec)  echo -n "⚡" ;;
    *)     echo -n "◻️" ;;
  esac
}

# ── Species to image file mapping ──
species_to_img() {
  case "$1" in
    ヒノコ)     echo "001-hinoko.png" ;;
    エンカザン)  echo "002-enkazan.png" ;;
    ミズチ)     echo "003-mizuchi.png" ;;
    リュウカイ)  echo "004-ryuukai.png" ;;
    ツボミン)    echo "005-tsubomin.png" ;;
    ハナサウル)  echo "006-hanasauru.png" ;;
    ゴロツキ)    echo "007-gorotsuki.png" ;;
    ビリネズ)    echo "008-birinezu.png" ;;
    *)          echo "" ;;
  esac
}

# ── Render sprite (chafa image or AA fallback) ──
# Usage: render_sprite "species_name" "indent" "size"
render_sprite() {
  local species=$1 indent=$2 size=${3:-"14x7"}
  local img_file=$(species_to_img "$species")
  local img_path="$IMG_DIR/$img_file"

  # chafa disabled — control codes leak into prompt
  aa_sprite "$species" "$indent"
}

# ── AA fallback sprites ──
aa_sprite() {
  local species=$1 indent=$2
  case "$species" in
    ヒノコ|エンカザン)
      echo -e "${indent}${BR}╭─╮${RESET}"
      echo -e "${indent}${BR}(${BY}◕${BR}ᴗ${BY}◕${BR})${RESET}"
      echo -e "${indent}${DIM}${R}/|${RESET}${BR}▲${DIM}${R}|\\\\${RESET}"
      ;;
    ミズチ|リュウカイ)
      echo -e "${indent}${BB}╭─╮${RESET}"
      echo -e "${indent}${BB}(${BC}◕${BB}ω${BC}◕${BB})${RESET}"
      echo -e "${indent}${DIM}${B}~|${RESET}${BB}◇${DIM}${B}|~${RESET}"
      ;;
    ツボミン|ハナサウル)
      echo -e "${indent}${BG}╭🌱╮${RESET}"
      echo -e "${indent}${BG}(${G}◕${BG}‿${G}◕${BG})${RESET}"
      echo -e "${indent}${DIM}${G}~|${RESET}${BG}♣${DIM}${G}|~${RESET}"
      ;;
    ゴロツキ)
      echo -e "${indent}${DIM}${W}╭─╮${RESET}"
      echo -e "${indent}${W}(${R}°${W}ω${R}°${W})${RESET}"
      echo -e "${indent}${DIM}${W}/|${RESET}${W}人${DIM}|\\\\${RESET}"
      ;;
    ビリネズ)
      echo -e "${indent}${BY}⚡╭─╮${RESET}"
      echo -e "${indent}${BY}(${BW}·${BY}ω${BW}·${BY})${RESET}"
      echo -e "${indent}${DIM}${BY}~│${RESET}${BY}△${DIM}│~${RESET}"
      ;;
    *)
      echo -e "${indent}${DIM}╭─╮${RESET}"
      echo -e "${indent}${W}(°□°)${RESET}"
      echo -e "${indent}${DIM}/| |\\\\${RESET}"
      ;;
  esac
}

# ── Status effect icons ──
status_icon() {
  case "$1" in
    *やけど*)    echo -n " 🔥${R}BRN${RESET}" ;;
  esac
  case "$1" in
    *マヒ*)      echo -n " ⚡${BY}PAR${RESET}" ;;
  esac
  case "$1" in
    *うずまき*)   echo -n " 🌀${BC}SLW${RESET}" ;;
  esac
  case "$1" in
    *パラサイト*) echo -n " 🌿${BG}PST${RESET}" ;;
  esac
  case "$1" in
    *チャージ*)   echo -n " ⚡${BY}CHG${RESET}" ;;
  esac
}

# ── Parse player monster ──
parse_monster_file() {
  local f=$1
  M_NAME=$(head -1 "$f" | sed 's/# //')
  M_LV=$(grep "^- Level:" "$f" | sed 's/- Level: //')
  M_TYPE=$(grep "^- Type:" "$f" | sed 's/- Type: //')
  M_SPECIES=$(grep "^- Species:" "$f" | sed 's/- Species: //')
  M_CUR_HP=$(grep "^- HP:" "$f" | sed 's/- HP: //' | cut -d'/' -f1 | tr -d ' ')
  M_MAX_HP=$(grep "^- HP:" "$f" | sed 's/- HP: //' | cut -d'/' -f2 | tr -d ' ')
  M_XP_LINE=$(grep "^- XP:" "$f" | sed 's/- XP: //')
  M_XP_CUR=$(echo "$M_XP_LINE" | cut -d'/' -f1 | tr -d ' ')
  M_XP_MAX=$(echo "$M_XP_LINE" | cut -d'/' -f2 | tr -d ' ')
}

# ══════════════════════════════════════════
# BATTLE MODE
# ══════════════════════════════════════════
if [ -f "$BATTLE" ]; then
  TURN=$(grep "^- Turn:" "$BATTLE" | sed 's/- Turn: //')
  BT=$(grep "^- Type:" "$BATTLE" | head -1 | sed 's/- Type: //')

  # Player
  P_FILE=$(grep "^- File:" "$BATTLE" | sed 's/- File: //')
  P_NAME=$(sed -n '/## Player Active/,/## /p' "$BATTLE" | grep "^- Name:" | sed 's/- Name: //')
  P_HP_LINE=$(sed -n '/## Player Active/,/## /p' "$BATTLE" | grep "^- HP:")
  P_CUR=$(echo "$P_HP_LINE" | sed 's/- HP: //' | cut -d'/' -f1 | tr -d ' ')
  P_MAX=$(echo "$P_HP_LINE" | sed 's/- HP: //' | cut -d'/' -f2 | tr -d ' ')
  P_STATUS=$(sed -n '/## Player Active/,/## /p' "$BATTLE" | grep "^- Status Effects:" | sed 's/- Status Effects: //')

  if [ -f "$PROJ/$P_FILE" ]; then
    P_SPECIES=$(grep "^- Species:" "$PROJ/$P_FILE" | sed 's/- Species: //')
    P_LV=$(grep "^- Level:" "$PROJ/$P_FILE" | sed 's/- Level: //')
    P_TYPE=$(grep "^- Type:" "$PROJ/$P_FILE" | sed 's/- Type: //')
    P_XP_LINE=$(grep "^- XP:" "$PROJ/$P_FILE" | sed 's/- XP: //')
    P_XP_CUR=$(echo "$P_XP_LINE" | cut -d'/' -f1 | tr -d ' ')
    P_XP_MAX=$(echo "$P_XP_LINE" | cut -d'/' -f2 | tr -d ' ')
  else
    P_SPECIES="$P_NAME"; P_LV="?"; P_TYPE="Normal"; P_XP_CUR=0; P_XP_MAX=1
  fi

  # Opponent
  O_NAME=$(sed -n '/## Opponent Active/,/## /p' "$BATTLE" | grep "^- Name:" | sed 's/- Name: //')
  O_LV=$(sed -n '/## Opponent Active/,/## /p' "$BATTLE" | grep "^- Level:" | sed 's/- Level: //')
  O_HP_LINE=$(sed -n '/## Opponent Active/,/## /p' "$BATTLE" | grep "^- HP:")
  O_CUR=$(echo "$O_HP_LINE" | sed 's/- HP: //' | cut -d'/' -f1 | tr -d ' ')
  O_MAX=$(echo "$O_HP_LINE" | sed 's/- HP: //' | cut -d'/' -f2 | tr -d ' ')
  O_STATUS=$(sed -n '/## Opponent Active/,/## /p' "$BATTLE" | grep "^- Status Effects:" | sed 's/- Status Effects: //')

  # Battle type label
  case "$BT" in
    gym)     BT_LABEL="${BR}${BOLD}⚔ GYM BATTLE${RESET}" ;;
    trainer) BT_LABEL="${BY}${BOLD}⚔ TRAINER BATTLE${RESET}" ;;
    *)       BT_LABEL="${BG}${BOLD}⚔ WILD BATTLE${RESET}" ;;
  esac

  # ── Render battle scene ──

  # Header
  echo -e "${BT_LABEL}  ${DIM}Turn ${TURN}${RESET}                          ${DIM}💰${GOLD}G ${BADGE_ICONS}${RESET}"

  # Opponent status box (top-right)
  O_STATUS_ICONS=$(status_icon "$O_STATUS")
  echo -e "                         ┌──────────────────────┐"
  echo -en "                         │ ${BOLD}${W}${O_NAME}${RESET} ${DIM}Lv${O_LV}${RESET}${O_STATUS_ICONS}"
  echo -e " │"
  echo -en "                         │ HP $(hp_bar "$O_CUR" "$O_MAX" 12) "
  echo -en "${W}${O_CUR}/${O_MAX}${RESET}"
  echo -e " │"
  echo -e "                         └──────────────────────┘"

  # Opponent sprite (right side)
  render_sprite "$O_NAME" "                              " "14x7"

  # Separator
  echo -e "${DIM}─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─${RESET}"

  # Player sprite (left side)
  render_sprite "$P_SPECIES" "  " "14x7"

  # Player status box (bottom-left)
  P_STATUS_ICONS=$(status_icon "$P_STATUS")
  echo -e "  ┌──────────────────────────┐"
  echo -e "  │ $(type_icon "$P_TYPE") ${BOLD}${BW}${P_NAME}${RESET} ${DIM}Lv${P_LV}${RESET}${P_STATUS_ICONS}         │"
  echo -en "  │ HP $(hp_bar "$P_CUR" "$P_MAX" 12) ${BW}${P_CUR}/${P_MAX}${RESET}"
  echo -e "       │"
  echo -en "  │ XP $(xp_bar "$P_XP_CUR" "$P_XP_MAX" 12) ${DIM}${P_XP_CUR}/${P_XP_MAX}${RESET}"
  echo -e "       │"
  echo -e "  └──────────────────────────┘"

# ══════════════════════════════════════════
# FIELD MODE
# ══════════════════════════════════════════
else
  echo -e "🎮 ${BOLD}${BW}${PLAYER}${RESET}  📍${BC}${LOCATION}${RESET}  💰${BY}${GOLD}G${RESET}  ${BADGE_ICONS}"
  echo ""
  for f in $(ls "$MONSTERS_DIR"/[0-9]*.md 2>/dev/null | sort); do
    parse_monster_file "$f"

    # Show sprite inline for field mode
    render_sprite "$M_SPECIES" "  " "8x4"

    echo -en "  $(type_icon "$M_TYPE") ${BOLD}${M_NAME}${RESET} Lv${M_LV}  HP $(hp_bar "$M_CUR_HP" "$M_MAX_HP" 10) ${M_CUR_HP}/${M_MAX_HP}"
    if [ -n "$M_XP_CUR" ] && [ -n "$M_XP_MAX" ]; then
      echo -en "  XP ${DIM}${M_XP_CUR}/${M_XP_MAX}${RESET}"
    fi
    echo ""
  done
fi
