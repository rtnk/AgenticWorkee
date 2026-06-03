---
name: refactor-status
description: Sterowanie workflowem refaktoryzacji — komenda /refactor-status. Trigger gdy użytkownik wpisze /refactor-status lub zapyta, na którym etapie jest refaktoryzacja. Czyta refactor-state.md i artefakty, po czym raportuje aktualny etap, gate, postęp zadań i listę wygenerowanych plików. Nie zmienia stanu.
---

# refactor-status — stan i postęp workflowu

**Trigger:** użytkownik wpisuje `/refactor-status` lub pyta „na którym etapie jesteśmy / co dalej".
Skill **tylko raportuje** — niczego nie uruchamia ani nie zmienia.

## Kroki
1. **Wczytaj `refactor-state.md`.** Brak → poinformuj, że workflow nie jest aktywny; podpowiedz
   start od `/refactor-project|module|class|snippet`.
2. **Zbierz fakty:** aktualny `stage` i `gate`, zakres (Macro/Mezo/Mikro), cel (ścieżka/moduł/klasa),
   w ETAPIE 4 postęp zadań (np. `zadanie 2/5`).
3. **Sprawdź obecność artefaktów:** `analysis-report.md`, `refactor-plan.md`,
   `test-baseline-report.md`, `refactor-review.md` — zaznacz, które istnieją.
4. **Wskaż następny krok** (zwykle: zaakceptuj gate → `/refactor-continue`).

## Format outputu
Konsola (zwięzła tabela/lista), np.:
```
Workflow refaktoryzacji — STATUS
Zakres:      Mezo — ./src/Billing
Etap:        4/5 — Implementacja
Gate:        GATE 4 (po zadaniu 2/5)
Artefakty:   analysis-report.md ✓ | refactor-plan.md ✓ | test-baseline-report.md ✓ | refactor-review.md ✗
Następny krok: zaakceptuj GATE 4 → /refactor-continue (zadanie 3/5)
```
(Opcjonalnie zapis tego samego podsumowania nie jest wymagany — stan żyje w `refactor-state.md`.)

## Obsługa błędów i edge cases
- **Brak `refactor-state.md`** → „brak aktywnego workflowu" + jak zacząć.
- **Stan niespójny z artefaktami** (np. wpis GATE 3, brak baseline) → zaznacz rozbieżność i
   zaproponuj naprawę (powtórzenie etapu) lub `/refactor-abort`.

## Integracja z gate'ami
Read-only — nie przechodzi żadnego gate'u; jedynie pokazuje, na którym gate'cie stoi workflow.
