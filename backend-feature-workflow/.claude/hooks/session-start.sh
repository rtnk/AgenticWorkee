#!/usr/bin/env bash
# session-start.sh — SessionStart hook (opt-in) dla projektu DOCELOWEGO.
# Waliduje środowisko backendu .NET 10 i wypisuje krótki kontekst na starcie sesji.
# Lokalny, bez sieci poza `dotnet restore`, BEZ GitHub. Wyjście trafia do kontekstu sesji.
#
# Podłączenie: patrz .claude/hooks/settings.snippet.json (scal do .claude/settings.json).
set -euo pipefail

echo "== backend-feature-workflow: kontrola środowiska =="

if command -v dotnet >/dev/null 2>&1; then
  echo "  dotnet: $(dotnet --version 2>/dev/null || echo '?')"
  # Restore jest tani i ujawnia brak pakietów wcześnie; nie przerywa sesji przy błędzie.
  if dotnet restore >/tmp/sessionstart-restore.log 2>&1; then
    echo "  restore: OK"
  else
    echo "  restore: NIEUDANY (zob. /tmp/sessionstart-restore.log) — napraw przed fazą 5."
  fi
else
  echo "  dotnet: BRAK — zainstaluj .NET SDK (faza 5 wymaga build/test)."
fi

# Progres feature: jeśli jest dokładnie jedna aktywna feature, pokaż jej state.md.
if [[ -d docs/features ]]; then
  for st in docs/features/*/state.md; do
    [[ -e "$st" ]] || continue
    echo "  feature $(basename "$(dirname "$st")"):"
    sed -n 's/^- /    /p' "$st" 2>/dev/null | head -8 || true
  done
fi

echo "== koniec kontroli =="
exit 0
