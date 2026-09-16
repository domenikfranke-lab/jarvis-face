#!/bin/bash
# Lokalen Stand auf GitHub Pages schieben.
#
# Das Arbeitsverzeichnis liegt bewusst NICHT hier im Vault, sondern unter
# ~/Developer/jarvis-face-pages - sonst landet .git im Drive-Sync.
# ref.png bleibt absichtlich draussen: Standbild aus fremdem Instagram-Reel.
set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
OUT="$HOME/Developer/jarvis-face-pages"
export PATH="$HOME/.local/bin:$PATH"

[ -d "$OUT/.git" ] || { echo "Kein Klon unter $OUT"; exit 1; }
cp "$SRC/index.html" "$SRC/HANDOVER.md" "$SRC/serve.py" "$OUT/"
cd "$OUT"
if git diff --quiet && git diff --cached --quiet; then
  echo "Nichts geaendert."; exit 0
fi
git add -A
git commit -q -m "${1:-Avatar aktualisiert}"
git push -q origin main
echo "https://domenikfranke-lab.github.io/jarvis-face/  (Deploy dauert ~1 min)"
