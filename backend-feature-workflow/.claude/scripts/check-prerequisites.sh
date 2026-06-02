#!/usr/bin/env bash
# check-prerequisites.sh — deterministyczna walidacja prerekwizytów workflow.
# Uruchamiany z roota projektu DOCELOWEGO (nie meta-repo).
#
# Użycie:
#   .claude/scripts/check-prerequisites.sh <slug> [--phase plan|tasks|impl] [--build] [--no-build]
#
# Fazy (co musi istnieć / być spełnione):
#   plan   : docs/constitution.md (zalecane), spec.md w statusie `ready`
#   tasks  : powyższe + plan.md (+ brak cykli w DAG zależności tasków, jeśli tasks.md istnieje)
#   impl   : powyższe + tasks.md + analysis.md z werdyktem "GOTOWE DO IMPLEMENTACJI"
#            (trwały dowód bramki fazy 4.5; musi być nowszy niż spec.md/plan.md/tasks.md);
#            brak cykli w DAG zależności tasków; `dotnet build` musi być czysty
#            (domyślnie dla impl; wyłącz przez --no-build). Dla plan/tasks build włącza --build.
#
# Podkomenda:
#   progress <slug>  : read-only — wypisuje bieżącą fazę i NASTĘPNĄ komendę do uruchomienia.
#
# Kod wyjścia: 0 = OK, 1 = brak prerekwizytów, 2 = błędne użycie.
set -euo pipefail

# Wykrywa cykl w DAG zależności tasków (tasks.md). Zwraca 0 = brak cyklu, 1 = cykl/błąd.
# Parsuje nagłówki "### T-xxx" i następującą po nich linię "- **Zależności**: ...".
detect_task_cycle() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  awk '
    /^###[[:space:]]+T-[0-9]+/ {
      match($0, /T-[0-9]+/); cur = substr($0, RSTART, RLENGTH);
      nodes[cur] = 1; next
    }
    /^[[:space:]]*-[[:space:]]*\*\*Zależności\*\*[[:space:]]*:/ && cur != "" {
      line = $0;
      n = 0; depcount = 0;
      while (match(line, /T-[0-9]+/)) {
        d = substr(line, RSTART, RLENGTH);
        edge[cur, ++cnt[cur]] = d; depcount++;
        line = substr(line, RSTART + RLENGTH);
      }
      cur = ""; next
    }
    END {
      # Kahn: policz wejścia. Krawędź dep -> task (dep musi być przed task).
      for (t in nodes) indeg[t] = 0;
      for (t in nodes) {
        for (i = 1; i <= cnt[t]; i++) {
          dep = edge[t, i];
          if (dep in nodes) { adj[dep, ++adjc[dep]] = t; indeg[t]++; }
        }
      }
      qn = 0;
      for (t in nodes) if (indeg[t] == 0) queue[++qn] = t;
      processed = 0; head = 1;
      while (head <= qn) {
        u = queue[head++]; processed++;
        for (i = 1; i <= adjc[u]; i++) {
          v = adj[u, i];
          if (--indeg[v] == 0) queue[++qn] = v;
        }
      }
      total = 0; for (t in nodes) total++;
      if (processed < total) { print "CYCLE"; exit 1 }
      exit 0
    }
  ' "$file"
}

# Podkomenda: progress (read-only wskaźnik następnego kroku).
if [[ "${1:-}" == "progress" ]]; then
  PSLUG="${2:-}"
  [[ -z "$PSLUG" ]] && { echo "Użycie: $0 progress <slug>" >&2; exit 2; }
  F="docs/features/$PSLUG"
  step() { echo "FAZA: $1"; echo "NASTĘPNA KOMENDA: $2"; exit 0; }
  # Ścieżka szybka (feature-quick): tasks.md z markerem, brak spec/plan/analizy jest świadomy.
  # Nie odsyłaj do feature-spec-author — kieruj wprost do/po pętli TDD.
  if [[ -f "$F/tasks.md" ]] && grep -qiE '\[ZAŁOŻENIE\][[:space:]]*ścieżka szybka' "$F/tasks.md"; then
    if grep -Eqi '^\s*-\s*\*\*Status\*\*\s*:\s*(todo|in_progress|tests_written|implemented)' "$F/tasks.md"; then
      step "5 (ścieżka szybka)" "Kontynuuj feature-quick dla $F/ (lub feature-implementation-orchestrator dla $F/tasks.md)."
    fi
    if grep -Eqi '^\s*-\s*\*\*Status\*\*\s*:\s*blocked' "$F/tasks.md"; then
      step "5 (ścieżka szybka — zablokowane)" "Zmiana nie jest drobna — przejdź na pełny workflow: feature-spec-author."
    fi
    step "zakończona (ścieżka szybka)" "Zmiana szybka gotowa — wszystkie taski done."
  fi
  [[ -f "docs/constitution.md" ]] || step "0 (konstytucja)" "Użyj subagenta feature-constitution-author. Ustal zasady projektu i zapisz docs/constitution.md."
  [[ -f "$F/spec.md" ]] || step "1 (specyfikacja)" "Użyj subagenta feature-spec-author. Opis feature: \"<opis>\""
  if ! grep -Eqi '^\s*-\s*\*\*Status\*\*\s*:\s*ready' "$F/spec.md" || grep -q '\[DO USTALENIA\]' "$F/spec.md"; then
    step "2 (doprecyzowanie)" "Użyj subagenta feature-spec-refiner dla $F/spec.md."
  fi
  [[ -f "$F/plan.md" ]] || step "3 (plan)" "Użyj subagenta feature-planner dla $F/spec.md."
  [[ -f "$F/tasks.md" ]] || step "4 (zadania)" "Użyj subagenta feature-task-decomposer dla $F/plan.md."
  if [[ ! -f "$F/analysis.md" ]] || ! grep -Eqi '^\s*-\s*\*\*Werdykt\*\*\s*:\s*GOTOWE DO IMPLEMENTACJI' "$F/analysis.md"; then
    step "4.5 (analiza)" "Użyj subagenta feature-analyzer dla $F/."
  fi
  for inp in spec.md plan.md tasks.md; do
    if [[ -f "$F/$inp" && "$F/$inp" -nt "$F/analysis.md" ]]; then
      step "4.5 (analiza nieaktualna)" "Użyj subagenta feature-analyzer dla $F/."
    fi
  done
  # Pozostałe wykonalne taski? (status todo / in_progress / niepełne)
  if grep -Eqi '^\s*-\s*\*\*Status\*\*\s*:\s*(todo|in_progress|tests_written|implemented)' "$F/tasks.md"; then
    step "5+ (implementacja)" "Użyj subagenta feature-implementation-orchestrator dla $F/tasks.md."
  fi
  # Zadania zablokowane? NIE przechodź do przeglądu — najpierw rozwiąż blokadę (faza 5+ niedokończona).
  if grep -Eqi '^\s*-\s*\*\*Status\*\*\s*:\s*blocked' "$F/tasks.md"; then
    step "5+ (zablokowane)" "Rozwiąż blokadę zadań w $F/tasks.md (zmień spec przez feature-spec-refiner lub uzupełnij brakującą decyzję), uruchom ponownie feature-analyzer, potem wróć do feature-implementation-orchestrator."
  fi
  if [[ ! -f "$F/review.md" ]] || ! grep -Eqi '^\s*-\s*\*\*Werdykt\*\*\s*:\s*CZYSTE' "$F/review.md"; then
    step "6 (przegląd)" "Użyj subagenta feature-reviewer dla $F/."
  fi
  step "zakończona" "Feature gotowa — wszystkie taski done i przegląd CZYSTE."
