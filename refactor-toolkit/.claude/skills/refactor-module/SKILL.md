---
name: refactor-module
description: Punkt wejścia workflowu refaktoryzacji — komenda /refactor-module [ścieżka|nazwa]. Trigger gdy użytkownik wpisze /refactor-module lub poprosi o analizę/refaktoryzację mezo konkretnego modułu/feature/folderu. Uruchamia ETAP 1 (analiza mezo) przez subagenta refactor-analyzer i zatrzymuje się na GATE 1.
---

# refactor-module — start workflowu (analiza mezo)

**Trigger:** użytkownik wpisuje `/refactor-module [ścieżka|nazwa]` lub prosi o analizę/refaktoryzację
**konkretnego modułu/feature/folderu**. **Punkt wejścia** workflowu — startuje ETAP 1, zakres **Mezo**.

## Kroki
1. **Ustal moduł** z argumentu (np. `./src/Billing`, `Orders`). Brak argumentu → dopytaj, który moduł.
2. **Zainicjuj stan:** zapisz `refactor-state.md` (stage: `1-analiza`, gate: `GATE 1`, scope: `Mezo`,
   moduł, data).
3. **Uruchom subagenta `refactor-analyzer`** (przez Task): zakres `Mezo`, ścieżka/nazwa modułu,
   skill `analyze-module` (oraz `dotnet-patterns` dla .NET/C#).
4. **Odbierz `analysis-report.md`** i wydrukuj TL;DR w konsoli.

## Format outputu
- `analysis-report.md` (zakres Mezo, tworzy subagent) + `refactor-state.md`.
- Konsola: zakres + liczba naruszeń per kategoria + TL;DR.

## Obsługa błędów i edge cases
- **Moduł niejednoznaczny / nieznaleziony** → wylistuj dopasowania, poproś o wybór; nie inicjuj stanu.
- **Workflow już aktywny** → ostrzeż, zaproponuj `/refactor-status` lub `/refactor-abort`.
- **Moduł silnie spleciony z resztą repo** → zasugeruj rozważenie `/refactor-project`.

## Integracja z gate'ami
Kończy na **GATE 1**: przedstaw raport, poproś o akceptację, wskaż `/refactor-continue` (→ ETAP 2).
Bez planowania i bez zmian w kodzie.
