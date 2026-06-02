---
name: feature-constitution
description: Load when authoring or maintaining the project constitution (docs/constitution.md) for a .NET 10 service — the durable, project-specific, non-negotiable principles that gate every later phase of the backend feature workflow (phase 0). Defines the constitution.md template (principles, tech-stack baseline, layering, testing standards, NFR thresholds, security policy, simplicity/anti-abstraction gates, migration policy) plus rules for amendments. Used by feature-constitution-author; referenced as a gate by feature-planner and feature-verifier.
---

# Feature Constitution — szablon `constitution.md`

Ten skill definiuje **konstytucję projektu** — trwały, **projekt-specyficzny** zbiór
nienaruszalnych zasad, do których odwołują się **wszystkie** fazy workflow (1–5+).
To **faza 0**: powstaje raz na projekt, jest rzadko zmieniana (przez jawną poprawkę), i
**gatuje** plan (`feature-planner`) oraz weryfikację (`feature-verifier`).

Różnica wobec skilli `backend-doc-conventions` / `backend-impl-conventions`: tamte definiują
reguły **samego workflow** (język, idempotencja, role). Konstytucja definiuje reguły **tego
konkretnego repozytorium** (wybrane wzorce, progi, polityki) — to, czego dziś agenci szukają
ad hoc w kodzie przy każdym uruchomieniu.

Stosuj reguły ze skilla `backend-doc-conventions` (polski, „nie zgaduj — dopytaj", notacja
`> [ZAŁOŻENIE]` / `> [DO USTALENIA]`).

## Reguły wypełniania

- Konstytucja wynika z **rzeczywistego repo** (`CLAUDE.md`, kod, `*.csproj`, istniejące specy),
  nie z założeń. Czego nie da się potwierdzić → `> [DO USTALENIA]`, nie zmyślona zasada.
- Zasady są **nienaruszalne**: odchylenie w planie/kodzie wymaga jawnego uzasadnienia (sekcja
  „Complexity Tracking" planu) albo poprawki konstytucji — nie cichego obejścia.
- Każda zasada ma **ID** (`P-1`, `P-2`, …), by plan i verifier mogły się do niej odwołać.
- Lokalizacja: **`docs/constitution.md`** w projekcie docelowym (jedna na repo, nie per feature).
- Zmiana konstytucji to **poprawka** (amendment) z datą i wersją — nie nadpisanie historii.

## Szkielet do skopiowania

````markdown
# Konstytucja projektu: <nazwa usługi>

- **Wersja**: <semver, np. 1.0.0>
- **Data**: <YYYY-MM-DD>
- **Status**: active

## 1. Stos i baseline techniczny
- **.NET**: <wersja, np. .NET 10>
- **Web**: <ASP.NET Core: Minimal API | kontrolery>
- **Dispatcher**: <MediatR-style | inny | brak>
- **Dane**: <EF Core + MS SQL | inne>; migracje: <EF | inne>
- **Async/messaging**: <Kafka | RabbitMQ | brak>
- **Cache/locki**: <Redis | brak>
- **Auth**: <IdentityServer | OpenIddict | JWT | inne>
- **Obserwowalność**: <OpenTelemetry | Serilog | …>

## 2. Zasady architektury (nienaruszalne)
- **P-1 — Warstwy**: <np. API → Application (handlery) → Domain → Infrastructure; zależności
  tylko do wewnątrz>.
- **P-2 — Obsługa błędów**: <Result vs wyjątki — która konwencja i gdzie>.
- **P-3 — Walidacja**: <FluentValidation w pipeline | inne>.
- **P-4 — Naming**: <np. `XxxCommandHandler`, `XxxQuery`, `XxxValidator`>.
- **P-5 — DI / mapowanie**: <konwencje rejestracji, AutoMapper vs ręczne>.

## 3. Standardy testowania (nienaruszalne)
- **P-6 — TDD**: testy przed kodem (faza RED przed GREEN) — patrz `task-implementation-loop`.
- **P-7 — Stack testowy**: <xUnit/NUnit/MSTest; FluentAssertions; Moq/NSubstitute>.
- **P-8 — Bramki**: build czysty + 100% testów zielonych; pokrycie każdego kryterium akceptacji.

## 4. Progi niefunkcjonalne (NFR)
- **P-9 — Wydajność**: <np. p95 < 200 ms dla X>.
- **P-10 — Dostępność / SLA**: <cel>.
- **P-11 — Limity**: <rate limits, rozmiary, timeouty>.

## 5. Bezpieczeństwo (nienaruszalne)
- **P-12 — AuthN/AuthZ**: <wymagany mechanizm, polityki ról/scope>.
- **P-13 — Dane wrażliwe**: <klasyfikacja, szyfrowanie, maskowanie, logowanie>.
- **P-14 — Sekrety**: <gdzie i jak; zakaz w kodzie/logach>.

## 6. Bramka prostoty i anty-abstrakcji
- **P-15 — Prostota**: <np. ≤ N projektów; bez „future-proofing"; YAGNI>.
- **P-16 — Anty-abstrakcja**: <używaj frameworka wprost; nie owijaj bez powodu>.
- **P-17 — Brak duplikacji abstrakcji**: <jedna droga do rzeczy X>.

## 7. Polityka migracji i kompatybilności
- **P-18 — Migracje**: <rozłączne, idempotentne, backward-compatible; brak destrukcyjnych zmian
  bez planu>.
- **P-19 — Kontrakty API/DB**: <wersjonowanie, kompatybilność wsteczna>.

## 8. Poprawki (amendments)
| Wersja | Data | Zmiana | Powód |
|--------|------|--------|-------|
| 1.0.0 | <YYYY-MM-DD> | wersja początkowa | — |
````

## Jak konstytucja gatuje resztę workflow

- **`feature-planner`** sprawdza, czy plan jest zgodny z `P-*`; odchylenie → uzasadnienie w
  sekcji „Complexity Tracking" planu **albo** stop i eskalacja (np. nadmiarowa architektura
  łamie P-15/P-16).
- **`feature-verifier`** dolicza **bramkę zgodności z konstytucją**: implementacja łamiąca
  `P-*` (np. wyjątki zamiast Result, sekret w kodzie, dodatkowy projekt ponad limit) = `FAIL`
  z odwołaniem do konkretnego `P-x`.
- Brak `docs/constitution.md` nie blokuje workflow, ale jest sygnalizowany — wtedy agenci
  wracają do odkrywania konwencji z repo (jak dotychczas).
