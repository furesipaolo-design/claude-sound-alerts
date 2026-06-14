#!/bin/bash
# test-sounds.sh — anteprima di tutti gli effetti, categoria per categoria.
# Uso:  ./scripts/test-sounds.sh
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for cat in permission question done; do
  echo ""
  echo "===== $cat ====="
  for f in "$ROOT/sounds/$cat"/*.mp3; do
    [ -e "$f" ] || continue
    echo "  ▶ $(basename "$f")"
    /usr/bin/afplay -t 6 "$f"
    /bin/sleep 0.4
  done
done
echo ""
echo "Fatto. Per cambiare un suono: sostituisci/aggiungi un .mp3 nella cartella della categoria."
