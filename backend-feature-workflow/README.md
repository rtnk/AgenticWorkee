# backend-feature-workflow

Gotowa-do-skopiowania **paczka artefaktów Claude Code** (skille + subagenci) tworząca powtarzalny
workflow dla zmian w usłudze backendowej pisanej w **.NET 10** — od **dokumentacji** i
**dekompozycji na zadania** (fazy 1–4) aż po **implementację** kolejnych zadań w cyklu TDD
(faza 5+).

Fazy 1–4 produkują dokumentację (`spec.md` → `plan.md` → `tasks.md`) i **nie dotykają kodu**.
Faza 5+ bierze gotowy `tasks.md` i **realizuje zadania, modyfikując kod produkcyjny i testy**
(`src/`, `tests/`) w pętli: testy → implementacja → weryfikacja, aż do spełnienia kryteriów
akceptacji.

> **Uwaga:** to repozytorium (`rtnk/AgenticWorkee`) to meta-repo narzędzi AI. Paczka tu jedynie
> *mieszka*. Dokumenty feature (`spec.md`, `plan.md`, `tasks.md`, `decisions.md`) **nie** powstają
> w tym repo — tworzą się dopiero w **projekcie docelowym** w `docs/features/<slug>/`, po skopiowaniu
> paczki.

## Zawartość

```
backend-feature-workflow/
  README.md
  .claude/
    agents/
      feature-spec-author.md        # faza 1: opis feature -> spec.md (draft)
      feature-spec-refiner.md       # faza 2: interaktywne doprecyzowanie spec.md
      feature-planner.md            # faza 3: spec.md (ready) -> plan.md
      feature-task-decomposer.md    # faza 4: plan.md -> tasks.md
      feature-implementation-orchestrator.md  # faza 5: tasks.md -> implementacja (pętla TDD)
      feature-test-author.md        # faza 5 (RED): kryteria akceptacji -> failujące testy
      feature-implementer.md        # faza 5 (GREEN): minimalny kod produkcyjny
      feature-verifier.md           # faza 5 (BRAMKA): build/test + zgodność ze spec -> PASS/FAIL
    skills/
      backend-doc-conventions/SKILL.md   # wspólne reguły faz 1-4 (język, slug, "nie zgaduj", .NET 10)
      feature-spec/SKILL.md              # szablon specyfikacji (15 sekcji)
      feature-planning/SKILL.md          # szablon plan.md
      feature-tasks/SKILL.md             # szablon tasks.md
      backend-impl-conventions/SKILL.md  # wspólne reguły fazy 5+ (src/+tests/, statusy, "nie zgaduj")
      backend-testing/SKILL.md           # konwencje testów .NET 10 (xUnit, AAA, bramki)
      task-implementation-loop/SKILL.md  # maszyna stanów iteracji jednego taska (TDD)
```

## Instalacja w projekcie .NET 10

Skopiuj katalog `.claude/` z paczki do **roota** docelowego projektu:

```bash
cp -r backend-feature-workflow/.claude <projekt>/
```

Jeśli projekt ma już własny `.claude/`, scal zawartość katalogów `agents/` i `skills/`
(nie nadpisuj istniejących, nazwy są unikalne dla tego workflow).

Po skopiowaniu subagenci i skille są dostępne w sesjach Claude Code uruchamianych w tym projekcie.
Dokumenty będą tworzone w `docs/features/<slug>/` (katalog powstaje automatycznie przy pierwszym
uruchomieniu fazy 1).

## Kolejność użycia

```
feature-spec-author  ->  feature-spec-refiner (iteracyjnie, wiele sesji)  ->  feature-planner  ->  feature-task-decomposer  ->  feature-implementation-orchestrator (faza 5, pętla TDD)
```

| Faza | Subagent | Wejście | Wyjście |
|------|----------|---------|---------|
| 1. Specyfikacja | `feature-spec-author` | opis feature + repo | `docs/features/<slug>/spec.md` (status `draft`) |
| 2. Doprecyzowanie | `feature-spec-refiner` | istniejący `spec.md` | zaktualizowany `spec.md` (+ `decisions.md`), docelowo `ready` |
| 3. Plan | `feature-planner` | `spec.md` w statusie `ready` | `docs/features/<slug>/plan.md` |
| 4. Zadania | `feature-task-decomposer` | `plan.md` (+ `spec.md`) | `docs/features/<slug>/tasks.md` |
| 5+. Implementacja | `feature-implementation-orchestrator` | `tasks.md` (+ `spec.md`, `plan.md`) | kod w `src/`/`tests/` + zaktualizowane statusy w `tasks.md` |

