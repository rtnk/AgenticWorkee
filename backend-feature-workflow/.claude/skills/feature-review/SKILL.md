---
name: feature-review
description: Load when running the holistic code review (phase 6) of the backend feature workflow — a read-only review of the WHOLE feature diff after all tasks are done, before wrapping up. Defines the review rubric (correctness, cross-task coherence, dead code, duplication, security, constitution adherence), the Critical/Warning/Info severity classification, and the structured review-report format persisted to docs/features/<slug>/review.md. Self-contained — no external/built-in skills, no GitHub. Used by feature-reviewer.
---

# Feature Review — holistyczny przegląd całej feature

Ten skill definiuje **read-only przegląd całego diffu feature** (faza 6) — po tym, jak
wszystkie taski są `zweryfikowane / zrobione`. `feature-verifier` patrzy **per task**;
ten przegląd patrzy **całościowo**, na styki między taskami i na jakość kodu jako całości.
Jest **samowystarczalny** — nie korzysta z żadnych zewnętrznych/wbudowanych skilli ani
z GitHub. Zapisuje **wyłącznie** raport `docs/features/<slug>/review.md`; niczego nie naprawia.

Stosuj reguły ze skilla `backend-impl-conventions` (zakres, „nie zgaduj", konstytucja nadrzędna)
oraz `backend-testing` (bramki build/test) — ale tu tylko **czytasz** i orzekasz.

## Zakres przeglądu (cały diff feature)

Bierz pod uwagę **sumę zmian** wszystkich tasków feature (np. `git diff` względem punktu
wyjścia gałęzi, albo commity per task) — nie pojedynczy task.

## Rubryka

1. **Poprawność (całościowa)** — czy złożenie tasków realizuje cel feature ze `spec.md §2`
   i wszystkie kryteria §3; czy nie ma sprzeczności między fragmentami z różnych tasków.
2. **Spójność między-taskowa** — powtarzające się/rozjeżdżające abstrakcje wprowadzone w
   różnych taskach (dwa walidatory tego samego, dwa mapowania, niespójny naming między warstwami).
3. **Martwy/osierocony kod** — kod dodany pod task wcześniejszy, a porzucony po zmianie w
   późniejszym; nieużywane typy/metody/parametry; testy bez asercji.
4. **Duplikacja** — skopiowana logika, którą należało wydzielić; powielone stałe/kontrakty.
5. **Bezpieczeństwo (przekrojowo)** — sekrety w kodzie/logach, braki authZ, niezamaskowane
   dane wrażliwe, niewalidowane wejścia — w skali całej feature (spec §10, `P-12`–`P-14`).
6. **Zgodność z konstytucją** — czy całość respektuje `P-*` (warstwy, Result vs wyjątki,
   prostota P-15/P-16). Odstępstwo bez wpisu w „Complexity Tracking" planu = Critical.
7. **Higiena testów** — czy zestaw testów pokrywa kryteria feature jako całości (nie tylko
   per task), brak testów „na zielono bez asercji", brak pominięć bez uzasadnienia.

## Klasyfikacja wagi (jak `/gsd-code-review`)

- **Critical** — błąd poprawności/bezpieczeństwa, naruszenie konstytucji lub kontraktu spec.
  Blokuje werdykt `CZYSTE`.
- **Warning** — realny dług/ryzyko (duplikacja, martwy kod, słaby test), nie blokuje, ale
  powinien być świadomie zaadresowany lub odnotowany.
- **Info** — drobna obserwacja/sugestia, bez zobowiązania.

## Format raportu (persystowany do `review.md`)

```markdown
# Przegląd feature: <slug>

- **Werdykt**: CZYSTE | WYMAGA POPRAWEK
- **Data**: <YYYY-MM-DD>
- **Zakres**: diff feature (<n> commitów / <n> plików), na podstawie tasks.md (data: <YYYY-MM-DD>)

## Ustalenia
- [Critical] <obszar> — <opis> — <plik:linia / T-00x> — <co naprawić>
- [Warning]  <obszar> — <opis> — <gdzie> — <rekomendacja>
- [Info]     <obszar> — <opis> — <gdzie>

## Podsumowanie
- Critical: <n>; Warning: <n>; Info: <n>
- Zgodność z konstytucją: OK | naruszenia: <lista P-x>
- Pokrycie testowe feature (kryteria §3): OK | luki: <lista>
- Następny krok: <zakończ feature | wróć do fazy 5 dla T-00x | wróć do faz 1–4>
```

- Linia `- **Werdykt**: CZYSTE` jest **kontraktem** — emituj ją dosłownie tylko, gdy brak
  ustaleń `Critical`. Każdy `Critical` ⇒ `WYMAGA POPRAWEK`.
- Raport jest **nieaktualny**, jeśli po jego wygenerowaniu doszły kolejne zmiany w `src/`/`tests/`.

## Reguły

- **Tylko do odczytu** `src/`, `tests/`, artefakty feature. Zapisujesz **wyłącznie** `review.md`
  (idempotentnie). **Niczego nie naprawiasz, nie postujesz nigdzie** (brak GitHub).
- **Nie zgadujesz** — wątpliwość co do intencji spec to ustalenie do zgłoszenia, nie domysł.
- Każde ustalenie ma **adres** (`plik:linia` lub `T-00x`) i wskazówkę naprawczą.
- Werdykt `CZYSTE` tylko przy zerowych `Critical`.
