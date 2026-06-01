#!/usr/bin/env bash
# check-packages.sh — bramka legalności zależności NuGet (slopcheck).
# Uruchamiany z roota projektu DOCELOWEGO (nie meta-repo), w fazie 5+.
#
# Cel: wychwycić HALUCYNACJĘ pakietu — PackageReference do paczki, która nie istnieje
# w skonfigurowanym feedzie (lub jest podejrzanym typo-squatem). Dla każdego *nowego*
# pakietu (względem git HEAD) emituje werdykt [OK] / [SUS] / [SLOP].
#
# Użycie:
#   .claude/scripts/check-packages.sh [--base <git-ref>]
#     --base <ref>  punkt odniesienia do wykrycia NOWYCH pakietów (domyślnie HEAD).
#
# Werdykty:
#   [OK]   — pakiet resolvuje się z feedu (istnieje).
#   [SUS]  — istnieje, ale nazwa jest podejrzanie bliska znanej paczki (możliwy typo-squat)
#            ALBO nie dało się rozstrzygnąć offline (wymaga potwierdzenia człowieka).
#   [SLOP] — nie resolvuje się z żadnego feedu — prawdopodobna halucynacja. TWARDA BLOKADA.
#
# Kod wyjścia: 0 = brak [SLOP] (mogą być [SUS] do potwierdzenia), 1 = wykryto [SLOP],
#              2 = błędne użycie / brak narzędzi.
set -euo pipefail

BASE="HEAD"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE="${2:-}"; shift 2 ;;
    *) echo "Nieznany argument: $1" >&2; exit 2 ;;
  esac
done

if ! command -v dotnet >/dev/null 2>&1; then
  echo "dotnet niedostępny — nie da się zweryfikować legalności pakietów. Zainstaluj .NET SDK." >&2
  exit 2
fi

# Zbierz aktualne PackageReference (Include="Nazwa") z plików projektu.
current_pkgs() {
  grep -rhoE '<PackageReference[^>]*Include="[^"]+"' --include='*.csproj' --include='*.props' . 2>/dev/null \
    | sed -E 's/.*Include="([^"]+)".*/\1/' | sort -u
}

# Zbierz pakiety z wersji bazowej (git), aby policzyć tylko NOWE.
base_pkgs() {
  git grep -hoE '<PackageReference[^>]*Include="[^"]+"' "$BASE" -- '*.csproj' '*.props' 2>/dev/null \
    | sed -E 's/.*Include="([^"]+)".*/\1/' | sort -u || true
}

mapfile -t CUR < <(current_pkgs)
mapfile -t OLD < <(base_pkgs)

# NOWE = CUR \ OLD
NEW=()
for p in "${CUR[@]:-}"; do
  [[ -z "$p" ]] && continue
  found=0
  for o in "${OLD[@]:-}"; do [[ "$p" == "$o" ]] && found=1 && break; done
  [[ "$found" -eq 0 ]] && NEW+=("$p")
done

if [[ "${#NEW[@]}" -eq 0 ]]; then
  echo "Brak nowych PackageReference względem $BASE — nic do sprawdzenia."
  exit 0
fi

echo "Nowe pakiety do weryfikacji (względem $BASE): ${NEW[*]}"
SLOP=0; SUS=0
for pkg in "${NEW[@]}"; do
  # Czy pakiet istnieje w feedzie? Dokładne dopasowanie nazwy w wynikach wyszukiwania.
  if dotnet package search "$pkg" --exact-match >/tmp/pkgsearch.log 2>&1 \
     && grep -qiE "(^|[^A-Za-z0-9.])$pkg([^A-Za-z0-9.]|$)" /tmp/pkgsearch.log; then
    printf '  [OK]  %s — resolvuje się z feedu.\n' "$pkg"
  elif dotnet package search "$pkg" >/tmp/pkgsearch.log 2>&1 && [[ -s /tmp/pkgsearch.log ]]; then
    printf '  [SUS] %s — brak dokładnego trafienia; możliwy typo-squat. Potwierdź u człowieka.\n' "$pkg"
    SUS=$((SUS+1))
  else
    printf '  [SLOP] %s — nie znaleziono w żadnym feedzie (prawdopodobna halucynacja). BLOKADA.\n' "$pkg"
    SLOP=$((SLOP+1))
  fi
done

echo "Podsumowanie: SLOP=$SLOP, SUS=$SUS, OK=$(( ${#NEW[@]} - SLOP - SUS ))."
if [[ "$SLOP" -gt 0 ]]; then
  echo "WYNIK: BLOKADA — usuń/zastąp pakiet(y) [SLOP] albo udowodnij ich istnienie. Nie zgaduj." >&2
  exit 1
fi
if [[ "$SUS" -gt 0 ]]; then
  echo "WYNIK: WYMAGA POTWIERDZENIA — pakiety [SUS] wymagają jawnej zgody człowieka (checkpoint)."
fi
echo "WYNIK: OK (brak [SLOP])."
