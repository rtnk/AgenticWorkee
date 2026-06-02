# backend-feature-workflow

**Wersja: 1.1.0** (zob. `CHANGELOG.md`).

Gotowa-do-skopiowania **paczka artefaktów Claude Code** (skille + subagenci) tworząca powtarzalny
workflow dla zmian w usłudze backendowej pisanej w **.NET 10** — od **konstytucji projektu**
(faza 0), przez **dokumentację** i **dekompozycję na zadania** (fazy 1–4) oraz **analizę
spójności** (faza 4.5), aż po **implementację** kolejnych zadań w cyklu TDD (faza 5+).

Faza 0 ustala raz na projekt nienaruszalne zasady (`docs/constitution.md`). Fazy 1–4 produkują
dokumentację (`spec.md` → `plan.md` → `tasks.md`) i **nie dotykają kodu**. Faza 4.5
(`feature-analyzer`, read-only) sprawdza całościową spójność spec↔plan↔tasks przed implementacją.
Faza 5+ bierze gotowy `tasks.md` i **realizuje zadania, modyfikując kod produkcyjny i testy**
(`src/`, `tests/`) w pętli: testy → implementacja → weryfikacja, aż do spełnienia kryteriów
akceptacji. Faza 6 (`feature-reviewer`, read-only) robi **holistyczny przegląd całej feature**.