fi

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

# Tryb szybki (feature-quick): tasks.md z markerem ścieżki szybkiej — brak spec/plan/analizy
# jest ŚWIADOMY (kryteria inline). Dotyczy tylko fazy impl.
QUICK=0
if [[ "$PHASE" == "impl" && -f "$FEAT/tasks.md" ]] \
   && grep -qiE '\[ZAŁOŻENIE\][[:space:]]*ścieżka szybka' "$FEAT/tasks.md"; then
  QUICK=1
fi

# Konstytucja (zalecana, nie twarda)
if [[ -f "docs/constitution.md" ]]; then ok "docs/constitution.md"; else note "brak docs/constitution.md (zalecane — faza 0)"; fi

# spec.md + status ready (pomijane w trybie szybkim — kryteria inline w tasks.md)
if [[ "$QUICK" -eq 1 ]]; then
  ok "ścieżka szybka — pomijam spec.md/plan.md/analysis.md (kryteria inline w tasks.md)"
elif [[ -f "$FEAT/spec.md" ]]; then
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

# plan.md (pomijane w trybie szybkim)
if [[ "$QUICK" -ne 1 && ( "$PHASE" == "tasks" || "$PHASE" == "impl" ) ]]; then
  [[ -f "$FEAT/plan.md" ]] && ok "$FEAT/plan.md" || fail "brak $FEAT/plan.md"
fi

# tasks.md (+ brak cykli w DAG zależności)
# Faza `tasks` jest wywoływana przed dekompozycją, więc brak tasks.md jest OK; jeśli plik już
# istnieje (np. ponowna walidacja po fazie 4), sprawdzamy DAG od razu, zgodnie z deklaracją nagłówka.
# Faza `impl` wymaga tasks.md bezwarunkowo.
if [[ "$PHASE" == "tasks" || "$PHASE" == "impl" ]]; then
  if [[ -f "$FEAT/tasks.md" ]]; then
    ok "$FEAT/tasks.md"
    if detect_task_cycle "$FEAT/tasks.md" >/dev/null 2>&1; then
      ok "DAG zależności tasków: bez cykli"
    else
      fail "cykl w zależnościach tasków (tasks.md) — orchestrator nie ruszy; rozplącz zależności (faza 4)"
    fi
  elif [[ "$PHASE" == "impl" ]]; then
    fail "brak $FEAT/tasks.md"
  else
    note "brak $FEAT/tasks.md (OK przed fazą 4; DAG sprawdzę po utworzeniu tasks.md)"
  fi
fi

# analysis.md — trwały dowód bramki fazy 4.5 (tylko dla impl; pomijane w trybie szybkim)
if [[ "$PHASE" == "impl" && "$QUICK" -ne 1 ]]; then
  if [[ -f "$FEAT/analysis.md" ]]; then
    if grep -Eqi '^\s*-\s*\*\*Werdykt\*\*\s*:\s*GOTOWE DO IMPLEMENTACJI' "$FEAT/analysis.md"; then
      ok "analysis.md: GOTOWE DO IMPLEMENTACJI"
      # nieaktualność: którekolwiek z wejść analizy zmienione po ostatniej analizie
      for input in spec.md plan.md tasks.md; do
        if [[ -f "$FEAT/$input" && "$FEAT/$input" -nt "$FEAT/analysis.md" ]]; then
          fail "analysis.md jest starszy niż $input — uruchom feature-analyzer ponownie"
        fi
      done
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
  echo "WYNIK: BRAK PREREKWIZYTÓW ($ERRORS) — nie przechodź dalej na ślepo." >&2
  exit 1
fi
echo "WYNIK: OK"
