---
name: backend-impl-conventions
description: Load for any backend feature IMPLEMENTATION work (phase 5+ of the workflow) in a .NET 10 service. Implementation counterpart of backend-doc-conventions. Defines what may be changed (src/ and tests/ in the target project, running build/test), how to read repo conventions before coding, scope boundaries, the "don't guess — block & escalate" rule, the extended tasks.md status machine, and commit/idempotency discipline. Loaded first by feature-implementation-orchestrator, feature-test-author, feature-implementer and feature-verifier.
---

# Backend Impl Conventions (wspólne reguły fazy implementacyjnej)

Ten skill definiuje **wspólne** zasady obowiązujące we wszystkich agentach fazy
implementacyjnej (5+): orchestrator → autor testów → implementer → weryfikator.
Każdy agent fazy 5+ ładuje go **jako pierwszy**.

To implementacyjny odpowiednik `backend-doc-conventions`. **Kluczowa różnica wobec
faz 1–4:** w fazie 5+ agenci **wolno modyfikować kod produkcyjny i testy** oraz
uruchamiać kompilację i testy. Wszystkie pozostałe reguły dyscypliny (język,
„nie zgaduj", idempotentność, wąskie role) obowiązują nadal.

## 1. Co wolno, a czego nie

- **Wolno**:
  - tworzyć i modyfikować pliki w **`src/`** (kod produkcyjny) i **`tests/`** projektu
    docelowego, w zakresie aktualnie realizowanego taska;
  - uruchamiać **`dotnet build`** i **`dotnet test`** (oraz pomocnicze `dotnet`/CLI repo);
  - aktualizować **status** zadania w `docs/features/<slug>/tasks.md`;
  - tworzyć **commit per task** (jeśli orchestrator/użytkownik tego oczekuje).
- **Nie wolno**:
  - zmieniać `spec.md`/`plan.md`/`tasks.md` poza polem **Status** taska (treść
    decyzyjna należy do faz 1–4);
  - dotykać kodu, konfiguracji ani migracji **spoza zakresu** wybranego taska;
  - podejmować decyzji projektowych nieobecnych w `spec.md`/`tasks.md` — patrz §4.

## 2. Czytaj konwencje repo PRZED kodowaniem

Nie zakładaj stosu na sztywno. Zanim napiszesz pierwszy test lub linię kodu:

1. Przeczytaj `CLAUDE.md` / `README.md` / `docs/` w roocie — źródło prawdy o wzorcach.
2. Poznaj układ `src/` i projektów `*.csproj` (warstwy API / Application / Domain /
   Infrastructure, namespacy, target framework, referencje).
3. Wychwyć istniejące wzorce: **Result vs wyjątki**, naming handlerów (np.
   `XxxCommandHandler`), walidacja (FluentValidation?), mapowanie, DI.
4. Poznaj **styl testów**: framework (xUnit/NUnit/MSTest), asercje (FluentAssertions?),
   mocki (Moq/NSubstitute), układ projektów `*.Tests`, konwencje nazewnictwa.
5. Zajrzyj do `spec.md` i `plan.md` feature — to one definiują kontrakty, model danych,
   reguły, bezpieczeństwo, których kod musi dotrzymać.

To, czego nie da się potwierdzić z repo/spec, **nigdy** nie jest zgadywane — patrz §4.

## 3. Granice zakresu

- Realizujesz **TYLKO** wybrany task, w obrębie tego, co opisuje `spec.md`.
- Implementacja **minimalna**: tyle kodu, ile potrzeba, by spełnić kryteria akceptacji
  taska i przejść testy. Bez „przy okazji" refaktorów, dodatkowych funkcji ani zmian
  poza plikami wskazanymi przez task (pole „Obszar kodu / pliki" to wskazówka, nie
  pozwolenie na rozszerzanie zakresu).
- Jeśli realizacja taska wymaga zmian, których task nie obejmuje → to sygnał, że task
  jest źle pocięty: zatrzymaj się i eskaluj (nie poszerzaj zakresu po cichu).

## 4. „Nie zgaduj — blokuj i eskaluj"

Najważniejsza reguła, przeniesiona z faz 1–4 do świata kodu.

- Gdy do realizacji taska brakuje **decyzji projektowej** (kontrakt, reguła, format,
  zachowanie brzegowe), a `spec.md`/`tasks.md` o niej milczą lub są sprzeczne — **nie
  wymyślaj** odpowiedzi.
- Ustaw status taska na **`BLOCKED (przez: <opis luki / [DO USTALENIA] #X>)`** i
  **eskaluj do człowieka** (pytanie z konkretną luką i opcjami). Nie dotykaj kodu
  produkcyjnego „na próbę".
- Drobny, bezpieczny brak (np. nazwa pola spójna z istniejącą konwencją repo) możesz
  przyjąć jako jawne `[ZAŁOŻENIE]` w podsumowaniu — ale **wszystko, co zmienia
  kontrakt, model danych lub regułę biznesową, jest decyzją projektową** i podlega
  blokadzie, nie domysłowi.

## 5. Notacja statusów w `tasks.md` (rozszerzenie `feature-tasks`)

Faza 4 ustawia tylko `do zrobienia | BLOCKED`. Faza 5+ rozszerza maszynę stanów
(kompatybilnie wstecz — wartości to artefakt narzędziowy, **po angielsku**):

```
do zrobienia → w toku → testy napisane → zaimplementowane → zweryfikowane / zrobione
                                                              (BLOCKED — w dowolnym momencie)
```

| Status | Znaczenie | Kto ustawia |
|--------|-----------|-------------|
| `do zrobienia` | gotowy do podjęcia (stan z fazy 4) | task-decomposer |
| `w toku` | orchestrator wybrał task, cykl wystartował | orchestrator |
| `testy napisane` | faza RED gotowa: testy istnieją i failują z właściwego powodu | orchestrator (po test-author) |
| `zaimplementowane` | faza GREEN: kod gotowy, build czysty, testy zielone | orchestrator (po implementer) |
| `zweryfikowane / zrobione` | verifier orzekł PASS (kryteria + zgodność ze spec) | orchestrator (po verifier) |
| `BLOCKED (przez: ...)` | luka decyzyjna lub przekroczony limit iteracji → eskalacja | dowolny agent |

Status edytuje **wyłącznie** orchestrator (subagenci raportują wynik; orchestrator
przepisuje pole **Status** w `tasks.md`). Edycja jest punktowa — zmienia tylko jedną
linię `- **Status**: ...`, nic poza nią.

## 6. Dyscyplina commitów i idempotentność

- **Commit per task** (jeśli włączone): jeden zrealizowany task = jeden commit z jasnym
  opisem, np. `feat(<slug>): T-007 walidacja limitu wypłaty`. Commit obejmuje kod, testy
  i aktualizację statusu w `tasks.md`.
- **Idempotentność**: ponowne uruchomienie na tym samym tasku **nie duplikuje** pracy
  ani testów. Przed pisaniem sprawdź, czy testy/kod już istnieją (po nazwach klas/metod
  i obszarze kodu z taska) i **aktualizuj** zamiast doklejać kopie. Task w statusie
  `zweryfikowane / zrobione` jest pomijany.
- Nie usuwaj cudzego kodu ani testów bez wyraźnej potrzeby wynikającej z taska; przy
  konflikcie z istniejącym kodem — zatrzymaj się i eskaluj.
