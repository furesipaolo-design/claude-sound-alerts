#!/bin/bash
# turn-start.sh — registra l'inizio del turno per il gate 'done' di play.sh.
# Hook: UserPromptSubmit. Legge session_id dallo stdin JSON. Nessun suono.
if [ -t 0 ]; then STDIN=""; else STDIN="$(/bin/cat 2>/dev/null)"; fi
SID="$(printf '%s' "$STDIN" | /usr/bin/grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | /usr/bin/head -1 | /usr/bin/sed -E 's/.*"([^"]*)"$/\1/')"
[ -z "$SID" ] && SID="default"
/bin/date +%s > "/tmp/claude-sound-alerts.$SID.start" 2>/dev/null
exit 0
