# Refactoring Toolkit

Zestaw **subagentów** i **skilli** dla Claude Code do przeprowadzania refaktoryzacji kodu w
sposób bezpieczny i powtarzalny — zgodnie z **Clean Architecture**, **wzorcami projektowymi
(GoF)**, **SOLID**, **KISS**, **DRY** i **YAGNI**. Toolkit jest **niezależny od języka** tam,
gdzie to możliwe, z rozszerzoną obsługą dla **.NET / C#**.

Naczelna zasada: **Behaviour Preservation First** — refaktoryzacja nie zmienia zachowania
zewnętrznego, a testy są tego dowodem.

## Jak to działa

Toolkit prowadzi przez **5 etapów**, każdy obsługiwany przez jednego subagenta o **jednej
odpowiedzialności** i wspierany przez dedykowany skill. Między etapami stoją **gate'y** —
twarde punkty zatrzymania, w których czekamy na akceptację użytkownika, zanim ruszymy dalej.

```
ETAP 1: ANALIZA      → refactor-analyzer    → analyze-{project|module|snippet} → analysis-report.md     ⛔ GATE 1
ETAP 2: PLAN         → refactor-planner      → plan-refactor                     → refactor-plan.md       ⛔ GATE 2
ETAP 3: TESTY (TDD)  → refactor-test-writer  → write-tests                       → test-baseline-report.md ⛔ GATE 3
ETAP 4: IMPLEMENTACJA→ refactor-implementer  → implement-refactor                → kod + testy (per zadanie) ⛔ GATE 4 (po każdym zadaniu)
ETAP 5: REVIEW       → refactor-reviewer     → review-refactor                   → refactor-review.md     ⛔ GATE 5
```

- **GATE 1** — raport analizy gotowy; czekamy na akceptację zakresu.
- **GATE 2** — plan gotowy; **implementacja nigdy nie startuje bez zaakceptowanego planu**.
- **GATE 3** — testy baseline zielone na obecnym kodzie; siatka bezpieczeństwa gotowa.
- **GATE 4** — po **każdym** zadaniu: diff + zielone testy; akceptacja przed kolejnym zadaniem.
- **GATE 5** — przegląd końcowy; akceptacja zamknięcia (lub kolejna iteracja).

Po każdym gate'cie kontynuujesz komendą **`/refactor-continue`**.

## Struktura

```
refactor-toolkit/
├── README.md
├── COMMANDS.md
└── .claude/
    ├── agents/
    │   ├── refactor-analyzer.md      # ETAP 1 — diagnoza naruszeń
    │   ├── refactor-planner.md       # ETAP 2 — plan + breakdown zadań
    │   ├── refactor-test-writer.md   # ETAP 3 — testy baseline (TDD)
    │   ├── refactor-implementer.md   # ETAP 4 — bezpieczna implementacja
    │   └── refactor-reviewer.md      # ETAP 5 — przegląd końcowy
    └── skills/
        ├── analyze-project.md        # analiza makro (cały projekt/solution)
        ├── analyze-module.md         # analiza mezo (moduł/feature/folder)
        ├── analyze-snippet.md        # analiza mikro (klasa/metoda/fragment)
        ├── plan-refactor.md          # generowanie planu
        ├── write-tests.md            # testy baseline TDD
        ├── implement-refactor.md     # implementacja zmian
        ├── review-refactor.md        # przegląd wyników
        └── dotnet-patterns.md        # wzorce i reguły .NET/C#
```

## Komendy (skrót)

| Komenda | Działanie |
|---------|-----------|
| `/refactor-project [ścieżka]` | Analiza makro całego projektu/solution |
| `/refactor-module [ścieżka\|nazwa]` | Analiza mezo modułu lub folderu |
| `/refactor-class [NazwaKlasy]` | Analiza mikro konkretnej klasy |
| `/refactor-snippet` | Analiza mikro wklejonego fragmentu |
| `/refactor-continue` | Kontynuuj od aktualnego gate'u po akceptacji |
| `/refactor-status` | Pokaż aktualny etap i stan workflowu |
| `/refactor-abort` | Przerwij workflow, zapisz stan |

Pełne przykłady i opis w [`COMMANDS.md`](COMMANDS.md).

## Instalacja / użycie

Toolkit **mieszka** w tym meta-repo — kopiujesz go do projektu docelowego:

1. Skopiuj zawartość `refactor-toolkit/.claude/` do katalogu `.claude/` projektu docelowego
   (scalając `agents/` i `skills/`).
   ```bash
   cp -r refactor-toolkit/.claude/agents/*  <projekt>/.claude/agents/
   cp -r refactor-toolkit/.claude/skills/*  <projekt>/.claude/skills/
   ```
2. Otwórz projekt docelowy w Claude Code.
3. Uruchom pierwszy etap, np. `/refactor-class OrderService` lub `/refactor-module ./src/Billing`.
4. Po każdym raporcie/gate'cie zaakceptuj i kontynuuj `/refactor-continue`.

Artefakty (`analysis-report.md`, `refactor-plan.md`, `test-baseline-report.md`,
`refactor-review.md`) powstają w projekcie docelowym — to tam toczy się właściwa praca.

## Reguły ogólne (obowiązują wszystkie etapy)

1. **Behaviour Preservation First** — testy są dowodem niezmienionego zachowania.
2. **Brak implementacji bez zaakceptowanego planu** (GATE 2 zawsze przed ETAPEM 4).
3. **Nigdy nie modyfikuj testów, by „naprawić" ich wynik** — czerwień po refaktorze = błąd w refaktorze.
4. **Obsługa wyjątków jest zachowaniem** — zmiana mechanizmu = osobne zadanie + aktualizacja
   wszystkich powiązanych `catch`/call-site'ów.
5. **Jeden agent = jedna odpowiedzialność** — analyzer nie planuje, planner nie implementuje.
6. **Każda zmiana = uruchomienie testów** — implementer odpala testy po każdym zadaniu.
7. **Output zawsze do pliku + konsola** — raporty `.md` + podsumowanie w konsoli.
8. **Scope exclusions są jawne** — plan zawiera sekcję „Co NIE zostanie zmienione".
