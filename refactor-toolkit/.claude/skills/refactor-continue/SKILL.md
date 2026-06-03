---
name: refactor-continue
description: Sterowanie workflowem refaktoryzacji — komenda /refactor-continue. Trigger gdy użytkownik wpisze /refactor-continue lub zaakceptuje aktualny gate i poprosi o przejście dalej. Czyta refactor-state.md i uruchamia kolejny etap (lub kolejne zadanie w ETAPIE 4) przez właściwego subagenta, zatrzymując się na następnym gate'cie.
---

# refactor-continue — przejście do kolejnego etapu po akceptacji gate'u

**Trigger:** użytkownik wpisuje `/refactor-continue` lub akceptuje aktualny gate i prosi o dalej.
To **dyspozytor** workflowu: na podstawie zapisanego stanu wybiera kolejny etap/subagenta.

## Kroki
1. **Wczytaj `refactor-state.md`.** Brak pliku/aktywnego workflowu → poinformuj, że nie ma czego
   kontynuować; zaproponuj start od `/refactor-project|module|class|snippet` (ETAP 1).
2. **Ustal następny krok** wg aktualnego `gate`:
   - po **GATE 1** → ETAP 2: subagent `refactor-planner` (skill `plan-refactor`) → `refactor-plan.md`.
   - po **GATE 2** → ETAP 3: subagent `refactor-test-writer` (skill `write-tests`) → `test-baseline-report.md`.
   - po **GATE 3** → ETAP 4: subagent `refactor-implementer` (skill `implement-refactor`) → pierwsze zadanie.
   - po **GATE 4** → kolejne zadanie z planu; gdy zadania wyczerpane → ETAP 5: subagent
     `refactor-reviewer` (skill `review-refactor`) → `refactor-review.md`.
   - po **GATE 5** → zamknięcie workflowu (skasuj/oznacz `refactor-state.md` jako `zamknięty`) lub
     nowa iteracja, jeśli użytkownik tego chce.
3. **Sprawdź warunek wejścia** etapu (np. ETAP 4 wymaga zaakceptowanego planu — reguła #2; brak →
   STOP i wyjaśnij). Dla ETAPU 4 wymagaj **zielonego** baseline.
4. **Uruchom właściwego subagenta** (przez Task), przekazując potrzebne artefakty.
5. **Zaktualizuj `refactor-state.md`** (nowy `stage`/`gate`, a w ETAPIE 4 numer zadania, np.
   `zadanie 2/5`).

## Format outputu
- Artefakt właściwego etapu (plan / baseline / diff zadania / review) — tworzy subagent.
- Zaktualizowany `refactor-state.md`.
- Konsola: na którym etapie/gate'cie teraz jesteśmy + podsumowanie etapu.

## Obsługa błędów i edge cases
- **Brak aktywnego workflowu** → przypomnij, by zacząć od komendy ETAPU 1.
- **Próba wejścia w ETAP 4 bez zaakceptowanego planu** → STOP (reguła #2).
- **ETAP 4 z czerwonym baseline** → odeślij do ETAPU 3; nie implementuj bez siatki bezpieczeństwa.
- **Niespójny stan** (artefakt brakuje mimo wpisu) → zgłoś, zaproponuj `/refactor-status`.

## Integracja z gate'ami
Po wykonaniu etapu **STOP na jego gate'cie** (GATE 2/3/4/5) i czekaj na akceptację. Po GATE 4
ponowne `/refactor-continue` przechodzi do kolejnego zadania lub do ETAPU 5.
