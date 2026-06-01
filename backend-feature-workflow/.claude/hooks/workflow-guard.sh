#!/usr/bin/env bash
# workflow-guard.sh — PreToolUse hook (opt-in, ADVISORY) dla projektu DOCELOWEGO.
# Ostrzega, gdy ktoś edytuje kod produkcyjny w `src/`, zanim bramka fazy 4.5 dała zielone
# światło (brak `analysis.md` z werdyktem "GOTOWE DO IMPLEMENTACJI"). To uzupełnienie
# allowlist narzędzi agentów faz 1–4 (defense-in-depth), NIE twarda blokada.
#
# Wejście: JSON na stdin (PreToolUse) z polem .tool_input.file_path.
# Zachowanie: zawsze przepuszcza (exit 0); przy ryzyku wypisuje ostrzeżenie na stderr.
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

# Czy istnieje JAKIKOLWIEK analysis.md z werdyktem GOTOWE? Jeśli tak — cisza.
if grep -rqsE '^\s*-\s*\*\*Werdykt\*\*\s*:\s*GOTOWE DO IMPLEMENTACJI' docs/features 2>/dev/null; then
  exit 0
fi

echo "WORKFLOW-GUARD (ostrzeżenie): edytujesz '$FP' w src/, a żadna feature nie ma jeszcze" >&2
echo "  analysis.md z werdyktem 'GOTOWE DO IMPLEMENTACJI' (bramka fazy 4.5). Upewnij się, że" >&2
echo "  jesteś w fazie 5+ właściwej feature, albo użyj ścieżki szybkiej (feature-quick)." >&2
exit 0
