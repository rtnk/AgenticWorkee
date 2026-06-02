#!/usr/bin/env bash
# check-quick-scope.sh — deterministyczna mini-bramka zakresu dla feature-quick.
# Uruchamiany z roota projektu DOCELOWEGO (nie meta-repo), w ścieżce szybkiej.
#
# Cel: skoro feature-quick świadomie pomija spec.md/plan.md/analysis.md, ta bramka sprawdza dwa
# minimalne dowody, że zmiana nadal jest „mała":
# 1) tasks.md zawiera potwierdzoną checklistę zakresu quick path,
# 2) diff względem git base nie dotyka oczywistych plików kontraktu API, modelu danych,
#    reguł domenowych ani bezpieczeństwa.
#
# Użycie:
#   .claude/scripts/check-quick-scope.sh <slug> [--base <git-ref>]
#
# Kod wyjścia: 0 = OK, 1 = naruszenie zakresu quick path, 2 = błędne użycie / brak git.
set -euo pipefail
shopt -s nocasematch

SLUG="${1:-}"
BASE=""
BASE_FROM_ARG=0
[[ -n "$SLUG" ]] || { echo "Użycie: $0 <slug> [--base <git-ref>]" >&2; exit 2; }
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE="${2:-}"; BASE_FROM_ARG=1; shift 2 ;;
    *) echo "Nieznany argument: $1" >&2; exit 2 ;;
  esac
done

FEAT="docs/features/$SLUG"
TASKS="$FEAT/tasks.md"
[[ -f "$TASKS" ]] || { echo "[FAIL] brak $TASKS" >&2; exit 1; }

grep -qiE '\[ZAŁOŻENIE\][[:space:]]*ścieżka szybka' "$TASKS" \
  || { echo "[FAIL] $TASKS nie ma markera ścieżki szybkiej" >&2; exit 1; }

# Domyślny base powinien być punktem startowym quick path z tasks.md. Fallback do HEAD
# zostaje tylko dla kompatybilności z już istniejącymi quick-taskami bez Quick-scope-base; nowe
# tasks.md nadal powinny zapisywać Quick-scope-base, aby commit per task nie ukrył naruszenia.
if [[ "$BASE_FROM_ARG" -eq 0 ]]; then
  BASE="$(sed -nE 's/^[[:space:]]*-[[:space:]]*\*\*Quick-scope-base\*\*[[:space:]]*:[[:space:]]*(.+)[[:space:]]*$/\1/p' "$TASKS" | head -1)"
fi
BASE="${BASE:-HEAD}"
[[ -n "$BASE" ]] || { echo "Pusty --base" >&2; exit 2; }

ERRORS=0
check_item() {
  local label="$1"
  if grep -Eqi "^[[:space:]]*-[[:space:]]*\[[xX]\][[:space:]]*$label" "$TASKS"; then
    printf '[OK] checklista: %s\n' "$label"
  else
    printf '[FAIL] brak potwierdzenia checklisty quick path: %s\n' "$label" >&2
    ERRORS=$((ERRORS+1))
  fi
}

check_item 'Kontrakt API:'
check_item 'Model danych:'
check_item 'Reguły biznesowe:'
check_item 'Bezpieczeństwo:'

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[FAIL] brak repozytorium git — nie da się deterministycznie sprawdzić zakresu quick path" >&2
  exit 2
fi
if ! git rev-parse --verify "$BASE" >/dev/null 2>&1; then
  echo "[FAIL] nieznany git ref --base '$BASE'" >&2
  exit 2
fi

# Tracked zmiany względem BASE + untracked pliki (bo nowy kontrakt/migracja też łamie quick path).
mapfile -t CHANGED < <({ git diff --name-only "$BASE" --; git ls-files --others --exclude-standard; } | sort -u)

if [[ "${#CHANGED[@]}" -eq 0 ]]; then
  echo "[OK] diff: brak zmian plików względem $BASE"
else
  echo "[INFO] diff względem $BASE: ${#CHANGED[@]} plik(ów)"
fi

flag_path() {
  local kind="$1" path="$2" why="$3"
  printf '[FAIL] %s: %s — %s\n' "$kind" "$path" "$why" >&2
  ERRORS=$((ERRORS+1))
}

for path in "${CHANGED[@]}"; do
  # Artefakty dokumentacyjne feature i testy są dozwolone — bramka dotyczy ryzykownych zmian produktu.
  case "$path" in
    docs/features/*|tests/*|test/*|*.Tests/*) continue ;;
  esac

  if [[ "$path" =~ (^|/)(contracts?|openapi|swagger|protos?)(/|$) ]] \
     || [[ "$path" =~ \.(proto)$ ]] \
     || [[ "$path" =~ (^|/)(openapi|swagger).*\.(json|ya?ml)$ ]] \
     || [[ "$path" =~ (Request|Response|Dto|DTO|Contract)\.cs$ ]] \
     || [[ "$path" =~ (^|/)Controllers?/ ]] \
     || [[ "$path" =~ Controller\.cs$ ]] \
     || [[ "$path" =~ (^|/)(Endpoints?|Routes?)(/|$) ]] \
     || [[ "$path" =~ (Endpoint|Route)\.cs$ ]] \
     || [[ "$path" =~ (^|/)Program\.cs$ ]]; then
    flag_path "Kontrakt API" "$path" "quick path nie może zmieniać endpointów, kontrolerów, minimal API, kontraktów request-response, OpenAPI ani proto"
  fi

  if [[ "$path" =~ (^|/)Migrations?/ ]] \
     || [[ "$path" =~ Migration.*\.cs$ ]] \
     || [[ "$path" =~ DbContext.*\.cs$ ]] \
     || [[ "$path" =~ EntityTypeConfiguration.*\.cs$ ]] \
     || [[ "$path" =~ \.(sql)$ ]]; then
    flag_path "Model danych" "$path" "quick path nie może zmieniać migracji, DbContext ani schematu danych"
  fi

  if [[ "$path" =~ (^|/)(BusinessRules|Rules)(/|$) ]] \
     || [[ "$path" =~ (BusinessRule|DomainRule|Policy)\.cs$ ]]; then
    flag_path "Reguły biznesowe" "$path" "quick path nie może zmieniać jawnych reguł domenowych/biznesowych"
  fi

  if [[ "$path" =~ (^|/)(Auth|Authorization|Authentication|Identity|Permissions?)(/|$) ]] \
     || [[ "$path" =~ (Authorization|Authentication|Permission|Role|Secret|Token).*\.cs$ ]] \
     || [[ "$path" =~ (^|/)appsettings.*\.(json|ya?ml)$ ]]; then
    flag_path "Bezpieczeństwo" "$path" "quick path nie może zmieniać authN/authZ, sekretów ani konfiguracji bezpieczeństwa"
  fi
done

if [[ "$ERRORS" -gt 0 ]]; then
  echo "WYNIK: FAIL — zmiana nie spełnia mini-bramki quick path; eskaluj do pełnego workflow." >&2
  exit 1
fi

echo "WYNIK: OK — mini-bramka quick path zaliczona."
