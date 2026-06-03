---
name: write-tests
description: ETAP 3 — pisanie i weryfikacja testów baseline (TDD pre-refactor) pokrywających OBECNE zachowanie kodu przed refaktoryzacją. Trigger — /refactor-continue po GATE 2 lub prośba o testy baseline. Używany przez subagenta refactor-test-writer. Produkuje test-baseline-report.md i kończy na GATE 3.
---

# write-tests — testy baseline (TDD pre-refactor)

**Trigger:** `/refactor-continue` po zaakceptowanym GATE 2, albo prośba o zbudowanie siatki
bezpieczeństwa testów przed refaktoryzacją.

Budujesz testy charakteryzujące **obecne** zachowanie kodu w zakresie planu. Te testy są
dowodem zachowania zachowania (behaviour preservation) podczas implementacji.

## Kroki
1. **Wczytaj `refactor-plan.md`** — co zostanie zmienione = co musi być pokryte testami.
   Brak planu → STOP, odeślij do ETAPU 2.
2. **Zinwentaryzuj istniejące testy** i zmapuj na zachowania z planu. Zidentyfikuj **luki**
   (zachowania bez testu, nieobjęte ścieżki błędów, edge case'y).
3. **Dopisz brakujące testy** pokrywające OBECNE zachowanie, ze szczególnym naciskiem na:
   - ścieżki sukcesu i **ścieżki błędów**,
   - **obsługę wyjątków**: typy wyjątków, istotne komunikaty, warunki rzucenia,
   - edge case'y i granice (null/puste/skrajne wartości, współbieżność jeśli dotyczy).
   Dla .NET/C#: xUnit + FluentAssertions + Moq (patrz `dotnet-patterns`).
4. **Uruchom cały zestaw** (`dotnet test`/runner projektu). **WSZYSTKIE** testy muszą przejść na
   **niezmienionym** kodzie. Czerwony test = źle napisany test (charakteryzujesz realne
   zachowanie) → popraw **test**, nie kod produkcyjny.
5. **Cel pokrycia** dla .NET/C#: min. 70% dla kodu, który będzie refaktoryzowany (reguła z
   `dotnet-patterns`). Jeśli nieosiągalne — zaznacz dlaczego.
6. **Zapisz `test-baseline-report.md`** i wydrukuj podsumowanie liczbowe + PASS/FAIL w konsoli.

## Format outputu

Plik `test-baseline-report.md`:

```markdown
# Raport Baseline Testów
**Data:** <data>

## Stan przed refaktoryzacją
- Testy istniejące: X
- Testy dodane: Y
- Wynik uruchomienia: PASS / FAIL

## Pokrycie krytycznych zachowań
| Zachowanie | Test | Status |
|------------|------|--------|

## Obsługa wyjątków — pokrycie
| Wyjątek/Przypadek | Test | Status |
|-------------------|------|--------|
```

Konsola: `X istniejących + Y dodanych = PASS/FAIL` + ewentualne luki niepokryte.

## Obsługa błędów i edge cases
- **Brak frameworka testowego / nie da się uruchomić** → zgłoś jako blokadę, zaproponuj
  konfigurację; nie raportuj fałszywego PASS.
- **Test nie przechodzi na obecnym kodzie** → to charakterystyka realnego (być może wadliwego)
  zachowania: udokumentuj quirk i dopasuj **test**, nie kod. Nigdy nie „napraw" kodu na tym etapie.
- **Zachowanie zależne od czasu/losowości/IO** → izoluj (Moq/fakes), oznacz założenia.
- **Niemożliwe pełne pokrycie** (kod nietestowalny) → odnotuj w raporcie jako ryzyko i kandydat
  na osobne zadanie „seam for testing".

## Integracja z gate'ami
Po **zielonym** baseline **STOP na GATE 3**. Pokaż raport, poproś o akceptację, wskaż
`/refactor-continue` (→ ETAP 4). Z czerwonym/niekompletnym baseline **nie** przechodź dalej.
Nigdy nie modyfikujesz testów, by ukryć wynik (reguła #3).
