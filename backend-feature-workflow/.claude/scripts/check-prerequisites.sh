#!/usr/bin/env bash
# check-prerequisites.sh — deterministyczna walidacja prerekwizytów workflow.
# Uruchamiany z roota projektu DOCELOWEGO (nie meta-repo).
#
# Użycie:
#   .claude/scripts/check-prerequisites.sh <slug> [--phase plan|tasks|impl] [--build] [--no-build]
#
# Fazy (co musi istnieć / być spełnione):
#   plan   : docs/constitution.md (zalecane), spec.md w statusie `ready`
#   tasks  : powyższe + plan.md
#   impl   : powyższe + tasks.md + analysis.md z werdyktem "GOTOWE DO IMPLEMENTACJI"
#            (trwały dowód bramki fazy 4.5; musi być nowszy niż tasks.md);
#            `dotnet build` musi być czysty (domyślnie dla impl; wyłącz przez --no-build).
#            Dla plan/tasks build włącza --build.
#
# Kod wyjścia: 0 = OK, 1 = brak prerekwizytów, 2 = błędne użycie.
set -euo pipefail

SLUG="${1:-}"
PHASE="impl"
RUN_BUILD=0
NO_BUILD=0
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="${2:-}"; shift 2 ;;
    --build) RUN_BUILD=1; shift ;;
    --no-build) NO_BUILD=1; shift ;;
    *) echo "Nieznany argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$SLUG" ]]; then
  echo "Użycie: $0 <slug> [--phase plan|tasks|impl] [--build] [--no-build]" >&2
  exit 2
fi

case "$PHASE" in
  plan|tasks|impl) ;;
  *) echo "Nieprawidłowa faza: '$PHASE' (dozwolone: plan|tasks|impl)" >&2; exit 2 ;;
esac

# Faza impl wymaga czystego buildu jako twardej bramki — domyślnie włączony (chyba że --no-build).
if [[ "$PHASE" == "impl" && "$NO_BUILD" -ne 1 ]]; then
  RUN_BUILD=1
fi

FEAT="docs/features/$SLUG"
ERRORS=0
note() { printf '  - %s\n' "$1"; }
fail() { printf '  ✗ %s\n' "$1"; ERRORS=$((ERRORS+1)); }
ok()   { printf '  ✓ %s\n' "$1"; }

echo "Prerekwizyty: slug=$SLUG faza=$PHASE"

# Konstytucja (zalecana, nie twarda)
if [[ -f "docs/constitution.md" ]]; then ok "docs/constitution.md"; else note "brak docs/constitution.md (zalecane — faza 0)"; fi

# spec.md + status ready
if [[ -f "$FEAT/spec.md" ]]; then
  ok "$FEAT/spec.md"
  if grep -Eqi '^\s*-\s*\*\*Status\*\*\s*:\s*ready' "$FEAT/spec.md"; then
    ok "spec status: ready"
  else
    fail "spec nie jest w statusie 'ready'"
  fi
  if grep -q '\[DO USTALENIA\]' "$FEAT/spec.md"; then
    fail "spec zawiera otwarte [DO USTALENIA]"
  fi
else
  fail "brak $FEAT/spec.md"
fi

# plan.md
if [[ "$PHASE" == "tasks" || "$PHASE" == "impl" ]]; then
  [[ -f "$FEAT/plan.md" ]] && ok "$FEAT/plan.md" || fail "brak $FEAT/plan.md"
fi

# tasks.md
if [[ "$PHASE" == "impl" ]]; then
  [[ -f "$FEAT/tasks.md" ]] && ok "$FEAT/tasks.md" || fail "brak $FEAT/tasks.md"
fi

# analysis.md — trwały dowód bramki fazy 4.5 (tylko dla impl)
if [[ "$PHASE" == "impl" ]]; then
  if [[ -f "$FEAT/analysis.md" ]]; then
    if grep -Eqi '^\s*-\s*\*\*Werdykt\*\*\s*:\s*GOTOWE DO IMPLEMENTACJI' "$FEAT/analysis.md"; then
      ok "analysis.md: GOTOWE DO IMPLEMENTACJI"
      # nieaktualność: tasks.md zmieniony po ostatniej analizie
      if [[ "$FEAT/tasks.md" -nt "$FEAT/analysis.md" ]]; then
        fail "analysis.md jest starszy niż tasks.md — uruchom feature-analyzer ponownie"
      fi
    else
      fail "analysis.md bez werdyktu 'GOTOWE DO IMPLEMENTACJI' — popraw braki i uruchom feature-analyzer"
    fi
  else
    fail "brak $FEAT/analysis.md — uruchom feature-analyzer (faza 4.5) przed implementacją"
  fi
fi

# build (twarda bramka, gdy RUN_BUILD=1)
if [[ "$RUN_BUILD" -eq 1 ]]; then
  if command -v dotnet >/dev/null 2>&1; then
    if dotnet build >/tmp/check-build.log 2>&1; then
      ok "dotnet build: czysty"
    else
      fail "dotnet build nie przechodzi (zob. /tmp/check-build.log)"
    fi
  else
    fail "dotnet niedostępny — nie da się udowodnić czystego buildu (bramka wymagana). Zainstaluj .NET SDK albo użyj --no-build, jeśli świadomie pomijasz."
  fi
fi

if [[ "$ERRORS" -gt 0 ]]; then
  echo "WYNIK: BRAK PREREKWIZYTÓW ($ERRORS) — nie wchodź w fazę 5 na ślepo." >&2
  exit 1
fi
echo "WYNIK: OK"
