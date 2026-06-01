# Changelog — backend-feature-workflow

Format wg [Keep a Changelog](https://keepachangelog.com/), wersjonowanie semantyczne.

## [1.1.0] — 2026-06-01

Drugi przegląd porównawczy — względem **GSD (Get Shit Done)**: oryginał
[`gsd-build/get-shit-done`](https://github.com/gsd-build/get-shit-done) (zarchiwizowany) oraz
następca [`open-gsd/gsd-core`](https://github.com/open-gsd/gsd-core). Pełne uzasadnienie:
`backend-feature-workflow/REVIEW-GSD.md`. Wdrożono rekomendacje **GSD-1…GSD-12** oraz drobne
obserwacje (§7). Oś usprawnień: **context engineering** (walka z „context rot").

### Dodane
- **Faza 6 — holistyczny przegląd feature** (GSD-6): agent `feature-reviewer` + skill
  `feature-review` (read-only nad całym diffem, klasyfikacja Critical/Warning/Info, raport
  `review.md` z werdyktem `CZYSTE | WYMAGA POPRAWEK`). Samowystarczalny — bez GitHub.
- **Wskaźnik postępu i wznawianie** (GSD-4): agent `feature-progress` + artefakt
  `docs/features/<slug>/state.md` (faza, statusy, **następna komenda**) + podkomenda
  `check-prerequisites.sh progress <slug>`.
- **Lekka ścieżka** dla drobnych zmian (GSD-9): agent `feature-quick` (minimalny `tasks.md` →
  pętla TDD; twardy guardrail: kontakt z kontraktem/modelem/regułą → eskalacja do pełnej ścieżki).
- **Spike techniczny z werdyktem** (GSD-10): agent `feature-spike` (eksperymenty w `spikes/`,
  VALIDATED/INVALIDATED → `research.md`), zasila planera przy wysokim ryzyku.
- **Bramka legalności zależności NuGet** (GSD-7): `scripts/check-packages.sh`
  (`[OK]/[SUS]/[SLOP]`), podpięta w verifierze (`[SLOP]` = FAIL, `[SUS]` = checkpoint).
- **Hooki opt-in** (GSD-11): `.claude/hooks/session-start.sh`, `.claude/hooks/workflow-guard.sh`
  (ADVISORY) + `settings.snippet.json`. Lokalne, bez GitHub.
- **Profile modeli** (GSD-12): pole `model:` w każdym agencie (Haiku/Sonnet/Opus) + tabela profili
  w README.
- **Deterministyczny dowód ukończenia** (GSD-5): opcjonalna linia `- **Verify**:` w tasku
  (proponuje test-author, uruchamia verifier).
- **Pokrycie decyzji** (GSD-8): macierz „Decyzja `D-n` → Plan/Tasks" + klasa defektu
  „decyzja-sierota" w `feature-analysis`/`feature-analyzer`.

### Zmienione
- **Chudy orchestrator** (GSD-2) i **agresywna atomowość** (GSD-1): `task-implementation-loop`,
  `feature-implementation-orchestrator`, `feature-tasks`, `feature-task-decomposer` — orchestrator
  jest dyspozytorem (nie czyta `src/`, streszcza werdykt, stan na dysku → wznawianie), a taski są
  wymiarowane pod świeży kontekst (~½ okna, ≤ ~3 plików; `L` = sygnał podziału).
- **Równoległe fale `[P]`** (GSD-3): orchestrator dispatchuje taski `[P]` o rozłącznych plikach
  równolegle; `feature-analyzer` wykrywa konflikt plików w fali.
- **Werdykt verifiera** rozszerzony do `PASS | WARN | FAIL`; **limit iteracji** konfigurowalny per
  task (`- **Iteration-limit**:`); **flaga `Security-critical: yes`** wymusza bramkę bezpieczeństwa
  (kontrola **inline**, bez zewnętrznych skilli).
- **Wykrywanie cykli** w DAG zależności tasków: `check-prerequisites.sh` (faza impl) + analizator.
- `install.sh` obejmuje katalog `hooks/`; README: nowe fazy/agenci, profile modeli, sekcja o hookach.

### Usunięte
- **`feature-tasks-to-issues`** (eksport tasków do GitHub Issues) — rezygnacja z integracji GitHub.
  Paczka nie używa GitHub w żadnej formie (brak ship/PR/Issues, brak GitHub MCP). Krok `/gsd-ship`
  z GSD świadomie nie ma odpowiednika.

## [1.0.0] — 2026-06-01

Pierwsze wersjonowane wydanie po przeglądzie porównawczym z [GitHub Spec Kit](https://github.com/github/spec-kit)
(`backend-feature-workflow/REVIEW.md`). Wdrożono wszystkie rekomendacje G1–G10.

### Dodane
- **Faza 0 — konstytucja projektu** (G1): skill `feature-constitution` + agent
  `feature-constitution-author` produkujący `docs/constitution.md` (nienaruszalne zasady `P-*`).
- **Faza 4.5 — analiza spójności** (G2): skill `feature-analysis` + agent `feature-analyzer`
  (read-only): macierz pokrycia wymagań spec↔plan↔tasks, wykrywanie luk/sierot/sprzeczności,
  werdykt `GOTOWE DO IMPLEMENTACJI` / `WYMAGA POPRAWEK`.
- **Checklista akceptacji spec** (G4) w skillu `feature-spec`; egzekwowana przez
  `feature-spec-refiner` jako warunek statusu `ready`.
- **Plasterki wertykalne per UC + znacznik `[P]` + oznaczenie `(MVP)`** (G3) w `feature-tasks`
  i `feature-task-decomposer`.
- **Wydzielone artefakty planu** (G5): `contracts/` (OpenAPI/`*.md`), `data-model.md`,
  `research.md`; `feature-planner` je tworzy, `feature-verifier` z nich weryfikuje.
- **Bramka prostoty/konstytucji + sekcja „Complexity Tracking"** w planie (G9).
- **Bramka bezpieczeństwa** dla tasków wrażliwych (auth/dane/sekrety) w fazie 5+ (obserwacja §7).
- **Skrypty deterministyczne** (G6): `.claude/scripts/check-prerequisites.sh`,
  `.claude/scripts/install.sh` (instalator z warstwowaniem, G7).
- **Eksport tasków do GitHub Issues** (G8): agent `feature-tasks-to-issues` (opcjonalny).

### Zmienione
- **Bramka analizy (faza 4.5) ma trwały dowód**: `feature-analyzer` persystuje raport do
  `docs/features/<slug>/analysis.md` z maszynowo czytelnym werdyktem. `check-prerequisites.sh`
  waliduje go dla fazy `impl` (istnienie + werdykt + nieaktualność względem **spec.md, plan.md
  i tasks.md** — zmiana któregokolwiek wejścia wymusza nową analizę). Orchestrator traktuje
  brak/nieaktualność analizy jako **odzyskiwalny** krok (sam uruchamia analizator i ponawia
  check) przed generycznym stopem na pozostałych brakach — bez „utykania" (feedback z review PR #3).
- `check-prerequisites.sh`: walidacja `--phase` (literówka = błąd użycia), twarda bramka buildu
  dla `impl` (brak `dotnet` przy wymaganym buildzie = FAIL; `--no-build` do świadomego pominięcia).
- `install.sh`: usunięto `cp -n` (zbędne — istniejące pliki i tak pomijamy jawnie; eliminuje
  nieportowalne ostrzeżenie GNU coreutils ≥9.4).
- Limit iteracji pętli TDD ujednolicony do **domyślnie 4** (zakres 3–5 wg złożoności).
- `feature-verifier` doliczył bramki **zgodności z konstytucją** i **bezpieczeństwa**.
- `backend-doc-conventions` / `backend-impl-conventions`: konstytucja jako **nadrzędne** źródło
  zasad; zaktualizowany układ plików `docs/`.
- README paczki: nowe fazy 0 i 4.5, doprecyzowany zakres .NET-only i ścieżka rozszerzenia (G10).
