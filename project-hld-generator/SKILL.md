---
name: project-hld-generator
description: Interactive HLD (High-Level Design) documentation and CLAUDE.md generator for an existing repository. Runs automated repo reconnaissance, then a short interactive Q&A session with the developer (max 5–7 turns), then generates a topical docs/ tree (architecture, integrations, operations, development) plus a token-budgeted CLAUDE.md in the repo root. Use whenever the user asks to generate an HLD, create or update architecture documentation, document the system, produce project documentation from the codebase, create or optimize a CLAUDE.md for a repo, or onboard someone to an existing project — including Polish phrasings like "wygeneruj HLD dla projektu", "stwórz dokumentację architektury", "zrób CLAUDE.md dla tego repo", "onboard mnie do tego projektu", "udokumentuj architekturę systemu", "zrób high-level design" — even when the word "HLD" never appears.
---

# project-hld-generator — interaktywny generator HLD i CLAUDE.md

Działaj jak doświadczony tech lead, który wchodzi do nowego repo: najpierw sam czyta kod,
potem zadaje tylko te pytania, na które kod nie odpowiada, a na końcu zostawia po sobie
dokumentację gotową do commita. Skill jest przeznaczony dla Claude Code (terminal) —
korzysta z narzędzi plikowych (Glob/Grep/Read/Write) i tur konwersacji z deweloperem.

Workflow ma 5 faz w stałej kolejności. Nie pomijaj rekonesansu i nie generuj dokumentacji
przed zakończeniem Q&A — chyba że użytkownik wprost poprosi o pominięcie pytań (wtedy
przejdź na rozsądne założenia i oznacz je w dokumentach jako assumptions).

## Zasady językowe

- **Język treści dokumentacji = język odpowiedzi dewelopera.** Odpowiada po polsku →
  generuj po polsku; po angielsku → po angielsku. Pierwsze pytanie zadaj w języku,
  w którym użytkownik uruchomił skill.
- **Nazwy plików, klucze i wartości YAML frontmatter — zawsze po angielsku**, niezależnie
  od języka treści. Nagłówki sekcji z template'ów (np. `## Open Questions`) zostają po
  angielsku; treść pod nimi w języku dewelopera.

---

## Faza 1 — Automatyczny rekonesans repozytorium

Zanim zadasz jakiekolwiek pytanie, sam wyeksploruj repo. Każde pytanie o coś, co widać
w kodzie, podważa zaufanie dewelopera do wyniku — dlatego ta faza jest obowiązkowa.

Co zbadać (Glob + Read; przy dużym repo próbkuj, nie czytaj wszystkiego):

1. **Pliki konfiguracyjne**: `**/*.csproj`, `*.sln`, `package.json` (+ `workspaces`),
   `go.mod`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `Dockerfile`,
   `docker-compose.yml`, `kubernetes/`, `helm/`, `.github/workflows/`, `Makefile`,
   `*.props`, `.editorconfig`.
2. **Stack technologiczny**: języki, frameworki, biblioteki testowe, lintery, CI/CD —
   z konfigów i lockfile'ów, nie z domysłów.
3. **Struktura katalogów**: zmapuj do **max 3 poziomów głębokości**
   (np. `find . -maxdepth 3 -type d -not -path '*/.git*' -not -path '*/node_modules*'`).
4. **Istniejąca dokumentacja**: `README.md`, `docs/`, `ADR/`, `adr/`, `*.md` w root,
   istniejący `CLAUDE.md`. Zanotuj, co już jest opisane — tego nie wolno nadpisać.
5. **Wzorce architektoniczne z nazewnictwa**: sufiksy projektów/folderów typu `*.Api`,
   `*.Worker`, `*.Domain`, `*.Infrastructure`, `*.Application`, `apps/`/`packages/`
   (monorepo), `cmd/`/`internal/` (Go), `services/` — pozwalają wstępnie odgadnąć
   architekturę (onion/clean, microservices, monolit modułowy).
6. **Sygnały komunikacji i persystencji**: connection stringi i obrazy w
   `docker-compose.yml`/k8s (postgres, kafka, redis...), pakiety klienckie
   (Confluent.Kafka, RabbitMQ.Client, StackExchange.Redis, EF Core, Dapper...).

Wynik fazy: **wstępny model wiedzy** — wypełnij go w pamięci według checklisty z Fazy 2
i oznacz każdą pozycję jako: *wykryte z kodu* / *do potwierdzenia* / *nieznane*.
Pytania formułuj wyłącznie dla pozycji *do potwierdzenia* i *nieznane*.

---

## Faza 2 — Sesja Q&A (interaktywna, turowa)

### Zasady sesji

- Maksymalnie **5–7 tur**, w każdej **1–3 pytania** — nigdy więcej. Deweloper, który
  dostaje ścianę pytań, przestaje odpowiadać rzetelnie.
