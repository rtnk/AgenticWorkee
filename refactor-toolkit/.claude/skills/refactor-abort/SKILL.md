---
name: refactor-abort
description: Sterowanie workflowem refaktoryzacji — komenda /refactor-abort. Trigger gdy użytkownik wpisze /refactor-abort lub poprosi o przerwanie refaktoryzacji. Zatrzymuje workflow, zapisuje aktualny stan i wytworzone artefakty oraz instruuje, jak wznowić. Nie cofa wykonanych zmian w kodzie.
---

# refactor-abort — przerwanie workflowu z zapisem stanu

**Trigger:** użytkownik wpisuje `/refactor-abort` lub prosi o przerwanie/wstrzymanie refaktoryzacji.
Skill **zatrzymuje** workflow i **zapisuje stan**, by dało się wznowić.

## Kroki
1. **Wczytaj `refactor-state.md`.** Brak → poinformuj, że nie ma aktywnego workflowu (nic do przerwania).
2. **Zachowaj artefakty.** Pozostaw na dysku istniejące raporty/plan/baseline/diffy — nie kasuj ich.
3. **Oznacz stan jako przerwany:** zaktualizuj `refactor-state.md` (`status: aborted`, etap/gate, na
   którym przerwano, data). Nie modyfikuj kodu produkcyjnego ani testów.
4. **Podsumuj** co zostało zrobione, które artefakty istnieją i jak wznowić.

## Format outputu
- Zaktualizowany `refactor-state.md` (`status: aborted`).
- Konsola: punkt przerwania + lista zachowanych artefaktów + instrukcja wznowienia.

## Obsługa błędów i edge cases
- **Brak aktywnego workflowu** → komunikat „nic do przerwania".
- **Przerwanie w trakcie ETAPU 4** → jawnie zaznacz, że już zaimplementowane zadania **pozostają**
   w kodzie (abort nie cofa zmian); kolejne zadania nie zostaną wykonane.
- **Użytkownik chce cofnąć zmiany** → to osobna decyzja (np. `git revert`/`git checkout`); abort
   sam z siebie niczego nie cofa — zaznacz to wyraźnie.

## Wznowienie
- Po `aborted` można zacząć od nowa komendą ETAPU 1, albo — jeśli stan i artefakty są spójne —
   wznowić `/refactor-continue` od zapisanego gate'u (najpierw `/refactor-status`, by potwierdzić).

## Integracja z gate'ami
Zatrzymuje workflow poza normalnym przepływem gate'ów; nie przechodzi żadnego gate'u dalej.
