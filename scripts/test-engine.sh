#!/bin/bash
# test-engine.sh — verifica il motore di play.sh in DRY_RUN (nessun suono).
# Uso: ./scripts/test-engine.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLAY="$ROOT/scripts/play.sh"
TMP="$(/usr/bin/mktemp -d)"
CFG="$TMP/conf"
SID="testsession-$$"
LAST="/tmp/claude-sound-alerts.$SID.last"
START="/tmp/claude-sound-alerts.$SID.start"
STDIN_JSON="{\"session_id\":\"$SID\",\"hook_event_name\":\"Stop\"}"
pass=0; fail=0

cleanup() { rm -rf "$TMP" "$LAST" "$START"; }
trap cleanup EXIT

reset() { : > "$CFG"; rm -f "$LAST" "$START"; }
now() { /bin/date +%s; }

run() {  # run <category> -> output DRY_RUN di play.sh
  printf '%s' "$STDIN_JSON" | SOUND_ALERTS_DRYRUN=1 SOUND_ALERTS_CONFIG="$CFG" "$PLAY" "$1"
}

check() {  # check <desc> <substring-attesa> <output>
  if printf '%s' "$3" | /usr/bin/grep -qF "$2"; then
    echo "  ✅ $1"; pass=$((pass+1))
  else
    echo "  ❌ $1 — atteso '$2', ottenuto '$3'"; fail=$((fail+1))
  fi
}

echo "== scenari =="

reset
check "default: 'question' suona" "PLAY" "$(run question)"

reset; echo "enabled=false" >> "$CFG"
check "enabled=false → SKIP" "SKIP" "$(run question)"

reset; echo "volume=0.3" >> "$CFG"
check "volume passato a afplay" "vol=0.3" "$(run question)"

reset; echo "disabled=question" >> "$CFG"
check "categoria off → SKIP" "SKIP" "$(run question)"

# filtro per-file: spengo TUTTI i 'done' tranne tada → deve restare solo tada (gate bypassato con always)
reset; echo "doneMode=always" >> "$CFG"
for f in "$ROOT"/sounds/done/*.mp3; do b=$(basename "$f" .mp3); [ "$b" != "tada" ] && echo "disabled=done/$b" >> "$CFG"; done
check "filtro per-file lascia tada" "tada.mp3" "$(run done)"

# anti-doppione: .last appena scritto → done saltato (anche con always)
reset; echo "doneMode=always" >> "$CFG"; now > "$LAST"
check "anti-doppione ≤4s → SKIP" "SKIP" "$(run done)"

# gate worked (default), inizio turno appena segnato → turno breve → SKIP
reset; now > "$START"
check "gate: turno breve → SKIP" "SKIP" "$(run done)"

# gate worked, inizio turno 100s fa → turno lungo → PLAY
reset; echo "$(( $(now) - 100 ))" > "$START"
check "gate: turno lungo → PLAY" "PLAY" "$(run done)"

# gate worked, nessun inizio turno → conservativo → SKIP
reset
check "gate: nessun inizio turno → SKIP" "SKIP" "$(run done)"

# doneMode=always ignora il gate anche senza inizio turno
reset; echo "doneMode=always" >> "$CFG"
check "always: gate ignorato → PLAY" "PLAY" "$(run done)"

# permission scrive il marker anti-doppione
reset; run permission >/dev/null
if [ -f "$LAST" ]; then echo "  ✅ permission scrive .last"; pass=$((pass+1)); else echo "  ❌ permission NON scrive .last"; fail=$((fail+1)); fi

# --- config via file conf, override delle 4 chiavi ---
reset; echo "volume=0.4" >> "$CFG"
check "conf: volume override" "vol=0.4" "$(run question)"

reset; echo "doneGate=false" >> "$CFG"
check "conf: doneGate=false → always → PLAY" "PLAY" "$(run done)"

reset; echo "doneGate=true" >> "$CFG"; echo "$(( $(now) - 100 ))" > "$START"
check "conf: doneGate=true + turno lungo → PLAY" "PLAY" "$(run done)"

echo ""
echo "Risultato: $pass passati, $fail falliti"
[ "$fail" -eq 0 ]