- Pytania grupuj tematycznie per tura, w stałej kolejności z harmonogramu niżej.
- Pomiń pytania, na które rekonesans już odpowiedział; zamiast pytać — krótko potwierdź
  ustalenie („Z konfigów widzę PostgreSQL + Kafka — przyjmuję, daj znać jeśli błędnie").
  Jeśli po odsianiu w turze zostaje 0 pytań, przejdź do następnej tury.
- Po każdej odpowiedzi zaktualizuj model wiedzy i zdecyduj, czy kolejna tura jest potrzebna.
- Odpowiedź „nie wiem" / „pomiń" → przyjmij rozsądne domyślne założenie, oznacz je później
  w dokumentach jako assumption/TODO i idź dalej. Nie drąż.
- Styl: techniczny, konkretny, bez wstępów i podziękowań. Jedno zdanie kontekstu, potem pytania.
- Pytania zamknięte (np. deployment: k8s / VM / cloud managed) możesz zadać przez
  `AskUserQuestion`, jeśli narzędzie jest dostępne; pytania otwarte zadawaj zwykłym tekstem.

### Harmonogram tur (kolejność stała)

**Tura 1 — Kontekst biznesowy i granice systemu**
- Jaki problem biznesowy rozwiązuje ten system? (1–2 zdania)
- Kto jest konsumentem — użytkownicy końcowi, inne serwisy, zewnętrzne systemy?
- Czy są znane granice systemu (co jest IN scope, co OUT)?

**Tura 2 — Architektura wysokiego poziomu**
- Główne komponenty/serwisy i ich odpowiedzialności (tylko jeśli nie wynika z kodu).
- Jak komponenty się komunikują — sync HTTP/gRPC, async messaging (Kafka/RabbitMQ), shared DB?
- Zewnętrzne dependencje — third-party API, data providers, SSO?

**Tura 3 — Dane i persystencja**
- Jakie bazy/storage i do czego? (zwykle wykryte z konfigów — wtedy tylko potwierdź)
- Krytyczne wymagania spójności danych — eventual consistency, transakcje, outbox?
- Główne agregaty / encje domenowe?

**Tura 4 — NFR i operacje**
- Throughput / latency — rzędy wielkości?
- Deployment — Kubernetes, bare metal, cloud managed?
- HA, disaster recovery, multi-region?

**Tura 5 — Konwencje i standardy projektu**
- Obowiązkowe konwencje niewidoczne z kodu — nazewnictwo branchy, format commit message?
- Reguły code review — wymagany coverage, architektura onion/clean, zakazy?
- Specyficzne instrukcje dla AI-assisted development — czego Claude NIE powinien robić w tym repo?

**Tura 6 (opcjonalna) — Problemy i dług techniczny**
- Znane bolączki architektoniczne; miejsca, których nie dotyka się bez konsultacji?
- Planned migrations / refactory, o których Claude powinien wiedzieć?

**Tura 7 (opcjonalna) — Weryfikacja**
- Zaprezentuj zebrany model wiedzy jako zwięzłą bullet-listę i zapytaj:
  „Czy coś jest niepoprawne lub brakuje czegoś krytycznego?"

Tury 6–7 odpal, gdy budżet tur na to pozwala i gdy projekt jest na tyle złożony, że
weryfikacja się opłaca. Przy bardzo prostym repo całość może zamknąć się w 3–4 turach.

---

## Faza 3 — Generowanie struktury dokumentacji

Gotowe template'y wszystkich plików: **`references/doc-templates.md`** — przeczytaj ten
plik przed generowaniem i trzymaj się template'ów.

### Struktura wyjściowa

```
docs/
├── README.md                  # Mapa dokumentacji + 1-akapitowe streszczenie systemu
├── architecture/
│   ├── overview.md            # C4 Level 1+2 jako diagram Mermaid + opis komponentów
│   ├── decisions/
│   │   └── README.md          # Index ADR (pusty template, jeśli brak ADR)
│   └── data-model.md          # Główne encje, relacje, przepływ danych
├── integrations/
│   └── external-systems.md    # Zewnętrzne systemy, kontrakty, SLA
├── operations/
│   ├── deployment.md          # Jak deployować, środowiska, zmienne
│   └── runbook.md             # Typowe operacje, troubleshooting
└── development/
    ├── conventions.md         # Konwencje kodu, nazewnictwo, wzorce obowiązkowe
    ├── testing.md             # Strategia testów, jak uruchamiać, coverage targets
    └── local-setup.md         # Jak postawić projekt lokalnie
```

`CLAUDE.md` trafia do **rootu repo** (Faza 4) — nie duplikuj go w `docs/`, bo kopie się
rozjeżdżają; jeśli deweloper chce go widzieć w `docs/`, użyj symlinku.

### Reguły generowania

- Twórz **tylko te pliki, dla których zebrałeś wystarczające dane**. Gdy danych brak,
  a plik jest istotny — utwórz go z nagłówkami sekcji i blokiem `> TODO: uzupełnić`
  (w języku dokumentacji), żeby struktura była kompletna, a luki jawne.
- **Nie nadpisuj istniejącej dokumentacji.** Istniejący `README.md` zostaje nietknięty —
  linkuj do niego z `docs/README.md` i nie powielaj jego treści. Istniejące pliki w
  `docs/` lub ADR włącz do indeksu zamiast generować konkurencyjne wersje.
- Fakty wzięte z założeń (odpowiedzi „nie wiem") oznaczaj jawnie, np.
  `> Assumption: ... — do potwierdzenia`, i dopisuj do `## Open Questions`.

### Wymagania jakościowe dla każdego pliku `.md`

- YAML frontmatter: `last-updated: YYYY-MM-DD`, `owner` (jeśli znany), `status: draft|reviewed`.
  Świeżo wygenerowane pliki → `status: draft`.
- Diagram **Mermaid** tam, gdzie wizualizacja realnie pomaga (architektura — `graph`/C4,
  przepływ danych — `flowchart`, interakcje — `sequenceDiagram`). Nie wymuszaj diagramu
  w plikach czysto proceduralnych (local-setup, conventions).
- **Konkrety zamiast ogólników**: rzeczywiste nazwy serwisów, tabel, topiców, typów,
  komend — skopiowane/zweryfikowane z repo, nie wymyślone.
- Sekcja `## Open Questions` na końcu każdego pliku — na niejasności i assumptions.

---

## Faza 4 — Generowanie CLAUDE.md

Anty-wzorce i przykłady dobrych/złych reguł: **`references/claude-md-patterns.md`** —
przeczytaj przed pisaniem. CLAUDE.md to dense reference dla Claude Code, nie dokumentacja.

Struktura (nagłówki po angielsku, treść w języku dewelopera):

```markdown
# CLAUDE.md

## Project Overview
[2–3 zdania: co robi system, główny stack, skala]

## Architecture
[Kluczowe komponenty i ich lokalizacje w repo — ścieżki, nie opisy]

## Build & Run
[Dokładne komendy: build, test, lint, run local — skopiowane/zweryfikowane z konfigów]

## Key Conventions
[Reguły, które Claude musi respektować — punktory, konkretne, bez filozofii]

## What NOT To Do
[Explicit lista zakazów dla Claude Code]

## Navigation Hints
[Najważniejsze miejsca w kodzie dla typowych zadań: „zadanie → ścieżka"]

## Testing
[Jak uruchamiać testy, gdzie są, target coverage]

## Docs
[Wskazanie na docs/ z krótkim opisem co gdzie]
```

Twarde zasady:

- **Brak powtórzeń z docs/** — szczegół należy do docs/, w CLAUDE.md zostaje link.
- **Każda sekcja max 10 linii** — jeśli wychodzi więcej, przenieś nadmiar do docs/.
- **Zero ogólników** — każda reguła musi być falsifiable: da się obiektywnie sprawdzić,
  czy jest przestrzegana („Testy w xUnit + FluentAssertions, bez MSTest" — tak;
  „pisz czysty kod" — nie).
- **Komendy w Build & Run zweryfikuj** z konfigów (`package.json` scripts, `Makefile`,
  `*.csproj`, CI workflow) — nie wpisuj komend, których repo nie obsługuje.
- **Token budget ~400–600 tokenów.** Zmierz po wygenerowaniu (`wc -c CLAUDE.md`,
  szacunek: znaki / 4) i zakomunikuj deweloperowi wynik. Powyżej 600 — tnij.
- Jeśli `CLAUDE.md` już istnieje: nie nadpisuj w ciemno — zachowaj istniejące reguły,
  scal z nowymi sekcjami i pokaż deweloperowi, co się zmieniło.

---

## Faza 5 — Prezentacja i iteracja

Po wygenerowaniu wszystkich plików:

1. Wyświetl drzewo wygenerowanych plików z liczbą linii każdego
   (np. `find docs CLAUDE.md -name '*.md' -exec wc -l {} +` sformatowane jako drzewo).
2. Podaj szacunkowy token budget CLAUDE.md (znaki / 4) i czy mieści się w 400–600.
3. Zapytaj: „Czy chcesz rozwinąć którąś sekcję lub coś skrócić?"
4. Jeśli w Q&A wyszły kluczowe decyzje architektoniczne bez ADR (np. wybór Kafki,
   outbox pattern, multi-region) — zaproponuj utworzenie template'ów ADR dla nich
   w `docs/architecture/decisions/` (template w `references/doc-templates.md`).

Iteruj na życzenie: rozwijanie/skracanie sekcji rób edycją konkretnych plików,
nie regeneracją całości — deweloper mógł już coś poprawić ręcznie.

Nie commituj wygenerowanych plików samodzielnie, chyba że deweloper o to poprosi.

---

## Pliki referencyjne

- `references/doc-templates.md` — gotowe template'y każdego pliku w `docs/` + template ADR.
  Czytaj przed Fazą 3.
- `references/claude-md-patterns.md` — anty-wzorce CLAUDE.md (czego unikać) z przykładami
  złych i dobrych reguł + metoda pomiaru tokenów. Czytaj przed Fazą 4.