Faza 2 jest **iteracyjna**: uruchamiaj `feature-spec-refiner` wielokrotnie. Za każdym razem zadaje
skupioną porcję pytań, łata sekcje i dopisuje decyzje, aż status spec osiągnie `ready` (brak
jakiegokolwiek `[DO USTALENIA]`). Dopiero wtedy przechodź do fazy 3.

Faza 5+ jest **odrębna jakościowo**: w odróżnieniu od faz 1–4 (które piszą **tylko** do
`docs/features/<slug>/`) **modyfikuje kod produkcyjny i testy** (`src/`, `tests/`) oraz uruchamia
`dotnet build`/`dotnet test`. `feature-implementation-orchestrator` wybiera kolejny wykonalny task
i deleguje cykl TDD do trzech subagentów: **`feature-test-author`** (RED — failujące testy) →
**`feature-implementer`** (GREEN — minimalny kod) → **`feature-verifier`** (bramka build/test +
zgodność ze spec), prowadząc pętlę iteracji wg `task-implementation-loop` aż do PASS. Statusy
zadań przechodzą `do zrobienia → w toku → testy napisane → zaimplementowane → zweryfikowane /
zrobione`; luka decyzyjna lub przekroczony limit iteracji → `BLOCKED` + eskalacja (nigdy domysł).

## Przykładowe polecenia startowe

**Faza 1 — przekazanie opisu feature** (uruchom subagenta `feature-spec-author`):

```
Użyj subagenta feature-spec-author. Opis feature:
"Chcemy dodać dzienne limity wypłat dla kont premium. Po przekroczeniu limitu
wypłata jest odrzucana, a klient dostaje komunikat. Limit konfigurowalny per tier."
```

**Faza 2 — doprecyzowanie** (powtarzaj):

```
Użyj subagenta feature-spec-refiner dla docs/features/withdrawal-limits-premium/spec.md.
```

**Faza 3 — plan:**

```
Użyj subagenta feature-planner dla docs/features/withdrawal-limits-premium/spec.md.
```

**Faza 4 — zadania:**

```
Użyj subagenta feature-task-decomposer dla docs/features/withdrawal-limits-premium/plan.md.
```

**Faza 5+ — implementacja** (modyfikuje `src/` i `tests/`):

```
Użyj subagenta feature-implementation-orchestrator dla docs/features/withdrawal-limits-premium/tasks.md.
```

Aby zrealizować pojedyncze zadanie, wskaż jego ID:

```
Użyj subagenta feature-implementation-orchestrator dla taska T-007 z docs/features/withdrawal-limits-premium/tasks.md.
```

## Zasady przekrojowe (wszystkie artefakty)

- **Dokumenty po polsku**, rzeczowo i bez lania wody; **artefakty narzędziowe po angielsku**
  (frontmatter, nazwy, klucze, ID tasków).
- **„Nie zgaduj — dopytaj.”** Brakujące decyzje są oznaczane `> [DO USTALENIA] ...`, świadome
  uproszczenia `> [ZAŁOŻENIE] ...`. Spec jest `ready` dopiero bez żadnego `[DO USTALENIA]`.
- Każdy subagent ma **wąski zakres** i czyste wejście/wyjście (jedna rola, jeden artefakt).
- **Fazy 1–4** piszą **wyłącznie** do `docs/features/<slug>/` i **nie modyfikują kodu**.
  **Faza 5+** świadomie modyfikuje **`src/` i `tests/`** (uruchamia też `dotnet build`/`test`),
  ale nadal nie zmienia treści `spec.md`/`plan.md`/`tasks.md` poza polem `Status` taska.
- Stos .NET 10 (ASP.NET Core, dispatcher w stylu MediatR, EF Core + MS SQL, opcjonalnie
  Kafka/Redis/YARP/IdentityServer; testy domyślnie xUnit) jest **domyślny, ale potwierdzany
  z repo** (`CLAUDE.md`, istniejący kod, wcześniejsze specy) — nie zakładany na sztywno.
