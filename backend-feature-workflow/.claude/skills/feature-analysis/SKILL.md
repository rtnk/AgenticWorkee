---
name: feature-analysis
description: Load when running the cross-artifact consistency analysis (phase 4.5) of the backend feature workflow — a read-only audit that validates spec.md ↔ plan.md ↔ tasks.md before implementation starts. Defines the requirement-coverage matrix, the classes of defects to detect (orphans, gaps, contradictions, duplicates, untestable criteria, unresolved blockers), and the structured analysis-report format. Used by feature-analyzer.
---

# Feature Analysis — analiza spójności artefaktów

Ten skill definiuje **całościową, read-only analizę** spójności trójki artefaktów
`spec.md ↔ plan.md ↔ tasks.md` przeprowadzaną **po fazie 4, przed fazą 5+**. To
odpowiednik „cross-artifact analysis": nikt wcześniej nie sprawdza holistycznie, czy każde
wymaganie ma pokrycie i czy artefakty się nie kłócą — `feature-verifier` patrzy tylko
**per task**. Ta faza domyka pętlę jakości fazy dokumentacyjnej.

Analiza **niczego nie modyfikuje** — produkuje raport; braki kierują z powrotem do faz 1–4.

Stosuj reguły ze skilla `backend-doc-conventions` (polski, „nie zgaduj", zapis tylko do
`docs/features/<slug>/`).

## Macierz pokrycia wymagań

Rdzeń analizy: prześledź **każde** wymaganie i kryterium ze `spec.md` do `plan.md` i `tasks.md`.

```
| Źródło (spec) | Pozycja planu | Task(i) | Pokrycie testowe (kryteria) | Status |
|---------------|---------------|---------|-----------------------------|--------|
| BR-1          | §2 Domena     | T-004   | T-004 kryt. 1–2             | OK     |
| UC-2          | —             | —       | —                           | LUKA   |
| §6 endpoint X | §1 API        | T-002   | T-002 kryt. 1               | OK     |
```

Źródła do prześledzenia: przypadki użycia (UC-*), reguły biznesowe (BR-*), wysokopoziomowe
kryteria akceptacji (§3), kontrakty API (§6), model danych (§7), bezpieczeństwo (§10),
przepływy/idempotencja (§8), NFR (§4).

## Klasy defektów do wykrycia

1. **Luki pokrycia** — wymaganie/kryterium spec bez pozycji planu lub bez taska.
2. **Sieroty** — task lub pozycja planu bez mapowania do żadnej sekcji spec (potencjalny
   scope creep lub martwa praca).
3. **Sprzeczności** — różne artefakty mówią różne rzeczy (np. spec: 409, plan/task: 422).
4. **Duplikaty** — to samo wymaganie realizowane przez wiele tasków bez powodu.
5. **Niemierzalne kryteria** — kryteria akceptacji taska/spec typu „działa poprawnie".
6. **Nierozwiązane blokady** — `[DO USTALENIA]` w spec, od których zależą taski, mimo
   statusu `ready`; taski `BLOCKED` na ścieżce krytycznej.
7. **Niespójność kolejności** — zależność taska wskazuje na task późniejszy topologicznie.
8. **Naruszenia konstytucji** — plan/tasks łamią zasadę `P-*` (jeśli `docs/constitution.md`
   istnieje): np. nadmiarowa architektura vs P-15/P-16.

## Format raportu (read-only)

```
ANALIZA SPÓJNOŚCI: <slug>
Werdykt: GOTOWE DO IMPLEMENTACJI | WYMAGA POPRAWEK (faza 1–4)

## Macierz pokrycia
<tabela jak wyżej>

## Defekty
- [KRYT.] <klasa> — <opis> — <gdzie: spec §X / plan / T-00x> — <co naprawić i w której fazie>
- [OSTRZ.] <klasa> — <opis> — <gdzie> — <rekomendacja>

## Podsumowanie
- Wymagań prześledzonych: <n>; pokrytych: <n>; luk: <n>
- Tasków: <n>; sierot: <n>; BLOCKED na ścieżce krytycznej: <n>
- Zgodność z konstytucją: OK | naruszenia: <lista P-x>
- Następny krok: <faza 5+ | wróć do fazy 2/3/4 z listą braków>
```

## Reguły

- **Read-only**: czytasz `spec.md`/`plan.md`/`tasks.md` (+ `constitution.md`, kod dla kontekstu);
  **niczego nie zmieniasz**, w tym statusów tasków.
- **Nie zgadujesz**: niejasność = defekt do zgłoszenia, nie domyślne rozstrzygnięcie.
- Werdykt **GOTOWE DO IMPLEMENTACJI** tylko gdy brak defektów `[KRYT.]` i każde wymaganie
  ma pokrycie w tasku z mierzalnym kryterium.
- Każdy defekt ma **adres** (spec §/plan poz./T-00x) i **wskazówkę naprawczą z fazą**.
