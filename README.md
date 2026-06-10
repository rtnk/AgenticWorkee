# AgenticWorkee

Meta-repo narzędzi AI (artefakty Claude Code: subagenci, skille, workflow). Paczki tu
**mieszkają** — kopiuje się je do projektów docelowych, gdzie powstają właściwe dokumenty i kod.

## Zawartość

- **[`backend-feature-workflow/`](backend-feature-workflow/README.md)** — powtarzalny workflow
  dla zmian w usłudze backendowej **.NET 10**: konstytucja (faza 0) → specyfikacja/plan/zadania
  (fazy 1–4) → analiza spójności (faza 4.5) → implementacja w cyklu TDD (faza 5+) → holistyczny
  przegląd (faza 6). Przeglądy porównawcze: [`REVIEW.md`](backend-feature-workflow/REVIEW.md)
  (GitHub Spec Kit) i [`REVIEW-GSD.md`](backend-feature-workflow/REVIEW-GSD.md) (GSD / Get Shit
  Done — oś context engineering). **Bez integracji GitHub.**

- **[`refactor-toolkit/`](refactor-toolkit/README.md)** — zestaw subagentów i skilli do
  **bezpiecznej, powtarzalnej refaktoryzacji** kodu zgodnie z Clean Architecture, wzorcami GoF,
  SOLID, KISS, DRY i YAGNI. Niezależny od języka, z rozszerzoną obsługą **.NET / C#**.

- **[`project-hld-generator/`](project-hld-generator/README.md)** — skill generujący
  **HLD (`docs/**/*.md`) i `CLAUDE.md`** dla istniejącego projektu: automatyczny rekonesans
  repo → interaktywna sesja Q&A (max 5–7 tur) → dokumentacja gotowa do commita.
  Język treści podąża za językiem dewelopera; CLAUDE.md z budżetem ~400–600 tokenów.

## Refactoring Toolkit

Toolkit prowadzi refaktoryzację kodu w pięciu etapach z twardymi punktami zatrzymania
(gate'ami), w których czeka na akceptację użytkownika. Naczelna zasada: **Behaviour Preservation
First** — refaktoryzacja nie zmienia zachowania zewnętrznego, a testy są tego dowodem. Działa
agnostycznie językowo, z dodatkową wiedzą o wzorcach i obsłudze wyjątków w **.NET / C#**.

Szczegóły, struktura i instrukcja instalacji: [`refactor-toolkit/README.md`](refactor-toolkit/README.md);
pełny opis komend: [`refactor-toolkit/COMMANDS.md`](refactor-toolkit/COMMANDS.md).

**Komendy:**

| Komenda | Działanie |
|---------|-----------|
| `/refactor-project [ścieżka]` | Analiza makro całego projektu/solution |
| `/refactor-module [ścieżka\|nazwa]` | Analiza mezo modułu lub folderu |
| `/refactor-class [NazwaKlasy]` | Analiza mikro konkretnej klasy |
| `/refactor-snippet` | Analiza mikro wklejonego fragmentu kodu |
| `/refactor-continue` | Kontynuuj od aktualnego gate'u po akceptacji |
| `/refactor-status` | Pokaż aktualny etap i stan workflowu |
| `/refactor-abort` | Przerwij workflow, zapisz stan |

**Workflow — 5 etapów z gate'ami:**

1. **Analiza** (`refactor-analyzer`) → `analysis-report.md` → ⛔ **GATE 1**
2. **Plan** (`refactor-planner`) → `refactor-plan.md` → ⛔ **GATE 2** (implementacja nigdy nie
   startuje bez zaakceptowanego planu)
3. **Testy baseline TDD** (`refactor-test-writer`) → `test-baseline-report.md` → ⛔ **GATE 3**
4. **Implementacja** (`refactor-implementer`) → kod + testy zielone po każdym zadaniu →
   ⛔ **GATE 4** (po każdym zadaniu)
5. **Review** (`refactor-reviewer`) → `refactor-review.md` → ⛔ **GATE 5**

Po każdym gate'cie kontynuujesz komendą `/refactor-continue`.
