---
name: spec-reference
description: Lekka mapa sekcji spec.md dla KONSUMENTÓW specyfikacji w fazie 5+ (implementer, verifier) — w odróżnieniu od autorskiego skilla feature-spec. Daje numerację i zawartość 15 kanonicznych sekcji, by nawigować po istniejącym spec.md (oraz contracts/ / data-model.md, jeśli wydzielone) bez ładowania pełnego szablonu i reguł autorstwa. Used by feature-implementer and feature-verifier.
---

# Spec Reference — mapa sekcji (do czytania, nie pisania)

Ten skill jest dla agentów, którzy **czytają** gotowy `spec.md`, a nie go tworzą.
Pełny szablon, reguły autorstwa i bramka `ready` żyją w `feature-spec` (autorzy) — ich tu nie ma.

**Jak czytać:** otwórz `docs/features/<slug>/spec.md` i sięgaj **tylko po sekcje istotne dla
bieżącego taska** (numery sekcji masz w polach „Powiązania §" taska w `tasks.md`). Jeśli kontrakt
lub model danych wydzielono do `contracts/` / `data-model.md`, porównuj z tymi plikami.

**Ścieżka szybka (`feature-quick`):** gdy `spec.md` **nie istnieje** (`tasks.md` ma nagłówek
`> [ZAŁOŻENIE] ścieżka szybka`), kryteria są **inline** w tasku — opieraj się wyłącznie na nich.

## Mapa 15 sekcji `spec.md`

1. **Metadane** — nazwa, slug, status, powiązane usługi.
2. **Kontekst i cel** — problem, motywacja, zakres / poza zakresem.
3. **Wymagania funkcjonalne** — przypadki użycia `UC-*`, reguły biznesowe `BR-*`, kryteria akceptacji.
4. **Wymagania niefunkcjonalne** — progi wydajności, skalowalność, SLA, limity/kwoty.
5. **Architektura rozwiązania** — komponenty, miejsce zmiany, flowchart.
6. **Kontrakty API** — endpointy/handlery, request/response, kody błędów, walidacja, wersjonowanie.
7. **Model danych** — tabele MS SQL (typy, klucze, NULL), migracje EF, Redis, Kafka.
8. **Przepływy i sekwencje** — diagram sekwencji, przypadki brzegowe, idempotencja, transakcyjność.
9. **Integracje i zależności zewnętrzne** — inne usługi, kolejki/cache, kontrakty zdarzeń, tryb awarii.
10. **Bezpieczeństwo** — authN/authZ, dane wrażliwe, sekrety, audyt.
11. **Obserwowalność** — logi, metryki, trace, alerty.
12. **Wdrożenie i rollback** — feature flags, kompatybilność wsteczna, migracja danych, plan wycofania.
13. **Testowanie** — poziomy (unit/integration/e2e), kluczowe i brzegowe scenariusze.
14. **Ryzyka i otwarte pytania** — `[DO USTALENIA]`, ryzyka.
15. **Decyzje projektowe (ADR)** — `D-n`: kontekst → decyzja → konsekwencje (pełny log w `decisions.md`).

## Co najczęściej sprawdza faza 5+
- **Kontrakty (§6)** i **model danych (§7)** — sygnatury, typy, kody błędów, schemat.
- **Reguły biznesowe (§3, `BR-*`)** — zachowanie i przypadki brzegowe.
- **Przepływy (§8)** — idempotencja, transakcyjność.
- **Bezpieczeństwo (§10)** — authZ, sekrety, dane wrażliwe.
Rozbieżność implementacji z którąkolwiek z tych sekcji = sygnał `FAIL`/blokady, nie domysł.
