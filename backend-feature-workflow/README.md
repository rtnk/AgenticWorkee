# backend-feature-workflow

**Wersja: 1.0.0** (zob. `CHANGELOG.md`).

Gotowa-do-skopiowania **paczka artefaktów Claude Code** (skille + subagenci) tworząca powtarzalny
workflow dla zmian w usłudze backendowej pisanej w **.NET 10** — od **konstytucji projektu**
(faza 0), przez **dokumentację** i **dekompozycję na zadania** (fazy 1–4) oraz **analizę
spójności** (faza 4.5), aż po **implementację** kolejnych zadań w cyklu TDD (faza 5+).

Faza 0 ustala raz na projekt nienaruszalne zasady (`docs/constitution.md`). Fazy 1–4 produkują
dokumentację (`spec.md` → `plan.md` → `tasks.md`) i **nie dotykają kodu**. Faza 4.5
(`feature-analyzer`, read-only) sprawdza całościową spójność spec↔plan↔tasks przed implementacją.
Faza 5+ bierze gotowy `tasks.md` i **realizuje zadania, modyfikując kod produkcyjny i testy**
(`src/`, `tests/`) w pętli: testy → implementacja → weryfikacja, aż do spełnienia kryteriów
akceptacji.

> **Zakres:** paczka jest świadomie wyspecjalizowana w **backendzie .NET 10** (specjalizacja =
> jakość). Aby użyć jej dla innego stosu/frontu, podmień skille konwencji (`backend-*-conventions`,
> `backend-testing`) i szablony, zachowując strukturę faz, ról i bramek.

> **Uwaga:** to repozytorium (`rtnk/AgenticWorkee`) to meta-repo narzędzi AI. Paczka tu jedynie
> *mieszka*. Dokumenty feature (`spec.md`, `plan.md`, `tasks.md`, `decisions.md`) **nie** powstają
> w tym repo — tworzą się dopiero w **projekcie docelowym** w `docs/features/<slug>/`, po skopiowaniu
> paczki.

## Zawartość

```
backend-feature-workflow/
  README.md
  CHANGELOG.md
  REVIEW.md                         # przegląd porównawczy z GitHub Spec Kit
  .claude/
    agents/
      feature-constitution-author.md # faza 0: nienaruszalne zasady -> docs/constitution.md
      feature-spec-author.md        # faza 1: opis feature -> spec.md (draft)
      feature-spec-refiner.md       # faza 2: interaktywne doprecyzowanie spec.md (+ checklista)
      feature-planner.md            # faza 3: spec.md (ready) -> plan.md (+ contracts/, data-model.md)
      feature-task-decomposer.md    # faza 4: plan.md -> tasks.md (plasterki UC, [P], MVP)
      feature-analyzer.md           # faza 4.5: read-only analiza spójności spec<->plan<->tasks
      feature-implementation-orchestrator.md  # faza 5: tasks.md -> implementacja (pętla TDD)
      feature-test-author.md        # faza 5 (RED): kryteria akceptacji -> failujące testy
      feature-implementer.md        # faza 5 (GREEN): minimalny kod produkcyjny
      feature-verifier.md           # faza 5 (BRAMKA): build/test + spec + konstytucja -> PASS/FAIL
      feature-tasks-to-issues.md    # opcjonalnie: tasks.md -> GitHub Issues
    skills/
      feature-constitution/SKILL.md      # faza 0: szablon docs/constitution.md (zasady P-*)
      backend-doc-conventions/SKILL.md   # wspólne reguły faz 1-4 (język, slug, "nie zgaduj", .NET 10)
      feature-spec/SKILL.md              # szablon specyfikacji (15 sekcji) + checklista akceptacji
      feature-planning/SKILL.md          # szablon plan.md + Complexity Tracking + wydzielone artefakty
      feature-tasks/SKILL.md             # szablon tasks.md (plasterki UC, [P], MVP)
      feature-analysis/SKILL.md          # faza 4.5: macierz pokrycia + klasy defektów + raport
      backend-impl-conventions/SKILL.md  # wspólne reguły fazy 5+ (src/+tests/, statusy, bezpieczeństwo)
      backend-testing/SKILL.md           # konwencje testów .NET 10 (xUnit, AAA, bramki)
      task-implementation-loop/SKILL.md  # maszyna stanów iteracji jednego taska (TDD)
    scripts/
      check-prerequisites.sh             # deterministyczna walidacja prerekwizytów faz
      install.sh                         # instalator paczki do projektu (warstwowanie)
```

