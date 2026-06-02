#!/usr/bin/env bash
# workflow-guard.sh — PreToolUse hook (opt-in, ADVISORY) dla projektu DOCELOWEGO.
# Ostrzega, gdy ktoś edytuje kod produkcyjny w `src/`, zanim bramka fazy 4.5 dała zielone
# światło (brak `analysis.md` z werdyktem "GOTOWE DO IMPLEMENTACJI"). To uzupełnienie
# allowlist narzędzi agentów faz 1–4 (defense-in-depth), NIE twarda blokada.
#
# Wejście: JSON na stdin (PreToolUse) z polem .tool_input.file_path.
# Zachowanie: ADVISORY — przy ryzyku emituje wyłącznie `systemMessage` (JSON na stdout, exit 0)
# i NIE zmienia decyzji o uprawnieniach (bez `permissionDecision`), więc normalny przepływ
# zgody/promptów pozostaje nienaruszony. Uwaga: dla PreToolUse stderr NIE trafia do użytkownika
# przy exit 0 (jest podawane Claude'owi dopiero przy exit 2, co blokuje) — dlatego JSON, nie stderr.
# Świadomie NIE zwracamy `permissionDecision:"allow"` — to pominęłoby prompty i auto-zatwierdzało
# edycje, które guard ma tylko sygnalizować.
# Lokalny, BEZ GitHub.
set -euo pipefail

INPUT="$(cat 2>/dev/null || true)"

# Wyłuskaj file_path bez zależności od jq (best-effort).
extract_path() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true
  else
    printf '%s' "$1" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 \
      | sed -E 's/.*:[[:space:]]*"([^"]+)"/\1/' || true
  fi
}

FP="$(extract_path "$INPUT")"
[[ -z "$FP" ]] && exit 0

# Interesuje nas tylko kod produkcyjny (src/), nie testy ani docs/.
case "$FP" in
  */src/*|src/*) : ;;
  *) exit 0 ;;
esac

# Cisza tylko, gdy istnieje feature AKTYWNIE w fazie 5+: analysis.md z werdyktem GOTOWE
# ORAZ wciąż niedokończone taski. Ukończona (lub nowa bez analizy) feature NIE autoryzuje
# edycji src/ — inaczej jedna zamknięta feature wyłączyłaby guard na zawsze.
for d in docs/features/*/; do
  a="${d}analysis.md"; t="${d}tasks.md"
  [[ -f "$a" ]] || continue
  grep -Eqi '^[[:space:]]*-[[:space:]]*\*\*Werdykt\*\*[[:space:]]*:[[:space:]]*GOTOWE DO IMPLEMENTACJI' "$a" 2>/dev/null || continue
  [[ -f "$t" ]] || continue
  if grep -Eqi '^[[:space:]]*-[[:space:]]*\*\*Status\*\*[[:space:]]*:[[:space:]]*(todo|in_progress|tests_written|implemented|blocked)' "$t" 2>/dev/null; then
    exit 0
  fi
done

MSG="WORKFLOW-GUARD (ostrzeżenie): edytujesz '$FP' w src/, a żadna feature nie jest aktywnie w fazie 5+ (analysis.md 'GOTOWE DO IMPLEMENTACJI' + niedokończone taski). Upewnij się, że jesteś w fazie 5+ właściwej feature, albo użyj ścieżki szybkiej (feature-quick)."

# Ostrzeżenie nieblokujące dla użytkownika: PreToolUse pokazuje je TYLKO jako JSON `systemMessage`
# na stdout (stderr przy exit 0 nie trafia do użytkownika). BEZ `permissionDecision` — sam komunikat,
# normalny przepływ uprawnień zostaje (advisory, nie auto-allow).
if command -v jq >/dev/null 2>&1; then
  jq -n --arg m "$MSG" '{systemMessage:$m}'
else
  esc="${MSG//\\/\\\\}"; esc="${esc//\"/\\\"}"
  printf '{"systemMessage": "%s"}\n' "$esc"
fi
exit 0
