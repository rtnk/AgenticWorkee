---
name: analyze-snippet
description: ETAP 1 — analiza MIKRO pojedynczej klasy/metody lub wklejonego fragmentu kodu. Trigger — komendy /refactor-class [NazwaKlasy] albo /refactor-snippet (wklejony kod). Używany przez subagenta refactor-analyzer. Produkuje analysis-report.md (zakres — Mikro) i kończy na GATE 1.
---

# analyze-snippet — analiza mikro (klasa / metoda / fragment)

**Trigger:** `/refactor-class [NazwaKlasy]` (analiza konkretnej klasy w repo) albo
`/refactor-snippet` (analiza wklejonego fragmentu kodu). Zakres raportu: **Mikro**.

Najdrobniejszy poziom: jakość pojedynczej klasy/metody — czytelność, odpowiedzialności,
złożoność, nazewnictwo, obsługa błędów.

## Kroki
1. **Zlokalizuj kod.**
   - `/refactor-class` → Grep/Glob po nazwie klasy; jeśli wiele dopasowań, poproś o wybór pliku.
   - `/refactor-snippet` → użyj wklejonego fragmentu; jeśli go brak, poproś o wklejenie.
2. **Przeczytaj cały fragment** wraz z najbliższym kontekstem (sygnatury wywoływanych metod,
   typy). Zrozum, co kod robi i jakie ma zachowanie zewnętrzne.
3. **Wykryj naruszenia** per kategoria, z dokładną lokalizacją (linia):
   - **SOLID**: klasa/metoda robiąca za dużo (SRP), długie metody, sztywne `if/switch` po typie
     (OCP/Strategy), zależność od konkretów (DIP).
   - **DRY/KISS/YAGNI**: duplikaty, przekombinowana logika, nieużywane gałęzie/parametry.
   - **Wzorce**: lokalne usprawnienia (Guard Clauses, Strategy, Factory, Result zamiast wyjątku
     sterującego przepływem).
   - **Wyjątki**: połykane wyjątki, `catch` bez logowania/re-throw, `throw new Exception(...)`,
     `throw ex` (utrata stack trace), brak `using`/`finally` przy zasobach.
4. **Złożoność** — oszacuj złożoność cyklomatyczną metod (liczba ścieżek); zaznacz „szacunkowo".
5. **Zapisz `analysis-report.md`** i wydrukuj TL;DR w konsoli.

## Format outputu
Szablon jak w `analyze-project`, z nagłówkiem `**Zakres:** Mikro — <Klasa.Metoda / fragment>`.
Przy mikro tabele zwykle krótkie; sekcja „Rekomendowany zakres" wskazuje konkretne refaktory
(np. Extract Method, Replace Conditional with Polymorphism).

Konsola: zakres + lista najważniejszych naruszeń + TL;DR.

## Obsługa błędów i edge cases
- **Klasa nieznaleziona** → wylistuj podobne nazwy / poproś o ścieżkę.
- **Wiele dopasowań nazwy** → pokaż listę plików, poproś o wybór.
- **Pusty/niekompletny fragment** → poproś o pełny wklej; nie analizuj fikcyjnego kodu.
- **Fragment bez kontekstu typów** → zaznacz założenia i ogranicz pewność wniosków.

## Integracja z gate'ami
Po zapisaniu raportu **STOP na GATE 1**. Przedstaw raport, poproś o akceptację, wskaż
`/refactor-continue` (→ ETAP 2). Bez planowania i bez zmian w kodzie.