## Instalacja w projekcie .NET 10

Najprościej — instalatorem (kopiuje agentów, skille i skrypty, **nie nadpisując** istniejących):

```bash
backend-feature-workflow/.claude/scripts/install.sh <projekt>
# nadpisanie plików paczki: FORCE=1 backend-feature-workflow/.claude/scripts/install.sh <projekt>
```

Albo ręcznie:

```bash
cp -r backend-feature-workflow/.claude <projekt>/
```

**Warstwowanie / personalizacja:** instalator domyślnie **nie nadpisuje** plików o tej samej
nazwie — więc **projekt-lokalny agent/skill o tej samej nazwie wygrywa** nad wersją z paczki
(personalizacja bez forka). Aby zaktualizować pliki paczki do nowej wersji, użyj `FORCE=1`.
Jeśli projekt ma już własny `.claude/`, scal katalogi `agents/`/`skills/`/`scripts/`.

Po skopiowaniu subagenci i skille są dostępne w sesjach Claude Code uruchamianych w tym projekcie.
Dokumenty będą tworzone w `docs/features/<slug>/` (katalog powstaje automatycznie przy pierwszym
uruchomieniu fazy 1).

## Kolejność użycia

```
feature-constitution-author (raz na projekt)  ->  feature-spec-author  ->  feature-spec-refiner (iteracyjnie)  ->  feature-planner  ->  feature-task-decomposer  ->  feature-analyzer (bramka)  ->  feature-implementation-orchestrator (faza 5, pętla TDD)
```

| Faza | Subagent | Wejście | Wyjście |
|------|----------|---------|---------|
| 0. Konstytucja (raz/projekt) | `feature-constitution-author` | repo | `docs/constitution.md` (zasady `P-*`) |
| 1. Specyfikacja | `feature-spec-author` | opis feature + repo | `docs/features/<slug>/spec.md` (status `draft`) |
| 2. Doprecyzowanie | `feature-spec-refiner` | istniejący `spec.md` | `spec.md` (+ `decisions.md`), `ready` po zaliczeniu checklisty |
| 3. Plan | `feature-planner` | `spec.md` w statusie `ready` | `plan.md` (+ `contracts/`, `data-model.md`, `research.md`) |
| 4. Zadania | `feature-task-decomposer` | `plan.md` (+ `spec.md`) | `docs/features/<slug>/tasks.md` (plasterki UC, `[P]`, MVP) |
| 4.5 Analiza (read-only) | `feature-analyzer` | `spec.md`+`plan.md`+`tasks.md` | raport spójności + werdykt `GOTOWE` / `WYMAGA POPRAWEK` |
| 5+. Implementacja | `feature-implementation-orchestrator` | `tasks.md` (+ `spec.md`, `plan.md`, konstytucja) | kod w `src/`/`tests/` + statusy w `tasks.md` |
| (opc.) Tracking | `feature-tasks-to-issues` | `tasks.md` | GitHub Issues per task (`T-00x`) |

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

**Faza 0 — konstytucja projektu** (raz na projekt; uruchom `feature-constitution-author`):

```
Użyj subagenta feature-constitution-author. Ustal zasady projektu z repo
i zapisz docs/constitution.md.
```

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

**Faza 4.5 — analiza spójności** (read-only, bramka przed implementacją):

```
Użyj subagenta feature-analyzer dla docs/features/withdrawal-limits-premium/.
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
- **Konstytucja jest nadrzędna.** Jeśli istnieje `docs/constitution.md`, jej zasady `P-*` mają
  pierwszeństwo przed domysłem z kodu; plan dokumentuje odstępstwa w „Complexity Tracking",
  a `feature-verifier` egzekwuje zgodność jako twardą bramkę.
- **Bramki jakości:** spec → `ready` dopiero po checklliście akceptacji; `feature-analyzer`
  (faza 4.5) musi zwrócić `GOTOWE DO IMPLEMENTACJI`, zanim ruszy faza 5+.
