#!/usr/bin/env bash
# install.sh — instaluje paczkę backend-feature-workflow do projektu docelowego.
# Kopiuje agentów, skille i skrypty do <projekt>/.claude/, NIE nadpisując istniejących
# plików (warstwowanie: projekt-lokalny artefakt o tej samej nazwie wygrywa — patrz README).
#
# Użycie:
#   backend-feature-workflow/.claude/scripts/install.sh <ścieżka-do-projektu>
#   FORCE=1 ... install.sh <projekt>   # nadpisuje istniejące pliki paczki
set -euo pipefail

DEST="${1:-}"
if [[ -z "$DEST" ]]; then
  echo "Użycie: $0 <ścieżka-do-projektu> [FORCE=1]" >&2
  exit 2
fi
if [[ ! -d "$DEST" ]]; then
  echo "Katalog docelowy nie istnieje: $DEST" >&2
  exit 2
fi

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # .../backend-feature-workflow/.claude
FORCE="${FORCE:-0}"
CP_FLAGS=( -R )
[[ "$FORCE" -eq 1 ]] && CP_FLAGS+=( -f ) || CP_FLAGS+=( -n )

mkdir -p "$DEST/.claude/agents" "$DEST/.claude/skills" "$DEST/.claude/scripts"

echo "Instaluję z: $SRC"
echo "Do:          $DEST/.claude (FORCE=$FORCE)"

copied=0; skipped=0
for kind in agents skills scripts; do
  for item in "$SRC/$kind"/*; do
    [[ -e "$item" ]] || continue
    base="$(basename "$item")"
    target="$DEST/.claude/$kind/$base"
    if [[ -e "$target" && "$FORCE" -ne 1 ]]; then
      printf '  = pomijam istniejący: .claude/%s/%s\n' "$kind" "$base"
      skipped=$((skipped+1))
    else
      cp "${CP_FLAGS[@]}" "$item" "$DEST/.claude/$kind/"
      printf '  + %s/%s\n' "$kind" "$base"
      copied=$((copied+1))
    fi
  done
done

chmod +x "$DEST/.claude/scripts/"*.sh 2>/dev/null || true
echo "Gotowe: skopiowano=$copied, pominięto=$skipped."
echo "Dokumenty feature powstaną w $DEST/docs/ przy pierwszym uruchomieniu (faza 0/1)."
