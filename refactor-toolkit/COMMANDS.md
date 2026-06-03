# Komendy — Refactoring Toolkit

Każda komenda `/refactor-*` jest zaimplementowana jako **skill-punkt-wejścia**
(`.claude/skills/<nazwa>/SKILL.md`), więc wpisanie `/refactor-project` uruchamia odpowiedni
skill — nie ma osobnych plików w `.claude/commands/`. Komendy działają też jako **naturalne
triggery** (zdanie opisujące intencję). Każda komenda uruchamia odpowiedni etap workflowu i
zatrzymuje się na właściwym gate'cie.

Mapowanie etap → subagent → skill → output opisuje [`README.md`](README.md).

---

## Komendy startowe (ETAP 1 — Analiza)

### `/refactor-project [ścieżka]`
Pełna analiza **makro** całego projektu/solution.
- **Subagent:** `refactor-analyzer` · **Skill:** `analyze-project`
- **Output:** `analysis-report.md` (Zakres: Macro) → **GATE 1**
- **Przykłady:**
  ```
  /refactor-project .
  /refactor-project ./src
  /refactor-project ./MyApp.sln
  ```
  Naturalnie: *„Przeanalizuj architekturę całego solution pod kątem SOLID i Clean Architecture."*

### `/refactor-module [ścieżka|nazwa]`
Analiza **mezo** modułu / feature / folderu.
- **Subagent:** `refactor-analyzer` · **Skill:** `analyze-module`
- **Output:** `analysis-report.md` (Zakres: Mezo) → **GATE 1**
- **Przykłady:**
  ```
  /refactor-module ./src/Billing
  /refactor-module Orders
  ```
  Naturalnie: *„Oceń moduł Billing — spójność i zależności."*

### `/refactor-class [NazwaKlasy]`
Analiza **mikro** konkretnej klasy z repozytorium.
- **Subagent:** `refactor-analyzer` · **Skill:** `analyze-snippet`
- **Output:** `analysis-report.md` (Zakres: Mikro) → **GATE 1**
- **Przykłady:**
  ```
  /refactor-class OrderService
  /refactor-class PaymentProcessor
  ```
  Naturalnie: *„Zrefaktoryzuj klasę OrderService."* (start od analizy)

### `/refactor-snippet`
Analiza **mikro** wklejonego fragmentu kodu (bez lokalizowania w repo).
- **Subagent:** `refactor-analyzer` · **Skill:** `analyze-snippet`
- **Output:** `analysis-report.md` (Zakres: Mikro) → **GATE 1**
- **Użycie:** wpisz `/refactor-snippet` i wklej kod w bloku, np.:
  ````
  /refactor-snippet
  ```csharp
  public decimal Calc(Order o) { ... }
  ```
  ````

---

## Komendy sterujące przepływem

### `/refactor-continue`
Kontynuuj od **aktualnego gate'u** po jego akceptacji — przechodzi do kolejnego etapu (lub
kolejnego zadania w ETAPIE 4).
- Po **GATE 1** → ETAP 2 (`refactor-planner` / `plan-refactor`)
- Po **GATE 2** → ETAP 3 (`refactor-test-writer` / `write-tests`)
- Po **GATE 3** → ETAP 4 (`refactor-implementer` / `implement-refactor`)
- Po **GATE 4** → kolejne zadanie lub ETAP 5
- Po **GATE 5** → zamknięcie lub kolejna iteracja
- **Edge case:** brak aktywnego workflowu → komenda przypomina, by zacząć od `/refactor-*` (ETAP 1).

### `/refactor-status`
Pokazuje aktualny **etap**, **gate**, listę wytworzonych artefaktów i — w ETAPIE 4 — postęp zadań
(np. `Zadanie 2/5 done`). Nie zmienia stanu.

### `/refactor-abort`
Przerywa workflow i **zapisuje stan** (dotychczasowe raporty/plan zostają na dysku). Informuje,
jak wznowić (ponowny start etapu lub `/refactor-continue`, jeśli stan na to pozwala).

---

## Pełny przebieg (przykład .NET/C#)

```
1.  /refactor-module ./src/Billing
        → analysis-report.md                ⛔ GATE 1
2.  /refactor-continue
        → refactor-plan.md                  ⛔ GATE 2
3.  /refactor-continue
        → testy baseline + test-baseline-report.md (dotnet test = PASS)  ⛔ GATE 3
4.  /refactor-continue
        → Zadanie 1: diff + dotnet test PASS ⛔ GATE 4
    /refactor-continue
        → Zadanie 2: diff + dotnet test PASS ⛔ GATE 4
    ... (kolejne zadania)
5.  /refactor-continue
        → refactor-review.md                ⛔ GATE 5
    /refactor-continue → zamknięcie (lub kolejna iteracja)
```

W dowolnym momencie: `/refactor-status` (gdzie jestem) · `/refactor-abort` (przerwij i zapisz).

---

## Zasady przy komendach
- Komendy ETAPU 1 **zawsze** kończą się na GATE 1 — analiza nie przechodzi sama do planu.
- `/refactor-continue` **nie** uruchomi ETAPU 4 bez zaakceptowanego planu (GATE 2) — reguła #2.
- Każdy etap zapisuje raport do pliku **i** drukuje podsumowanie w konsoli — reguła #7.
