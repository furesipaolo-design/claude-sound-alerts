#!/bin/bash
# lib-config.sh — funzioni di lettura della config, usate da play.sh.
# Il chiamante DEVE aver impostato $CFG (path del file di config) prima di chiamarle.

# cfg_get <key> <default>
#   Restituisce il valore, ripulito (CR + spazi), con precedenza:
#     1) chiave nel file conf $CFG (override power-user)
#     2) default
cfg_get() {
  local key="$1" def="$2" val
  if [ -f "$CFG" ]; then
    val=$(/usr/bin/grep -E "^[[:space:]]*$key[[:space:]]*=" "$CFG" 2>/dev/null | /usr/bin/tail -1)
    if [ -n "$val" ]; then
      val="${val#*=}"; val="${val//$'\r'/}"
      val="$(printf '%s' "$val" | /usr/bin/sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      [ -n "$val" ] && { printf '%s' "$val"; return; }
    fi
  fi
  printf '%s' "$def"
}

# cfg_is_disabled <token> → 0 se esiste una riga "disabled=<token>".
cfg_is_disabled() {
  [ -f "$CFG" ] || return 1
  /usr/bin/grep -E "^[[:space:]]*disabled[[:space:]]*=" "$CFG" 2>/dev/null \
    | /usr/bin/sed -E 's/^[[:space:]]*disabled[[:space:]]*=[[:space:]]*//; s/\r//; s/[[:space:]]+$//' \
    | /usr/bin/grep -qxF "$1"
}
