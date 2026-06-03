---
name: refactor-snippet
description: Punkt wejścia workflowu refaktoryzacji — komenda /refactor-snippet. Trigger gdy użytkownik wpisze /refactor-snippet i wklei fragment kodu do analizy/refaktoryzacji (bez lokalizowania w repo). Uruchamia ETAP 1 (analiza mikro) przez subagenta refactor-analyzer i zatrzymuje się na GATE 1.
---

# refactor-snippet — start workflowu (analiza mikro fragmentu)

**Trigger:** użytkownik wpisuje `/refactor-snippet` i wkleja **fragment kodu**, lub prosi o analizę
wklejonego kodu. **Punkt wejścia** workflowu — startuje ETAP 1, zakres **Mikro**.

## Kroki
1. **Pobierz wklejony fragment.** Brak kodu → poproś o wklejenie w bloku ```` ``` ````; nie analizuj
   fikcyjnego kodu.
2. **Zainicjuj stan:** zapisz `refactor-state.md` (stage: `1-analiza`, gate: `GATE 1`, scope: `Mikro`,
   źródło: `snippet`, data). Jeśli to praca poza repo, zapisz artefakty w katalogu bieżącym.
3. **Uruchom subagenta `refactor-analyzer`** (przez Task): zakres `Mikro`, dołączony fragment,
   skill `analyze-snippet` (oraz `dotnet-patterns` jeśli to C#).
4. **Odbierz `analysis-report.md`** i wydrukuj TL;DR w konsoli.

## Format outputu
- `analysis-report.md` (zakres Mikro, tworzy subagent) + `refactor-state.md`.
- Konsola: lista najważniejszych naruszeń + TL;DR.

## Obsługa błędów i edge cases
- **Pusty/niekompletny fragment** → poproś o pełny wklej.
- **Fragment bez kontekstu typów** → subagent zaznaczy założenia i ograniczy pewność wniosków.
- **Workflow już aktywny** → ostrzeż, zaproponuj `/refactor-status` lub `/refactor-abort`.

## Integracja z gate'ami
Kończy na **GATE 1**: przedstaw raport, poproś o akceptację, wskaż `/refactor-continue` (→ ETAP 2).
Bez planowania i bez zmian w kodzie.
