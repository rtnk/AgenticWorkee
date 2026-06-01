# Changelog — backend-feature-workflow

Format wg [Keep a Changelog](https://keepachangelog.com/), wersjonowanie semantyczne.

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
- Limit iteracji pętli TDD ujednolicony do **domyślnie 4** (zakres 3–5 wg złożoności).
- `feature-verifier` doliczył bramki **zgodności z konstytucją** i **bezpieczeństwa**.
- `backend-doc-conventions` / `backend-impl-conventions`: konstytucja jako **nadrzędne** źródło
  zasad; zaktualizowany układ plików `docs/`.
- README paczki: nowe fazy 0 i 4.5, doprecyzowany zakres .NET-only i ścieżka rozszerzenia (G10).
</content>
