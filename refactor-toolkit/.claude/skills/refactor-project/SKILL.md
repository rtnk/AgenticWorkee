---
name: refactor-project
description: Punkt wejścia workflowu refaktoryzacji — komenda /refactor-project [ścieżka]. Trigger gdy użytkownik wpisze /refactor-project lub poprosi o analizę/refaktoryzację makro całego projektu/solution. Uruchamia ETAP 1 (analiza makro) przez subagenta refactor-analyzer i zatrzymuje się na GATE 1.
---

# refactor-project — start workflowu (analiza makro)

**Trigger:** użytkownik wpisuje `/refactor-project [ścieżka]` lub prosi o analizę/refaktoryzację
**całego projektu/solution**. To **punkt wejścia** workflowu — startuje ETAP 1 w zakresie **Macro**.

## Kroki
1. **Ustal ścieżkę** z argumentu (np. `.`, `./src`, `./MyApp.sln`). Brak argumentu → przyjmij
   katalog bieżący i potwierdź; jeśli niejednoznaczne, dopytaj.
2. **Zainicjuj stan workflowu:** zapisz `refactor-state.md` (stage: `1-analiza`, gate: `GATE 1`,
   scope: `Macro`, ścieżka, data). To źródło prawdy dla `/refactor-status`, `/refactor-continue`,
   `/refactor-abort`.
3. **Uruchom subagenta `refactor-analyzer`** (przez Task) z instrukcją: zakres `Macro`, ścieżka,
   skill `analyze-project` (oraz `dotnet-patterns` dla .NET/C#).
4. **Odbierz `analysis-report.md`** i wydrukuj TL;DR w konsoli.

## Format outputu
- Plik `analysis-report.md` (tworzy go subagent, zakres Macro).
- Plik `refactor-state.md` z aktualnym etapem/gate'em.
- Konsola: zakres + liczba naruszeń per kategoria + 3–5 zdań TL;DR.

## Obsługa błędów i edge cases
- **Ścieżka nie istnieje** → poproś o poprawną; nie inicjuj stanu.
- **Workflow już aktywny** (`refactor-state.md` istnieje na innym etapie) → ostrzeż, zaproponuj
  `/refactor-status` lub `/refactor-abort` przed nowym startem.
- **Repo bardzo duże** → przekaż subagentowi, by próbkował hotspoty; zasugeruj `/refactor-module`.

## Integracja z gate'ami
Kończy na **GATE 1**: przedstaw raport, poproś o akceptację, wskaż `/refactor-continue` (→ ETAP 2).
Ten skill **nie** planuje i **nie** zmienia kodu — tylko inicjuje workflow i deleguje analizę.
