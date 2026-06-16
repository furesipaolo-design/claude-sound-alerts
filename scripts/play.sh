#!/bin/bash
# play.sh <category> — riproduce un effetto sonoro a caso dalla categoria.
#   Categorie: permission | question | done
# Legge la config utente (FUORI dalla cache) e non blocca mai Claude.
#
# Config:  ~/.claude/sound-alerts.local.conf   (override: $SOUND_ALERTS_CONFIG)
# DRY RUN: $SOUND_ALERTS_DRYRUN non vuoto → stampa PLAY/SKIP invece di suonare (test).

CAT="$1"
ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DIR="$ROOT/sounds/$CAT"
CFG="${SOUND_ALERTS_CONFIG:-$HOME/.claude/sound-alerts.local.conf}"
CAP=6   # durata massima riproduzione (sec)

skip() { [ -n "${SOUND_ALERTS_DRYRUN:-}" ] && printf 'SKIP %s\n' "$1"; exit 0; }

# Funzioni di parsing condivise (cfg_get, cfg_is_disabled). Richiedono $CFG impostato.
. "$(dirname "${BASH_SOURCE[0]}")/lib-config.sh"

# session_id dallo stdin JSON dell'hook (no jq). Niente lettura se invocato a mano (tty).
if [ -t 0 ]; then STDIN=""; else STDIN="$(/bin/cat 2>/dev/null)"; fi
SID="$(printf '%s' "$STDIN" | /usr/bin/grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | /usr/bin/head -1 | /usr/bin/sed -E 's/.*"([^"]*)"$/\1/')"
[ -z "$SID" ] && SID="default"

MARK="/tmp/claude-sound-alerts.$SID.last"
START="/tmp/claude-sound-alerts.$SID.start"
now=$(/bin/date +%s)

# Master switch + categoria intera. (config: file conf > default.)
case "$(cfg_get enabled true | tr '[:upper:]' '[:lower:]')" in
  false|0|no|off) skip "enabled=false" ;;
esac
cfg_is_disabled "$CAT" && skip "categoria $CAT disattivata"

# Volume (fallback 1.0 se non numerico).
VOL="$(cfg_get volume 1.0)"
case "$VOL" in ''|*[!0-9.]*) VOL=1.0 ;; esac

# Logica per categoria.
if [ "$CAT" = "done" ]; then
  # Anti-doppione: se un permesso/domanda è suonato negli ultimi 4s, salta il "done".
  if [ -f "$MARK" ]; then
    last=$(/bin/cat "$MARK" 2>/dev/null); last=${last:-0}
    [ $((now - last)) -le 4 ] && skip "anti-doppione"
  fi
  # Gate durata: 'worked' = suona solo se il turno è durato ≥ doneMinSeconds; 'always' = sempre.
  # doneMode dal file conf se presente, altrimenti derivato dal booleano doneGate.
  DONEMODE="$(cfg_get doneMode '')"
  if [ -z "$DONEMODE" ]; then
    case "$(cfg_get doneGate true | tr '[:upper:]' '[:lower:]')" in
      false|0|no|off) DONEMODE=always ;;
      *) DONEMODE=worked ;;
    esac
  fi
  if [ "$DONEMODE" != "always" ]; then
    MIN="$(cfg_get doneMinSeconds 15)"; case "$MIN" in ''|*[!0-9]*) MIN=15 ;; esac
    if [ -f "$START" ]; then
      st=$(/bin/cat "$START" 2>/dev/null); st=${st:-0}
      [ $((now - st)) -lt "$MIN" ] && skip "gate: turno < ${MIN}s"
    else
      skip "gate: nessun inizio turno"
    fi
  fi
else
  # permission/question: marca l'istante per l'anti-doppione del "done".
  /bin/date +%s > "$MARK" 2>/dev/null
fi

# Pool + filtro per-file (disabled=<cat>/<nomefile>).
shopt -s nullglob
files=()
for f in "$DIR"/*.mp3; do
  base="$(/usr/bin/basename "$f")"; base="${base%.mp3}"
  cfg_is_disabled "$CAT/$base" && continue
  files+=("$f")
done
[ ${#files[@]} -eq 0 ] && skip "pool vuoto"

# --- Rotazione "shuffle bag": ogni suono esce UNA volta prima che il giro ricominci.
#     (Il vecchio RANDOM%N era senza memoria → ripetizioni ravvicinate e suoni "sfortunati".)
#     Stato per-categoria, condiviso tra sessioni; vive in $STATEDIR (default /tmp).
STATEDIR="${SOUND_ALERTS_STATE_DIR:-/tmp}"
BAG="$STATEDIR/claude-sound-alerts.bag.$CAT"
BAGLAST="$STATEDIR/claude-sound-alerts.bag.$CAT.last"

# remaining = file non ancora estratti nel giro corrente.
remaining=()
for f in "${files[@]}"; do
  b="$(/usr/bin/basename "$f" .mp3)"
  [ -f "$BAG" ] && /usr/bin/grep -qxF "$b" "$BAG" 2>/dev/null && continue
  remaining+=("$f")
done

# Giro completo (o stato vuoto/obsoleto) → si ricomincia, evitando di ripetere
# subito l'ultimo suonato quando il pool ha più di un file.
if [ ${#remaining[@]} -eq 0 ]; then
  last=""; [ -f "$BAGLAST" ] && last="$(/bin/cat "$BAGLAST" 2>/dev/null)"
  for f in "${files[@]}"; do
    b="$(/usr/bin/basename "$f" .mp3)"
    [ ${#files[@]} -gt 1 ] && [ "$b" = "$last" ] && continue
    remaining+=("$f")
  done
  : > "$BAG" 2>/dev/null
fi

pick="${remaining[$((RANDOM % ${#remaining[@]}))]}"
pickbase="$(/usr/bin/basename "$pick" .mp3)"
printf '%s\n' "$pickbase" >> "$BAG" 2>/dev/null
printf '%s' "$pickbase" > "$BAGLAST" 2>/dev/null

# Riproduzione (player cross-platform; sempre in background, mai bloccante).
if [ -n "${SOUND_ALERTS_DRYRUN:-}" ]; then
  printf 'PLAY %s vol=%s\n' "$pick" "$VOL"; exit 0
fi
if command -v afplay >/dev/null 2>&1; then            # macOS
  nohup afplay -v "$VOL" -t "$CAP" "$pick" >/dev/null 2>&1 &
elif command -v ffplay >/dev/null 2>&1; then          # ffmpeg (cross-platform)
  nohup ffplay -nodisp -autoexit -loglevel quiet -t "$CAP" -af "volume=$VOL" "$pick" >/dev/null 2>&1 &
elif command -v mpv >/dev/null 2>&1; then             # mpv
  nohup mpv --no-video --really-quiet --length="$CAP" --volume="$(awk "BEGIN{printf \"%d\", $VOL*100}")" "$pick" >/dev/null 2>&1 &
elif command -v mpg123 >/dev/null 2>&1; then          # mpg123 (Linux, niente cap/volume)
  nohup mpg123 -q "$pick" >/dev/null 2>&1 &
else
  exit 0   # nessun player audio: esce in silenzio (es. SO non supportato)
fi
disown 2>/dev/null
exit 0
