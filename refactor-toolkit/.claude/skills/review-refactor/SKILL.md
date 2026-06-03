---
name: review-refactor
description: ETAP 5 — read-only przegląd końcowy refaktoryzacji. Weryfikuje realizację celów (SOLID, Clean Architecture, DRY/KISS/YAGNI), porównuje testy przed/po, potwierdza behaviour preservation i spisuje długi techniczne. Trigger — /refactor-continue po zakończeniu ETAPU 4 lub prośba o przegląd refaktoryzacji. Używany przez subagenta refactor-reviewer. Produkuje refactor-review.md i kończy na GATE 5.
---

# review-refactor — przegląd wyników refaktoryzacji

**Trigger:** `/refactor-continue` po ukończeniu wszystkich zadań ETAPU 4, albo prośba o końcowy
przegląd refaktoryzacji. Przegląd jest **read-only** — niczego nie naprawiasz.

Patrzysz całościowo: czy cele spełnione, czy zachowanie nienaruszone, co zostało jako dług.

## Kroki
1. **Wczytaj kontekst:** `analysis-report.md` (cele), `refactor-plan.md` (zadania + wykluczenia),
   `test-baseline-report.md` (stan „przed"), diff zmian (`git diff` względem punktu wyjścia).
2. **Zestaw plan vs wykonanie** — zadania wykonane / pominięte / odłożone.
3. **Oceń realizację celów** per kategoria ze statusem ✅/⚠️/❌ i uzasadnieniem opartym na kodzie:
   SOLID (SRP/OCP/LSP/ISP/DIP), Clean Architecture, DRY/KISS/YAGNI, wzorce.
4. **Testy przed vs po:** uruchom testy ponownie; porównaj liczby passed i policz nowe testy.
   Czerwone testy → werdykt negatywny, nie ogłaszaj sukcesu (reguła z #1/#6).
5. **Behaviour preservation:** potwierdź brak zmian zachowania zewnętrznego LUB wylistuj
   odchylenia (szczególnie: wyjątki — typy/komunikaty/stack trace, kontrakty API, typy zwracane).
   Dla .NET/C# zastosuj checklisty z `dotnet-patterns`.
6. **Długi techniczne:** spisz to, co świadomie poza zakresem (zgodnie z „Co NIE zostanie
   zmienione" + nowe obserwacje) — do kolejnej iteracji.
7. **Zapisz `refactor-review.md`** i wydrukuj werdykt + stan testów w konsoli.

## Format outputu

Plik `refactor-review.md`:

```markdown
# Raport Przeglądu Refaktoryzacji

## Podsumowanie zmian
<lista wykonanych zadań>

## Weryfikacja celów
| Cel | Status | Uwagi |
|-----|--------|-------|
| SOLID - SRP | ✅/⚠️/❌ | |
| SOLID - OCP/LSP/ISP/DIP | | |
| Clean Architecture | | |
| DRY | | |
| KISS | | |
| YAGNI | | |

## Testy — wynik końcowy
- Testy przed: X passed
- Testy po: X passed
- Nowe testy: Y

## Zachowanie zachowania (Behaviour Preservation)
<potwierdzenie lub lista odchyleń>

## Pozostałe długi techniczne
<co poza zakresem — do następnej iteracji>
```

Konsola: werdykt (cele spełnione/częściowo/nie) + `testy: X przed → X po (+Y nowych)`.

## Obsługa błędów i edge cases
- **Brakuje artefaktów** (raport/plan/baseline) → zaznacz, czego brak; przegląd częściowy z
  jawnym ostrzeżeniem.
- **Testy czerwone na końcu** → werdykt negatywny; wskaż failujące testy, odeślij do ETAPU 4.
- **Wykryta regresja zachowania** → udokumentuj jako Critical; nie zamykaj jako sukces.
- **Zadania pominięte** → odnotuj jako dług techniczny, nie „dokańczaj" ich tutaj (read-only).

## Integracja z gate'ami
Końcowe podsumowanie → **STOP na GATE 5**. Poproś o akceptację zamknięcia workflowu (lub
`/refactor-continue` dla kolejnej iteracji). Nie zmieniasz kodu ani testów na tym etapie.
