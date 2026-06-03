---
name: analyze-project
description: ETAP 1 — analiza MAKRO całego projektu/solution. Trigger — komenda /refactor-project [ścieżka] lub prośba o ocenę architektury całego repozytorium/solution. Używany przez subagenta refactor-analyzer. Produkuje analysis-report.md (zakres — Macro) i kończy na GATE 1.
---

# analyze-project — analiza makro (cały projekt)

**Trigger:** `/refactor-project [ścieżka]` albo prośba typu „oceń architekturę całego
projektu/solution". Zakres raportu: **Macro**.

Ten skill patrzy z lotu ptaka: granice warstw, kierunek zależności, podział na moduły, spójność
wzorców w skali repozytorium — nie pojedyncze metody.

## Kroki
1. **Ustal granice projektu.** Glob po strukturze (`**/*.csproj`, `**/*.sln`, `package.json`,
   katalogi modułów). Zidentyfikuj warstwy/moduły i punkty wejścia.
2. **Zmapuj zależności między warstwami/modułami.** Sprawdź kierunek zależności (Dependency
   Rule Clean Architecture: zależności wskazują do wewnątrz; Domain nie zależy od Infrastructure).
   Wykryj cykle i odwrócone zależności (Grep po `using`/`import`).
3. **Próbkuj reprezentatywnie.** Przy dużym repo nie czytaj wszystkiego — wybierz pliki-„hotspoty"
   (duże, często zmieniane, centralne). Zaznacz, że to próbka.
4. **Wykryj naruszenia makro** per kategoria:
   - **SOLID** w skali modułów (np. moduł robiący zbyt wiele → SRP; brak abstrakcji na granicy → DIP).
   - **Clean Architecture**: przecieki warstw, Domain zależny od frameworka/IO, logika w kontrolerach.
   - **DRY/KISS/YAGNI**: zduplikowane moduły/abstrakcje, nadmiarowe warstwy „na wszelki wypadek".
   - **Wzorce**: gdzie wzorzec uporządkowałby granice (Repository/UoW, CQRS, Factory, Specification).
   - **Wyjątki**: globalna strategia błędów (centralny handler? mieszanka wyjątki/Result?).
5. **Zbierz metryki**, jeśli narzędzia dostępne (złożoność, duplikacja, pokrycie). Inaczej „brak danych".
6. **Zapisz `analysis-report.md`** (format niżej) i wydrukuj TL;DR w konsoli.

## Format outputu

Plik `analysis-report.md`:

```markdown
# Raport Analizy Refaktoryzacji
**Zakres:** Macro — <nazwa projektu/solution>
**Data:** <data>

## Podsumowanie wykonawcze
<2-3 zdania ogólnej oceny architektury>

## Naruszenia według kategorii
### SOLID
| Zasada | Plik | Linia | Opis | Priorytet |
|--------|------|-------|------|-----------|
### Clean Architecture
| Reguła | Plik | Linia | Opis | Priorytet |
### DRY / KISS / YAGNI
| Typ | Plik | Linia | Opis | Priorytet |
### Wzorce projektowe — możliwe zastosowanie
- <sugestia + uzasadnienie + gdzie>
### Obsługa wyjątków — uwagi
- <problem + lokalizacja>

## Metryki (jeśli dostępne)
- Złożoność cyklomatyczna: ...
- Duplikacja kodu: ...
- Pokrycie testami: ...

## Rekomendowany zakres refaktoryzacji
<co warto zmienić, co zostawić>
```

Konsola: zakres + liczba naruszeń per kategoria + 3–5 zdań TL;DR.

## Obsługa błędów i edge cases
- **Ścieżka nie istnieje / pusta** → poproś o poprawną ścieżkę, nie zgaduj.
- **Brak rozpoznanego projektu** (żaden `.sln`/`.csproj`/`package.json`) → zaznacz „analiza
  ogólna, agnostyczna językowo" i kontynuuj.
- **Repo zbyt duże** → jawnie zaznacz, że to próbka hotspotów; zaproponuj zawężenie do modułu
  (`/refactor-module`).
- **Brak narzędzi metryk** → sekcja Metryki = „brak danych", nigdy nie zmyślaj liczb.

## Integracja z gate'ami
Po zapisaniu raportu **STOP na GATE 1**. Przedstaw raport, poproś o akceptację i wskaż
`/refactor-continue` jako przejście do ETAPU 2 (plan). Nie planuj i nie zmieniaj kodu w tym skillu.
