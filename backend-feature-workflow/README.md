# backend-feature-workflow

Gotowa-do-skopiowania **paczka artefaktów Claude Code** (skille + subagenci) tworząca powtarzalny,
4-fazowy workflow do pracy nad **dokumentacją** i **dekompozycją na zadania** zmian w usłudze
backendowej pisanej w **.NET 10**.

Zakres workflow kończy się na gotowym `tasks.md` — **sama implementacja kodu jest poza zakresem**
tych artefaktów.

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
    skills/
      backend-doc-conventions/SKILL.md   # wspólne reguły (język, slug, "nie zgaduj", .NET 10)
      feature-spec/SKILL.md              # szablon specyfikacji (15 sekcji)
      feature-planning/SKILL.md          # szablon plan.md
      feature-tasks/SKILL.md             # szablon tasks.md
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
feature-spec-author  ->  feature-spec-refiner (iteracyjnie, wiele sesji)  ->  feature-planner  ->  feature-task-decomposer
```

| Faza | Subagent | Wejście | Wyjście |
|------|----------|---------|---------|
| 1. Specyfikacja | `feature-spec-author` | opis feature + repo | `docs/features/<slug>/spec.md` (status `draft`) |
| 2. Doprecyzowanie | `feature-spec-refiner` | istniejący `spec.md` | zaktualizowany `spec.md` (+ `decisions.md`), docelowo `ready` |
| 3. Plan | `feature-planner` | `spec.md` w statusie `ready` | `docs/features/<slug>/plan.md` |
| 4. Zadania | `feature-task-decomposer` | `plan.md` (+ `spec.md`) | `docs/features/<slug>/tasks.md` |

Faza 2 jest **iteracyjna**: uruchamiaj `feature-spec-refiner` wielokrotnie. Za każdym razem zadaje
skupioną porcję pytań, łata sekcje i dopisuje decyzje, aż status spec osiągnie `ready` (brak
jakiegokolwiek `[DO USTALENIA]`). Dopiero wtedy przechodź do fazy 3.

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

## Zasady przekrojowe (wszystkie artefakty)

- **Dokumenty po polsku**, rzeczowo i bez lania wody; **artefakty narzędziowe po angielsku**
  (frontmatter, nazwy, klucze, ID tasków).
- **„Nie zgaduj — dopytaj.”** Brakujące decyzje są oznaczane `> [DO USTALENIA] ...`, świadome
  uproszczenia `> [ZAŁOŻENIE] ...`. Spec jest `ready` dopiero bez żadnego `[DO USTALENIA]`.
- Każdy subagent ma **wąski zakres** i czyste wejście/wyjście (czyta jeden plik, pisze jeden).
- Subagenci **piszą wyłącznie** do `docs/features/<slug>/` i **nie modyfikują kodu produkcyjnego**.
- Stos .NET 10 (ASP.NET Core, dispatcher w stylu MediatR, EF Core + MS SQL, opcjonalnie
  Kafka/Redis/YARP/IdentityServer) jest **domyślny, ale potwierdzany z repo** (`CLAUDE.md`,
  istniejący kod, wcześniejsze specy) — nie zakładany na sztywno.
