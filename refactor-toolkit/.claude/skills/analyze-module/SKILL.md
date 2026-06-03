---
name: analyze-module
description: ETAP 1 — analiza MEZO jednego modułu/feature/folderu. Trigger — komenda /refactor-module [ścieżka|nazwa] lub prośba o ocenę konkretnego modułu/feature. Używany przez subagenta refactor-analyzer. Produkuje analysis-report.md (zakres — Mezo) i kończy na GATE 1.
---

# analyze-module — analiza mezo (moduł / feature / folder)

**Trigger:** `/refactor-module [ścieżka|nazwa]` albo prośba o ocenę konkretnego modułu/feature.
Zakres raportu: **Mezo**.

Poziom pośredni: spójność wewnętrzna modułu, współpraca klas w jego obrębie, jego zależności
na zewnątrz — bez schodzenia do każdej linii i bez audytu całego repo.

## Kroki
1. **Wyznacz granicę modułu.** Glob/Read po wskazanym katalogu/namespace. Wylistuj klasy/pliki
   wchodzące w skład modułu i jego publiczne API.
2. **Zależności wchodzące i wychodzące.** Co moduł importuje, kto importuje moduł (Grep). Oceń,
   czy zależności idą zgodnie z Dependency Rule i czy granica modułu nie przecieka.
3. **Czytaj kod modułu w całości** (mezo jest na to dość mały) — relacje między klasami,
   odpowiedzialności, przepływy.
4. **Wykryj naruszenia** per kategoria:
   - **SOLID**: klasy z wieloma odpowiedzialnościami (SRP), trudne rozszerzanie (OCP), wycieki
     abstrakcji (ISP/DIP), nieprawidłowe podstawianie (LSP).
   - **Clean Architecture**: mieszanie logiki domenowej z IO/frameworkiem wewnątrz modułu.
   - **DRY/KISS/YAGNI**: duplikacja w obrębie modułu, nadmierne uogólnienia, martwy kod.
   - **Wzorce**: gdzie wzorzec uprościłby moduł (Factory, Strategy, Decorator, Specification,
     Result zamiast wyjątków sterujących przepływem).
   - **Wyjątki**: spójność obsługi błędów wewnątrz modułu i na jego granicy.
5. **Metryki** dla modułu, jeśli dostępne; inaczej „brak danych".
6. **Zapisz `analysis-report.md`** i wydrukuj TL;DR w konsoli.

## Format outputu
Identyczny szablon jak w `analyze-project`, z nagłówkiem:
`**Zakres:** Mezo — <nazwa modułu/folderu>`. Tabele naruszeń (Zasada/Reguła/Typ | Plik | Linia |
Opis | Priorytet), sugestie wzorców, uwagi o wyjątkach, metryki, rekomendowany zakres.

Konsola: zakres + liczba naruszeń per kategoria + TL;DR.

## Obsługa błędów i edge cases
- **Moduł nie istnieje / nazwa niejednoznaczna** → wylistuj dopasowania i poproś o doprecyzowanie.
- **Moduł silnie spleciony z resztą repo** → zaznacz zależności zewnętrzne jako ryzyko i
  zasugeruj, czy nie potrzeba zakresu makro (`/refactor-project`).
- **Brak narzędzi metryk** → „brak danych".

## Integracja z gate'ami
Po zapisaniu raportu **STOP na GATE 1**. Przedstaw raport, poproś o akceptację, wskaż
`/refactor-continue` (→ ETAP 2). Bez planowania i bez zmian w kodzie.