> **Wpływ przeglądu z GSD (wersja 1.1.0).** Po przeglądzie względem
> [GSD](https://github.com/open-gsd/gsd-core) (zob. [`REVIEW-GSD.md`](REVIEW-GSD.md)) dodano oś
> **context engineering**: agresywną atomowość (budżet kontekstu per task), chudy orchestrator
> wznawialny ze stanu na dysku, równoległe fale `[P]`, trwały `state.md` + `feature-progress`,
> deterministyczny `Verify` per task, fazę 6 przeglądu, bramkę legalności pakietów NuGet, lekką
> ścieżkę `feature-quick`, spike z werdyktem i profile modeli. **Paczka nie używa GitHub** —
> ekwiwalent `/gsd-ship` celowo pominięto, a dawny eksport do Issues usunięto.

> **Zakres:** paczka jest świadomie wyspecjalizowana w **backendzie .NET 10** (specjalizacja =
> jakość). Aby użyć jej dla innego stosu/frontu, podmień skille konwencji (`backend-*-conventions`,
> `backend-testing`) i szablony, zachowując strukturę faz, ról i bramek.

> **Uwaga:** to repozytorium (`rtnk/AgenticWorkee`) to meta-repo narzędzi AI. Paczka tu jedynie
> *mieszka*. Dokumenty feature (`spec.md`, `plan.md`, `tasks.md`, `decisions.md`) **nie** powstają
> w tym repo — tworzą się dopiero w **projekcie docelowym** w `docs/features/<slug>/`, po skopiowaniu
> paczki.

## Szybki start (nowy feature)

Co uruchamiać po kolei. Komendy wpisujesz w sesji Claude Code w **projekcie docelowym**
(po instalacji paczki — patrz „Instalacja"). `<slug>` to kebab-case nazwy feature.

**Faza 0 — raz na projekt** (potem pomijasz; ewentualne poprawki):

```
Użyj subagenta feature-constitution-author. Ustal zasady projektu z repo i zapisz docs/constitution.md.
```

**Per feature — kolejne kroki:**

1. **Specyfikacja** — `feature-spec-author` (opis → `spec.md`, status `draft`):
   ```
   Użyj subagenta feature-spec-author. Opis feature: "<swobodny opis>"
   ```
2. **Doprecyzowanie** — `feature-spec-refiner`, **iteracyjnie** aż status `ready`
   (brak `[DO USTALENIA]` + zaliczona checklista akceptacji):
   ```
   Użyj subagenta feature-spec-refiner dla docs/features/<slug>/spec.md.
   ```
3. **Plan** — `feature-planner` (`plan.md` + opc. `contracts/`, `data-model.md`):
   ```
   Użyj subagenta feature-planner dla docs/features/<slug>/spec.md.
   ```
4. **Zadania** — `feature-task-decomposer` (`tasks.md`: plasterki per UC, `[P]`, MVP):
   ```
   Użyj subagenta feature-task-decomposer dla docs/features/<slug>/plan.md.
   ```
5. **Analiza (bramka 4.5)** — `feature-analyzer` (→ `analysis.md`; musi dać `GOTOWE DO IMPLEMENTACJI`):
   ```
   Użyj subagenta feature-analyzer dla docs/features/<slug>/.
   ```
6. **Implementacja (faza 5+)** — `feature-implementation-orchestrator` (pętla TDD, modyfikuje `src/`/`tests/`):
   ```
   Użyj subagenta feature-implementation-orchestrator dla docs/features/<slug>/tasks.md.
   ```
   Pojedynczy task: `... dla taska T-007 z docs/features/<slug>/tasks.md.`
7. **Przegląd (faza 6)** — `feature-reviewer` (po wszystkich taskach `zrobione`; → `review.md`,
   werdykt `CZYSTE`):
   ```
   Użyj subagenta feature-reviewer dla docs/features/<slug>/.
   ```

**W każdej chwili** — „gdzie jestem / co dalej": `feature-progress` (czyta artefakty, aktualizuje
`state.md`, podaje następną komendę). **Drobna zmiana** bez pełnej ścieżki: `feature-quick`.
**Wysokie ryzyko techniczne** przed planem: `feature-spike`.

Skrót przepływu:

```
[raz] feature-constitution-author
  └─ 1. feature-spec-author
     └─ 2. feature-spec-refiner   (iteracyjnie → spec ready)
        └─ 3. feature-planner   (opc. feature-spike przy ryzyku)
           └─ 4. feature-task-decomposer
              └─ 4.5 feature-analyzer   (bramka: GOTOWE DO IMPLEMENTACJI)
                 └─ 5+ feature-implementation-orchestrator   (pętla TDD, fale [P])
                    └─ 6. feature-reviewer   (bramka: CZYSTE)
   (wskaźnik: feature-progress → state.md;  drobna zmiana: feature-quick)
```

**Dwie reguły nadrzędne:**
- **Nie zgaduj** — brak decyzji projektowej to `[DO USTALENIA]` (fazy 1–4) lub `BLOCKED` +
  eskalacja (faza 5+), nigdy zmyślony fakt.
- **Nie przeskakuj bramek** — spec musi być `ready` przed planem, a analiza `GOTOWE DO
  IMPLEMENTACJI` przed implementacją (orchestrator sam dośle analizę, jeśli brak/nieaktualna).

## Zawartość

```
backend-feature-workflow/
  README.md
  CHANGELOG.md
  REVIEW.md                         # przegląd porównawczy z GitHub Spec Kit
  REVIEW-GSD.md                     # przegląd porównawczy z GSD (Get Shit Done)
  .claude/
    agents/
      feature-constitution-author.md # faza 0: nienaruszalne zasady -> docs/constitution.md
      feature-spec-author.md        # faza 1: opis feature -> spec.md (draft)
      feature-spec-refiner.md       # faza 2: interaktywne doprecyzowanie spec.md (+ checklista)
      feature-spike.md              # opc.: spike techniczny -> research.md (VALIDATED/INVALIDATED)
      feature-planner.md            # faza 3: spec.md (ready) -> plan.md (+ contracts/, data-model.md)
      feature-task-decomposer.md    # faza 4: plan.md -> tasks.md (plasterki UC, [P], budżet kontekstu)
      feature-analyzer.md           # faza 4.5: analiza spójności spec<->plan<->tasks -> analysis.md (bramka)
      feature-implementation-orchestrator.md  # faza 5: tasks.md -> implementacja (pętla TDD, fale [P])
      feature-test-author.md        # faza 5 (RED): kryteria akceptacji -> failujące testy
      feature-implementer.md        # faza 5 (GREEN): minimalny kod produkcyjny
      feature-verifier.md           # faza 5 (BRAMKA): build/test + spec + konstytucja -> PASS/WARN/FAIL
      feature-reviewer.md           # faza 6: holistyczny przegląd całej feature -> review.md (bramka)
      feature-quick.md              # ścieżka szybka: drobna zmiana -> minimalny tasks.md -> pętla TDD
      feature-progress.md           # wskaźnik "gdzie jestem / co dalej" -> state.md
    skills/
      feature-constitution/SKILL.md      # faza 0: szablon docs/constitution.md (zasady P-*)
      backend-doc-conventions/SKILL.md   # wspólne reguły faz 1-4 (język, slug, "nie zgaduj", .NET 10)
      feature-spec/SKILL.md              # szablon specyfikacji (15 sekcji) + checklista akceptacji
      feature-planning/SKILL.md          # szablon plan.md + Complexity Tracking + wydzielone artefakty
      feature-tasks/SKILL.md             # szablon tasks.md (UC, [P], budżet kontekstu, Verify, statusy)
      feature-analysis/SKILL.md          # faza 4.5: macierz pokrycia (+ decyzje) + klasy defektów + raport
      feature-review/SKILL.md            # faza 6: rubryka przeglądu + klasyfikacja C/W/I + raport
      backend-impl-conventions/SKILL.md  # wspólne reguły fazy 5+ (src/+tests/, statusy, bezp., pakiety)
      backend-testing/SKILL.md           # konwencje testów .NET 10 (xUnit, AAA, bramki)
      task-implementation-loop/SKILL.md  # maszyna stanów iteracji jednego taska (TDD, fale, chudy orchestrator)
    scripts/
      check-prerequisites.sh             # deterministyczna walidacja prerekwizytów + `progress` + cykle DAG
      check-packages.sh                  # bramka legalności pakietów NuGet (slopcheck [OK]/[SUS]/[SLOP])
      install.sh                         # instalator paczki do projektu (warstwowanie)
    hooks/                               # opt-in (scal settings.snippet.json do .claude/settings.json)
      session-start.sh                   # SessionStart: walidacja środowiska + progres feature
      workflow-guard.sh                  # PreToolUse (ADVISORY): ostrzega o edycji src/ bez bramki 4.5
      settings.snippet.json              # gotowy snippet hooków (lokalne, bez GitHub)
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
feature-constitution-author (raz na projekt)  ->  feature-spec-author  ->  feature-spec-refiner (iteracyjnie)  ->  feature-planner  ->  feature-task-decomposer  ->  feature-analyzer (bramka)  ->  feature-implementation-orchestrator (faza 5, pętla TDD)  ->  feature-reviewer (faza 6, bramka)
```

| Faza | Subagent | Wejście | Wyjście |
|------|----------|---------|---------|
| 0. Konstytucja (raz/projekt) | `feature-constitution-author` | repo | `docs/constitution.md` (zasady `P-*`) |
| 1. Specyfikacja | `feature-spec-author` | opis feature + repo | `docs/features/<slug>/spec.md` (status `draft`) |
| 2. Doprecyzowanie | `feature-spec-refiner` | istniejący `spec.md` | `spec.md` (+ `decisions.md`, `D-n`), `ready` po zaliczeniu checklisty |
| (opc.) Spike | `feature-spike` | ryzyko techniczne | `research.md` (werdykty VALIDATED/INVALIDATED) + kod w `spikes/` |
| 3. Plan | `feature-planner` | `spec.md` w statusie `ready` | `plan.md` (+ `contracts/`, `data-model.md`, `research.md`) |
| 4. Zadania | `feature-task-decomposer` | `plan.md` (+ `spec.md`) | `docs/features/<slug>/tasks.md` (UC, `[P]`, budżet kontekstu, `Verify`) |
| 4.5 Analiza (bramka) | `feature-analyzer` | `spec.md`+`plan.md`+`tasks.md` | `docs/features/<slug>/analysis.md` (raport + werdykt `GOTOWE` / `WYMAGA POPRAWEK`) |
| 5+. Implementacja | `feature-implementation-orchestrator` | `tasks.md` (+ `spec.md`, `plan.md`, konstytucja) | kod w `src/`/`tests/` + statusy w `tasks.md` + `state.md` |
| 6. Przegląd (bramka) | `feature-reviewer` | cały diff feature | `docs/features/<slug>/review.md` (C/W/I + werdykt `CZYSTE` / `WYMAGA POPRAWEK`) |
| (w każdej chwili) Wskaźnik | `feature-progress` | artefakty feature | `state.md` + „następna komenda" |
| (zamiast 1–4.5) Szybka ścieżka | `feature-quick` | drobna, zakreślona zmiana | minimalny `tasks.md` → pętla TDD (lub eskalacja do pełnej ścieżki) |

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

## Zmiana specyfikacji w trakcie implementacji

Gdy po zrealizowaniu kilku zadań chcesz zmienić coś w `spec.md`, **nie łataj tego wprost w kodzie**.
Zmiana spec to decyzja faz 1–2 — agenci fazy 5 napotkawszy rozbieżność oznaczą task `BLOCKED`
i eskalują („nie zgaduj"), zamiast po cichu zaabsorbować nowy wymóg. Zmianę puszczasz „od góry":

1. **Zmień spec przez doprecyzowanie** (refiner łata sekcje, dopisuje ADR do `decisions.md`,
   pilnuje statusu — przy nowych pytaniach spec wraca do `refining`, aż znów `ready`):
   ```
   Użyj subagenta feature-spec-refiner dla docs/features/<slug>/spec.md. "Zmiana: <co i dlaczego>"
   ```
2. **Przepłyń zmianę w dół** (gdy dotyka architektury/kontraktów/modelu danych — najpierw plan):
   ```
   Użyj subagenta feature-planner dla docs/features/<slug>/spec.md.
   Użyj subagenta feature-task-decomposer dla docs/features/<slug>/plan.md.
   ```
   Dekompozytor jest idempotentny (**ID tasków stałe**): dodaje nowe taski, aktualizuje kryteria
   istniejących, a taski już `zrobione`, którym zmiana **unieważnia kryteria**, ustawia z powrotem
   na `do zrobienia` (faza 4 jest właścicielem treści `tasks.md`).
3. **Uruchom ponownie analizę (bramka 4.5)** — obowiązkowe: edycja `spec.md`/`plan.md`/`tasks.md`
   czyni `analysis.md` **nieaktualnym**, więc faza 5 i tak nie ruszy bez świeżego werdyktu:
   ```
   Użyj subagenta feature-analyzer dla docs/features/<slug>/.
   ```
4. **Wróć do implementacji** — dzięki idempotentności taski wciąż `zweryfikowane / zrobione` są
   pomijane; orchestrator realizuje tylko nowe i ponownie otwarte (a brakującą/nieaktualną analizę
   sam dośle):
   ```
   Użyj subagenta feature-implementation-orchestrator dla docs/features/<slug>/tasks.md.
   ```

**Warianty:**
- **Drobne doprecyzowanie** (nie zmienia kontraktu API, modelu danych ani reguły biznesowej) —
  może wystarczyć refiner + ponowna analiza, bez ruszania planu.
- **Zmiana zasady przekrojowej projektu** (np. „od teraz Result zamiast wyjątków") — to nie spec
  feature, lecz **konstytucja**: zrób poprawkę przez `feature-constitution-author` (bump wersji +
  wpis w „Poprawki"), bo gatuje wszystkie feature.

**Co wymaga Twojej decyzji:** które już ukończone taski zmiana faktycznie unieważnia — analizator
wskaże je jako sprzeczności/luki, ale reopen potwierdzasz Ty. Reszta jest mechaniczna; `commit per
task` sprawia, że re-implementacja dotkniętego zadania jest zlokalizowana i łatwa do prześledzenia.

## Profile modeli (strojenie kosztu/jakości)

Każdy agent deklaruje rekomendowany `model:` we frontmatterze (analog profili GSD). Domyślne
przypisanie (zmień w razie potrzeby — projekt-lokalny agent o tej samej nazwie wygrywa):

| Grupa | Agenci | Domyślny model |
|-------|--------|----------------|
| Mechaniczne | `feature-test-author`, `feature-progress` | **haiku** |
| Wykonawcze | `feature-implementer`, `feature-task-decomposer`, `feature-quick`, `feature-spec-author`, `feature-spec-refiner`, `feature-implementation-orchestrator`, `feature-spike` | **sonnet** |
| Krytyczne dla jakości | `feature-planner`, `feature-analyzer`, `feature-verifier`, `feature-reviewer`, `feature-constitution-author` | **opus** |

Profile á la GSD: **budget** (zbij wszystko o tier niżej), **balanced** (jak wyżej), **quality**
(podbij wykonawcze do opus). Bramki (analyzer/verifier/reviewer) trzymaj na **opus** — to one łapią błędy.

## Hooki (opcjonalnie, opt-in)

W `.claude/hooks/` są **lokalne** hooki (bez GitHub), domyślnie **wyłączone**. Aby je włączyć,
scal `.claude/hooks/settings.snippet.json` do `.claude/settings.json` projektu docelowego:

- **SessionStart** (`session-start.sh`) — waliduje środowisko (`dotnet`, `restore`) i pokazuje
  progres feature ze `state.md` na starcie sesji.
- **PreToolUse / WorkflowGuard** (`workflow-guard.sh`) — **ADVISORY** (nie blokuje): ostrzega, gdy
  edytujesz `src/`, a żadna feature nie ma jeszcze werdyktu bramki 4.5. To uzupełnienie allowlist
  narzędzi agentów faz 1–4 (defense-in-depth).

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
  (faza 4.5) musi zwrócić `GOTOWE DO IMPLEMENTACJI`, zanim ruszy faza 5+; `feature-reviewer`
  (faza 6) zamyka feature werdyktem `CZYSTE`. **Bez GitHub** — krok `ship`/PR i eksport do Issues
  świadomie pominięte (zob. `REVIEW-GSD.md`).
