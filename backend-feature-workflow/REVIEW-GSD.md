# Review: backend-feature-workflow vs. GSD (Get Shit Done)

Dogłębny, **drugi** przegląd workflow do implementacji nowych funkcjonalności
(`backend-feature-workflow`) — tym razem względem **GSD (Get Shit Done)**. Pierwszy przegląd
(`REVIEW.md`) porównywał z GitHub Spec Kit i dotykał *governance* oraz kompletności artefaktów.
GSD wnosi **inną oś — context engineering** (walka z „context rot"), więc ujawnia inne luki.

- **Data**: 2026-06-01
- **Zakres przeglądu**: 13 subagentów + 10 skilli + skrypty/hooki paczki `backend-feature-workflow`.
- **Punkt odniesienia**:
  - [`gsd-build/get-shit-done`](https://github.com/gsd-build/get-shit-done) — oryginał TÂCHES,
    obecnie **zarchiwizowany** (maintainer nieosiągalny od 2026-04-01);
  - [`open-gsd/gsd-core`](https://github.com/open-gsd/gsd-core) i
    [`open-gsd/get-shit-done-redux`](https://github.com/open-gsd/get-shit-done-redux) — czynny
    następca pod governance Open GSD.

> **Status wdrożenia:** wszystkie rekomendacje **GSD-1…GSD-12** oraz drobne obserwacje (§7) zostały
> zaimplementowane w wersji **1.1.0** (zob. `CHANGELOG.md`). Ten dokument zachowuje pełne
> uzasadnienie i porównanie jako rejestr decyzji.

> **Świadome pominięcie — GitHub.** GSD ma krok `/gsd-ship` (PR) oraz integracje GitHub. Na życzenie
> właściciela paczka **nie używa GitHub w żadnej formie** (brak ship/PR, brak eksportu do Issues —
> usunięto dawny `feature-tasks-to-issues`). Nowe agenty są samowystarczalne i nie sięgają po skille
> z trybem postowania do GitHub. Dlatego ekwiwalent `/gsd-ship` celowo **nie** ma odpowiednika.

---

## 1. Streszczenie wykonawcze

Workflow jest **dojrzały** i w obszarze **dyscypliny dokumentacyjnej i bramek jakości** (konstytucja,
analiza spójności, TDD z separacją ról, niezależny verifier) **dorównuje lub przewyższa GSD**.

GSD bije nas natomiast na osi **context engineering** — jego centralną tezą jest, że jakość modelu
degraduje się, gdy okno kontekstu się zapełnia („context rot"), i całą architekturę podporządkowuje
**świeżym kontekstom per zadanie**. Główne luki, w kolejności wpływu:

1. **Brak budżetu kontekstu / agresywnej atomowości** — taski nie były wymiarowane pod świeży kontekst.
2. **Orchestrator akumulował kontekst** przez całą feature (ryzyko degradacji przy długich listach).
3. **Brak równoległych fal wykonania** — `[P]` istniał, ale wykonanie było czysto sekwencyjne.
4. **Brak trwałego stanu sesji + „co dalej"** — status tylko w `tasks.md`, bez wskaźnika wznawiania.
5. **Brak deterministycznego dowodu ukończenia per task** — kryteria oceniane prozą.
6. **Brak holistycznego przeglądu całej feature** — tylko weryfikacja per-task.
7. **Brak bramki legalności zależności** — ryzyko halucynacji pakietu NuGet.

Reszta: mocne strony (§3), mapa porównawcza (§4), luki z rekomendacjami (§5), mapa drogowa (§6).

---

## 2. Co to za system (GSD, skrót)

GSD to system meta-promptingu/context-engineeringu dla Claude Code. Trzon to **pętla 6 komend**
powtarzana per faza/kamień milowy:

```
/gsd-new-project → /gsd-discuss-phase N → /gsd-plan-phase N → /gsd-execute-phase N
                 → /gsd-verify-work N → /gsd-ship N        (+ /gsd-progress --next)
```

Idee przewodnie: **context rot** → **świeży kontekst 200k per task**; **aggressive atomicity**
(2–3 taski/plan, każdy ~50% okna); **parallel waves** (niezależne plany równolegle); trwałe
artefakty stanu (PROJECT/REQUIREMENTS/ROADMAP/**STATE**/CONTEXT.md) i wznawianie; deterministyczny
`<verify>` per task; `/gsd-code-review` (Critical/Warning/Info); **Registry Safety Gate** (slopcheck
pakietów `[OK]/[SUS]/[SLOP]`); spike z werdyktem VALIDATED/INVALIDATED; hooki; profile modeli.

---

## 3. Mocne strony (gdzie workflow już dorównuje GSD lub go bije)

| Cecha | backend-feature-workflow | GSD |
|------|--------------------------|-----|
| **Konstytucja jako bramka** | `feature-constitution` + egzekucja w plannerze/verifierze | brak trwałych zasad projektu rangą konstytucji |
| **TDD z separacją ról** | RED/GREEN/bramka jako **osobni** subagenci, verifier read-only | execute-phase + post-verifier, mniej rozdzielone role |
| **Analiza spójności 4.5** | macierz pokrycia spec↔plan↔tasks, trwały werdykt | częściowo (plan-checker, decision-coverage), ale bez naszej macierzy |
| **„Nie zgaduj → BLOCKED" w kodzie** | reguła rozszerzona na fazę 5 (eskalacja, nie domysł) | obecne głównie na poziomie planu |
| **Bogaty spec + ADR** | 15-sekcyjny `spec.md` + `decisions.md` (D-n) | lżejszy REQUIREMENTS/CONTEXT |
| **Least-privilege** | tool allowlist per agent (verifier bez Write) | profile modeli, mniej granularny tool-gating |

Te elementy są **wartościowe** — żadna rekomendacja poniżej ich nie narusza.

---

## 4. Mapa porównawcza

| Etap | GSD | backend-feature-workflow | Status |
|------|-----|--------------------------|--------|
| Inicjalizacja/zasady | `/gsd-new-project` | faza 0 konstytucja | ✅ równoważne |
| Decyzje przed planem | `/gsd-discuss-phase` | spec-refiner (sesyjny) + `decisions.md` | ✅ równoważne |
| Spike/feasibility | `/gsd-spike` (VALIDATED/INVALIDATED) | *(inline w planie)* | ❌ luka GSD-10 |
| Plan + atomowość | `/gsd-plan-phase` (2–3 taski/plan, ~50% okna) | plan + tasks (bez budżetu kontekstu) | ❌ luka GSD-1 |
| Wykonanie | `/gsd-execute-phase` (świeży kontekst, **fale**) | orchestrator (sekwencyjny, akumuluje kontekst) | ❌ luki GSD-2, GSD-3 |
| Dowód ukończenia | `<verify>cmd</verify>` per task | kryteria prozą → testy | ⚠️ luka GSD-5 |
| Przegląd kodu | `/gsd-code-review` (C/W/I, `--fix`/`--auto`) | tylko verifier per-task | ❌ luka GSD-6 |
| Legalność zależności | Registry Safety Gate (slopcheck) | *(brak)* | ❌ luka GSD-7 |
| Pokrycie decyzji | Decision Coverage Gate (D-01…) | ADR bez egzekucji pokrycia | ⚠️ luka GSD-8 |
| Stan/wznawianie | STATE.md, `/gsd-progress --next`, resume | status tylko w `tasks.md` | ❌ luka GSD-4 |
| Szybka ścieżka | `/gsd-quick` | *(pełna ścieżka zawsze)* | ⚠️ luka GSD-9 |
| Hooki | SessionStart, PreToolUse guard | allowlisty + proza | ⚠️ luka GSD-11 |
| Profile modeli | budget/balanced/quality | agenci bez `model:` | ⚠️ luka GSD-12 |
| Ship | `/gsd-ship` (PR) | commit-per-task | ⛔ świadomie pominięte (brak GitHub) |

---

## 5. Luki i rekomendacje (GSD-1…GSD-12)

### GSD-1. Budżet kontekstu / agresywna atomowość *(wysoki)*
**Obserwacja.** GSD wymiaruje taski pod świeży kontekst (2–3/plan, ~½ okna), bo „task 50. ma mieć
jakość taska 1.". U nas rozmiar S/M/L był opcjonalny, bez progu kontekstu.
**Rekomendacja (wdrożona).** `feature-tasks` + `feature-task-decomposer`: heurystyka — task musi
zmieścić testy+kod+build+commit w jednym świeżym kontekście (~½ okna, ≤ ~3 plików); `L` = sygnał
podziału.

### GSD-2. Chudy orchestrator (anty-context-rot) *(wysoki)*
**Obserwacja.** Delegacja do subagentów (RED/GREEN/verify) daje świeże konteksty, ale **sam
orchestrator** czytał kontekst i akumulował go przez całą feature.
**Rekomendacja (wdrożona).** `task-implementation-loop` + orchestrator: orchestrator = **dyspozytor**,
nie czyta `src/`, streszcza werdykt do jednej linii, stan trzyma na dysku (`tasks.md` + `state.md`),
więc świeża sesja wznawia bez stanu w pamięci.

### GSD-3. Równoległe fale wykonania *(średni)*
**Obserwacja.** GSD grupuje niezależne plany w fale i odpala równolegle. `[P]` u nas było martwym znacznikiem.
**Rekomendacja (wdrożona).** Orchestrator może dispatchować RED/GREEN tasków `[P]` o **rozłącznych
plikach** równolegle (weryfikacja/commit serializowane). Analizator 4.5 wykrywa konflikt plików w fali.

### GSD-4. Trwały stan sesji + „co dalej" + wznawianie *(wysoki)*
**Obserwacja.** GSD ma STATE.md i `/gsd-progress --next`. U nas — tylko statusy w `tasks.md`.
**Rekomendacja (wdrożona).** Artefakt `docs/features/<slug>/state.md` (faza, statusy, **następna
komenda**, BLOCKED, notatka) + agent **`feature-progress`** + podkomenda `check-prerequisites.sh progress <slug>`.

### GSD-5. Deterministyczny dowód ukończenia per task *(średni)*
**Obserwacja.** GSD wkleja `<verify>cmd</verify>` w task. U nas kryteria były oceniane prozą.
**Rekomendacja (wdrożona).** Opcjonalna linia `- **Verify**: <komenda>` w tasku; autor testów ją
proponuje, verifier uruchamia jako twardy dowód.

### GSD-6. Holistyczny przegląd całej feature *(wysoki)*
**Obserwacja.** GSD ma `/gsd-code-review` (Critical/Warning/Info). U nas weryfikacja była tylko per-task.
**Rekomendacja (wdrożona).** Faza 6: agent **`feature-reviewer`** + skill `feature-review` —
read-only nad całym diffem, klasyfikacja C/W/I, raport `review.md` z werdyktem `CZYSTE | WYMAGA
POPRAWEK`. **Samowystarczalny** (bez wbudowanych skilli, bez GitHub).

### GSD-7. Bramka legalności zależności (NuGet slopcheck) *(średni)*
**Obserwacja.** GSD blokuje halucynowane pakiety (`[OK]/[SUS]/[SLOP]`). U nas nic nie chroniło przed
wymyślonym `PackageReference`.
**Rekomendacja (wdrożona).** Skrypt `check-packages.sh` (resolve z feedu) + sub-bramka w verifierze:
`[SLOP]` = FAIL, `[SUS]` = checkpoint do potwierdzenia.

### GSD-8. Bramka pokrycia decyzji *(średni)*
**Obserwacja.** GSD śledzi, czy decyzje (D-01…) przeżywają discuss→plan→kod. Mamy `decisions.md`, ale
nic nie egzekwowało ich pokrycia.
**Rekomendacja (wdrożona).** Stabilne ID `D-<n>`; `feature-analysis`/`feature-analyzer` dodają macierz
„Decyzja → Plan/Tasks" i klasę defektu „decyzja-sierota".

### GSD-9. Lekka ścieżka dla drobnych zmian *(średni)*
**Obserwacja.** GSD ma `/gsd-quick`. U nas każda zmiana szła pełnym spec→plan→tasks→analiza.
**Rekomendacja (wdrożona).** Agent **`feature-quick`**: minimalny `tasks.md` (1–2 taski) prosto do
pętli TDD, **o ile** zmiana nie dotyka kontraktu/modelu/reguły/bezpieczeństwa — inaczej STOP +
eskalacja do pełnej ścieżki (guardrail mocniejszy niż w GSD).

### GSD-10. Spike techniczny z werdyktem *(niski/średni)*
**Obserwacja.** GSD `/gsd-spike`: hipoteza + kod + VALIDATED/INVALIDATED przed planem.
**Rekomendacja (wdrożona).** Agent **`feature-spike`** (kod jednorazowy w `spikes/`, uruchamiany),
werdykty do `research.md`, zasila planera przy wysokim ryzyku.

### GSD-11. Hooki egzekwujące fazy *(niski)*
**Obserwacja.** GSD ma SessionStart i PreToolUse guardy. U nas — tylko allowlisty + proza.
**Rekomendacja (wdrożona).** Opt-in hooki w `.claude/hooks/`: `session-start.sh` (walidacja środowiska
+ progres) i `workflow-guard.sh` (ADVISORY: ostrzega przy edycji `src/` bez werdyktu 4.5) + snippet
`settings.json`. Lokalne, bez GitHub.

### GSD-12. Profile modeli / routing kosztowy *(niski)*
**Obserwacja.** GSD dobiera modele per grupa agentów (budget/balanced/quality). Nasi agenci nie
deklarowali modelu.
**Rekomendacja (wdrożona).** Pole `model:` w każdym agencie (Haiku: test-author, progress; Sonnet:
implementer, decomposer, quick, spec, orchestrator, spike; Opus: planner, analyzer, verifier,
reviewer, constitution). README: tabela profili jako strojenie.

---

## 6. Priorytetyzowana mapa drogowa

| # | Usprawnienie | Wpływ | Koszt | Priorytet |
|---|--------------|-------|-------|-----------|
| GSD-1 | Budżet kontekstu / atomowość | wysoki | niski | **1** |
| GSD-2 | Chudy orchestrator | wysoki | niski | **2** |
| GSD-4 | Stan sesji + „co dalej" (`feature-progress`, `state.md`) | wysoki | śr. | **3** |
| GSD-6 | Holistyczny przegląd (`feature-reviewer`) | wysoki | śr. | **4** |
| GSD-3 | Równoległe fale `[P]` | śr. | śr. | 5 |
| GSD-5 | Deterministyczny `Verify` per task | śr. | niski | 6 |
| GSD-7 | Bramka legalności NuGet (slopcheck) | śr. | niski | 7 |
| GSD-8 | Pokrycie decyzji (D-n) | śr. | niski | 8 |
| GSD-9 | Lekka ścieżka (`feature-quick`) | śr. | śr. | 9 |
| GSD-10 | Spike z werdyktem (`feature-spike`) | niski-śr. | śr. | 10 |
| GSD-11 | Hooki (opt-in) | niski | niski | 11 |
| GSD-12 | Profile modeli | niski | niski | 12 |

**Rekomendowany pierwszy krok:** GSD-1 + GSD-2 (atomowość + chudy orchestrator) — najtańsze, a
domykają centralną tezę GSD o context engineering. Zaraz po nich GSD-4 (stan/wznawianie) i GSD-6
(przegląd), bo dają największy efekt jakościowy.

---

## 7. Drobne obserwacje techniczne (wdrożone)

- **Werdykt verifiera** rozszerzony do `PASS | WARN | FAIL` (spójnie z klasyfikacją code-review).
- **Limit iteracji** konfigurowalny per task (`- **Iteration-limit**:`, domyślnie 4).
- **Flaga `Security-critical: yes`** czyni bramkę bezpieczeństwa obowiązkową (zamiast „inferowania").
- **Wykrywanie cykli** w DAG zależności tasków: `check-prerequisites.sh` + analizator (`[KRYT.]`).
- **Bezpieczeństwo i przegląd** są **inline / samowystarczalne** — bez wbudowanych skilli z trybem
  GitHub (`code-review --comment`, `security-review`), zgodnie z polityką „bez GitHub".

---

## Źródła

- [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done) (zarchiwizowany)
- [open-gsd/gsd-core](https://github.com/open-gsd/gsd-core)
- [open-gsd/get-shit-done-redux](https://github.com/open-gsd/get-shit-done-redux) — `docs/COMMANDS.md`, `docs/USER-GUIDE.md`
- [Open GSD — opengsd.net](https://www.opengsd.net/)
- [get-shit-done/docs/USER-GUIDE.md](https://github.com/gsd-build/get-shit-done/blob/main/docs/USER-GUIDE.md)
