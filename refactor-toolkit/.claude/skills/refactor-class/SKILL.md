---
name: refactor-class
description: Punkt wejścia workflowu refaktoryzacji — komenda /refactor-class [NazwaKlasy]. Trigger gdy użytkownik wpisze /refactor-class lub poprosi o analizę/refaktoryzację konkretnej klasy z repozytorium. Uruchamia ETAP 1 (analiza mikro) przez subagenta refactor-analyzer i zatrzymuje się na GATE 1.
---

# refactor-class — start workflowu (analiza mikro klasy)

**Trigger:** użytkownik wpisuje `/refactor-class [NazwaKlasy]` lub prosi o analizę/refaktoryzację
**konkretnej klasy** z repo. **Punkt wejścia** workflowu — startuje ETAP 1, zakres **Mikro**.

## Kroki
1. **Zlokalizuj klasę** (Grep/Glob po nazwie). Wiele dopasowań → pokaż listę plików, poproś o wybór.
   Brak argumentu → dopytaj o nazwę klasy.
2. **Zainicjuj stan:** zapisz `refactor-state.md` (stage: `1-analiza`, gate: `GATE 1`, scope: `Mikro`,
   klasa + plik, data).
3. **Uruchom subagenta `refactor-analyzer`** (przez Task): zakres `Mikro`, wskazana klasa,
   skill `analyze-snippet` (oraz `dotnet-patterns` dla .NET/C#).
4. **Odbierz `analysis-report.md`** i wydrukuj TL;DR w konsoli.

## Format outputu
- `analysis-report.md` (zakres Mikro, tworzy subagent) + `refactor-state.md`.
- Konsola: zakres + najważniejsze naruszenia + TL;DR.

## Obsługa błędów i edge cases
- **Klasa nieznaleziona** → wylistuj podobne nazwy / poproś o ścieżkę; nie inicjuj stanu.
- **Wiele dopasowań** → wybór pliku przed startem.
- **Workflow już aktywny** → ostrzeż, zaproponuj `/refactor-status` lub `/refactor-abort`.

## Integracja z gate'ami
Kończy na **GATE 1**: przedstaw raport, poproś o akceptację, wskaż `/refactor-continue` (→ ETAP 2).
Bez planowania i bez zmian w kodzie.
