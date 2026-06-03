---
name: plan-refactor
description: ETAP 2 — generowanie planu refaktoryzacji z zaakceptowanego analysis-report.md. Trigger — /refactor-continue po GATE 1 lub prośba o plan refaktoryzacji. Używany przez subagenta refactor-planner. Produkuje refactor-plan.md (atomowe zadania + kolejność + wykluczenia) i kończy na GATE 2.
---

# plan-refactor — generowanie planu refaktoryzacji

**Trigger:** `/refactor-continue` po zaakceptowanym GATE 1, albo bezpośrednia prośba o plan na
podstawie istniejącego `analysis-report.md`.

Zamieniasz diagnozę w **wykonalny plan**: atomowe zadania, bezpieczna kolejność, jawne ryzyka i
wykluczenia. Plan jest kontraktem dla testów (ETAP 3) i implementacji (ETAP 4).

## Kroki
1. **Wczytaj `analysis-report.md`.** Jeśli go nie ma → STOP, poproś o wykonanie ETAPU 1.
2. **Pogrupuj naruszenia w atomowe zadania.** Jedno zadanie = jedna spójna, testowalna zmiana.
   Unikaj „mega-zadań".
3. **Opisz każde zadanie** wg formatu: priorytet, szacowany czas, pliki, **zależności**, ryzyko,
   opis (co i dlaczego), **kryterium ukończenia**.
4. **Wyznacz bezpieczną kolejność:** najpierw niskie ryzyko i zadania odblokowujące; zmiany
   ryzykowne (kontrakty publicznego API, mechanizm wyjątków, typy zwracane) jako **osobne**,
   wyraźnie oznaczone zadania, później w kolejności.
5. **Wyjątki = zachowanie.** Każda zmiana mechanizmu błędów (np. wyjątki → `Result<T>`) to
   osobne zadanie zawierające listę **wszystkich** call-site'ów i bloków `catch` do aktualizacji
   (skorzystaj z `dotnet-patterns` dla .NET/C#).
6. **Wypełnij „Co NIE zostanie zmienione"** — jawne wykluczenia zakresu (reguła #8).
7. **Zapisz `refactor-plan.md`** i wydrukuj listę zadań + kolejność w konsoli.

## Format outputu

Plik `refactor-plan.md`:

```markdown
# Plan Refaktoryzacji
**Zakres:** <z raportu>
**Skala:** Macro / Mezo / Mikro

## Zadania
### Zadanie 1: <Nazwa>
- **Priorytet:** Wysoki / Średni / Niski
- **Szacowany czas:** Xh
- **Pliki do zmiany:** <lista>
- **Zależności:** <poprzednie zadania / brak>
- **Ryzyko:** <opis>
- **Opis:** <co i dlaczego>
- **Kryterium ukończenia:** <jak sprawdzamy, że done — zwykle: testy zielone + cel spełniony>
<kolejne zadania...>

## Kolejność implementacji
<lista lub graf zależności, np. 1 → 2 → (3,4) → 5>

## Co NIE zostanie zmienione
<jawne wykluczenia zakresu>
```

Konsola: numerowana lista zadań (nazwa + priorytet) + kolejność.

## Obsługa błędów i edge cases
- **Brak `analysis-report.md`** → STOP, odeślij do ETAPU 1.
- **Raport bez konkretnych lokalizacji** → oznacz zadania jako „wymaga doprecyzowania" zamiast
  zgadywać pliki.
- **Sprzeczne/za szerokie cele** → podziel na iteracje; nadmiar zostaw w „Co NIE zostanie
  zmienione" lub jako zadania niskiego priorytetu.
- **Zależności cykliczne między zadaniami** → przeprojektuj podział na zadania, by przerwać cykl.

## Integracja z gate'ami
Po zapisaniu planu **STOP na GATE 2**. Przedstaw plan, poproś o akceptację, wskaż
`/refactor-continue` (→ ETAP 3, testy baseline). **Implementacja nigdy nie startuje bez
zaakceptowanego planu** (reguła #2).
