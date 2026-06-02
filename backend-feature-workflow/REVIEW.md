# Review: backend-feature-workflow vs. GitHub Spec Kit

Dogłębny przegląd workflow do implementacji nowych funkcjonalności (`backend-feature-workflow`)
z porównaniem do [GitHub Spec Kit](https://github.com/github/spec-kit) i listą usprawnień.

- **Data**: 2026-06-01
- **Zakres przeglądu**: 8 subagentów + 7 skilli paczki `backend-feature-workflow`.
- **Punkt odniesienia**: metodologia Spec-Driven Development (Spec Kit), commit `main`.

> **Status wdrożenia:** wszystkie rekomendacje **G1–G10** oraz drobne obserwacje (§7) zostały
> zaimplementowane w wersji **1.0.0** (zob. `CHANGELOG.md`). Ten dokument zachowuje pełne
> uzasadnienie i porównanie jako rejestr decyzji.

---

## 1. Streszczenie wykonawcze

Workflow jest **dojrzały i przemyślany** — w obszarze **dyscypliny implementacji (faza 5+)
faktycznie przewyższa Spec Kit**: ma prawdziwy TDD z rozdzieleniem ról (RED/GREEN/bramka),
niezależnego weryfikatora, jawną maszynę stanów z limitem iteracji i twarde bramki build/test.

Główne braki ujawnia porównanie z fazą *przed* implementacją oraz z mechanizmami *governance*
Spec Kit. W kolejności wpływu:

1. **Brak „konstytucji" projektu** — trwałych, projekt-specyficznych zasad gatujących plan i kod.
2. **Brak całościowej analizy spójności artefaktów** (`spec ↔ plan ↔ tasks`) przed implementacją.
3. **Taski cięte po warstwach, nie po wartości** — opóźnia działające, dostarczalne plasterki.
4. **Słaba bramka `spec → plan`** — jedynym kryterium jest brak `[DO USTALENIA]`.
5. **Prerekwizyty sprawdzane „prozą"** agenta, bez deterministycznych checków.

Reszta dokumentu: mocne strony (§3), mapa porównawcza faz (§4), luki z rekomendacjami (§5),
priorytetyzowana mapa drogowa (§6).

---

## 2. Co to za workflow (skrót)

Paczka artefaktów Claude Code (subagenci + skille) tworząca powtarzalny proces zmian w usłudze
backendowej .NET 10:

```
faza 1: feature-spec-author      opis → spec.md (draft)
faza 2: feature-spec-refiner     iteracyjne doprecyzowanie → spec.md (ready) + decisions.md
faza 3: feature-planner          spec(ready) → plan.md
faza 4: feature-task-decomposer  plan.md → tasks.md
faza 5+: feature-implementation-orchestrator
          └─ pętla TDD per task: feature-test-author (RED)
                                 → feature-implementer (GREEN)
                                 → feature-verifier (BRAMKA)
```

Fazy 1–4 piszą **tylko** do `docs/features/<slug>/`. Faza 5+ modyfikuje `src/` i `tests/`.

---

## 3. Mocne strony (gdzie workflow bije Spec Kit)

| Cecha | backend-feature-workflow | Spec Kit |
|------|--------------------------|----------|
| **TDD z separacją ról** | Osobne subagenty RED → GREEN → bramka; verifier jest **read-only i niezależny** (adwersaryjna weryfikacja) | TDD jako zasada konstytucji, ale `/implement` jest jednym, monolitycznym krokiem |
| **Single-writer statusów** | Status taska edytuje **wyłącznie** orchestrator; subagenci tylko raportują | brak takiej dyscypliny |
| **Jawna maszyna stanów pętli** | Kroki 0–8 + limit iteracji + jawna eskalacja `blocked` | brak ograniczonej pętli z eskalacją |
| **Least-privilege** | Tool allowlist per agent (np. verifier bez `Write`/`Edit`) | agent ma pełne uprawnienia |
| **„Nie zgaduj — blokuj i eskaluj"** | Reguła rozszerzona także na fazę **kodu**, nie tylko spec | `[NEEDS CLARIFICATION]` głównie na poziomie spec |
| **Izolacja kontekstu** | Każdy subagent = wąska rola, czyste wejście/wyjście | jeden agent prowadzi całość |
| **Anty-założenie** | Wymóg potwierdzania stosu/konwencji z repo (`CLAUDE.md`, kod) zanim cokolwiek założy | mniej dopracowane |

Te elementy są **wartościowe i warto je zachować** — żadna rekomendacja poniżej ich nie narusza.

---

## 4. Mapa porównawcza faz

| Etap | Spec Kit | backend-feature-workflow | Status |
|------|----------|--------------------------|--------|
| Zasady projektu | `/constitution` → `constitution.md` | *(brak)* | ❌ luka G1 |
| Specyfikacja | `/specify` → `spec.md` | `feature-spec-author` → `spec.md` (15 sekcji) | ✅ równoważne (bogatszy szablon) |
| Doprecyzowanie | `/clarify` (coverage-based) | `feature-spec-refiner` (iteracyjny, sesyjny) | ✅ równoważne / lepsze |
| Checklista jakości spec | `/checklist` | *(tylko „brak [DO USTALENIA]")* | ⚠️ luka G4 |
| Plan | `/plan` → plan.md + data-model.md + contracts/ + research.md | `feature-planner` → `plan.md` (kontrakty inline w spec) | ⚠️ luka G5 |
| Zadania | `/tasks` (per user-story, znaczniki `[P]`) | `feature-task-decomposer` (per warstwa, topologicznie) | ⚠️ luka G3 |
| Analiza spójności | `/analyze` (spec↔plan↔tasks, read-only) | *(tylko weryfikacja per-task)* | ❌ luka G2 |
| Implementacja | `/implement` (monolit) | orchestrator + pętla TDD (RED/GREEN/bramka) | ✅ wyraźnie lepsze |
| Tracking | `/taskstoissues` | commit-per-task | ⚠️ luka G8 |
| Instalacja/personalizacja | CLI `specify init` + override/preset/extension | `cp -r .claude` | ⚠️ luka G7 |

---

## 5. Luki i rekomendacje

### G1. Brak „konstytucji" projektu *(priorytet: wysoki)*

**Obserwacja.** Spec Kit utrzymuje `.specify/memory/constitution.md` — zestaw **nienaruszalnych
zasad projektu** (jakość, frameworki, testowanie, wydajność, prostota), do których agent odwołuje
się w *każdej* fazie, z jawnymi bramkami (np. *Simplicity Gate*, *Anti-Abstraction Gate*).
Workflow ma skille `backend-doc-conventions` / `backend-impl-conventions`, ale to reguły **samego
workflow** (język, idempotencja, role) — nie zasady **konkretnego projektu**. Konwencje stosu są
odkrywane ad hoc z repo *przy każdym uruchomieniu każdego agenta* — kosztowne i podatne na
niespójność między fazami/sesjami.

**Rekomendacja.**
- Dodać **fazę 0** + skill `feature-constitution` i lekkiego agenta, który raz na projekt tworzy/
  utrzymuje `docs/constitution.md` (lub `.claude/constitution.md`): wybór wzorców (Result vs
  wyjątki, naming handlerów, walidacja), progi NFR, polityka bezpieczeństwa, limit złożoności
  („≤ N projektów", „używaj frameworka wprost"), reguły migracji.
- `feature-planner` i `feature-verifier` dodają **bramkę zgodności z konstytucją** (odchylenie =
  ostrzeżenie/`FAIL` z uzasadnieniem w `decisions.md`).
- Efekt: konwencje czytane **raz**, spójnie egzekwowane, mniej ponownego skanowania repo.

### G2. Brak całościowej analizy spójności artefaktów *(priorytet: wysoki)*

**Obserwacja.** Weryfikacja jest **per-task** — `feature-verifier` sprawdza zgodność *jednego*
taska ze spec. Nikt nie sprawdza **całościowo**, przed wejściem w kod: czy każde wymaganie
funkcjonalne i każde wysokopoziomowe kryterium akceptacji ze spec §3 ma pokrycie w `tasks.md`; czy
plan pokrywa cały spec; czy nie ma tasków „sierot" bez mapowania; czy nie ma sprzeczności
spec↔plan↔tasks. Szablony *mają* mapowania (`plan → spec`, `task → spec §`), ale nic ich nie
egzekwuje holistycznie.

**Rekomendacja.**
- Nowy agent **`feature-analyzer`** (read-only, faza 4.5, między dekompozycją a implementacją) —
  odpowiednik `/analyze`:
  - **macierz pokrycia**: wymaganie/kryterium spec → pozycja planu → task(i),
  - wykrywanie: sierot, duplikatów, sprzeczności, niepokrytych wymagań, tasków bez kryteriów,
  - raport bez modyfikacji plików; braki kierują z powrotem do faz 1–4.
- Tani, wysoki zwrot: wychwytuje błędy *zanim* zaczną kosztować iteracje fazy 5.

### G3. Taski cięte po warstwach, nie po wartości *(priorytet: średni)*

**Obserwacja.** `feature-tasks` grupuje „po warstwach/kamieniach milowych" (Kontrakty → Handlery →
…) i sortuje topologicznie. Spec Kit grupuje **per user story**, tak by każda historia była
**niezależnie implementowalna i testowalna** (inkrementalne MVP), i oznacza zadania równoległe
znacznikiem `[P]`. Cięcie horyzontalne (po warstwach) opóźnia działającą wartość end-to-end i
utrudnia wczesny feedback.

**Rekomendacja.**
- W `feature-tasks` zalecić **plasterki wertykalne per przypadek użycia** (UC-1…) ze spec §3 jako
  domyślny tryb grupowania; topologia warstw zostaje jako reguła kolejności *wewnątrz* plasterka.
- Dodać znacznik **`[P]`** (task równoległy, brak współdzielonych plików) i jawne oznaczenie
  **MVP / „pierwszy działający przepływ"**.
- Orchestrator może wtedy dostarczać kompletne, demonstrowalne historie wcześniej.

### G4. Słaba bramka `spec → plan` *(priorytet: średni)*

**Obserwacja.** Jedyne kryterium przejścia spec→plan to **brak `[DO USTALENIA]`**. Spec bez
otwartych pytań może być wciąż niespójny, mieć puste NFR (§4), niemierzalne kryteria akceptacji
albo nieuzupełnione bezpieczeństwo (§10). Spec Kit traktuje `/checklist` + *Review & Acceptance
Checklist* jako osobną bramkę jakości („unit testy dla specyfikacji").

**Rekomendacja.**
- Dodać do skilla `feature-spec` **checklistę akceptacji spec** i egzekwować ją w `feature-spec-
  refiner` przed `ready`: każda sekcja kompletna? kryteria mierzalne (nie „działa poprawnie")? NFR
  z progami? §10 wypełnione? §13 mapuje kryteria na poziomy testów?
- Opcjonalnie wydzielić to do `feature-checklist` (analogicznie do `/checklist`).

### G5. Kontrakty i model danych tylko inline w `spec.md` *(priorytet: niski/średni)*

**Obserwacja.** Spec Kit rozdziela artefakty planu: `data-model.md`, `contracts/api-spec.json`
(OpenAPI), `research.md`, `quickstart.md` — część **maszynowo czytelna**. Tu wszystko jest inline
w `spec.md` (JSON w blokach), co utrudnia walidację kontraktu, diff i generowanie testów
kontraktowych.

**Rekomendacja (opcjonalna).**
- Wydzielić kontrakty do `docs/features/<slug>/contracts/` (OpenAPI/`*.json`) i model danych do
  `data-model.md`; `feature-test-author` może z nich generować testy kontraktowe, a `feature-
  verifier` — porównywać implementację z kontraktem maszynowo.

### G6. Prerekwizyty sprawdzane „prozą", nie deterministycznie *(priorytet: średni)*

**Obserwacja.** Spec Kit ma skrypty (`check-prerequisites.sh`, `setup-plan.sh`…) dające
deterministyczną walidację stanu. Tu sprawdzenia („czy status `ready`", „czy istnieje `tasks.md`",
„czy build przechodzi przed fazą 5") to instrukcje w prozie agenta — podatne na pominięcie.

**Rekomendacja.**
- Dodać lekkie helpery/skrypty lub **SessionStart hook** (repo działa w trybie Claude Code on
  web): weryfikacja, że spec jest `ready`, wymagane pliki istnieją, `dotnet build` jest zielony
  przed startem fazy 5. Patrz skill `session-start-hook`.

### G7. Brak instalatora i warstwowania szablonów *(priorytet: niski)*

**Obserwacja.** Spec Kit: CLI `specify init` + hierarchia override/preset/extension (personalizacja
bez forka). Tu: ręczne `cp -r .claude`, brak wersjonowania paczki i mechanizmu nadpisań.

**Rekomendacja.**
- Skrypt instalacyjny + udokumentowana reguła „projekt-lokalny skill/agent o tej samej nazwie
  wygrywa", `CHANGELOG.md` i wersja paczki.

### G8. Brak mostka do issue/PR tracking *(priorytet: niski)*

**Obserwacja.** Spec Kit ma `/taskstoissues`. Tu jest commit-per-task (dobre), ale brak eksportu
`tasks.md` → GitHub Issues / linkowania do PR.

**Rekomendacja (opcjonalna).** Opcjonalny krok eksportu tasków do Issues z zachowaniem ID `T-00x`.

> **Aktualizacja (1.1.0):** rekomendację G8 **wycofano** — na życzenie właściciela paczka nie używa
> GitHub w żadnej formie. Agent `feature-tasks-to-issues` (wdrożony w 1.0.0) został usunięty;
> tracking pozostaje przy commit-per-task. Zob. `REVIEW-GSD.md` i `CHANGELOG.md`.

### G9. Brak bramki prostoty/anty-abstrakcji na poziomie planu *(priorytet: niski)*

**Obserwacja.** „Minimalizm" jest regułą `feature-implementer`, ale `feature-planner` może
zaprojektować nadmiarową architekturę bez kontroli. Spec Kit ma jawne *Simplicity / Anti-Abstraction
Gates* w planie.

**Rekomendacja.** Po wprowadzeniu konstytucji (G1) dodać do `feature-planner`/`feature-verifier`
check prostoty zakorzeniony w jej zasadach.

### G10. Workflow jest .NET-only *(świadomy wybór — udokumentować)*

Spec Kit jest agnostyczny stosowo; ta paczka celowo specjalizuje się w backendzie .NET 10
(specjalizacja = jakość). Warto **jawnie udokumentować** to ograniczenie w README oraz ścieżkę
rozszerzenia na inne stosy/frontend, bo nazwa „nowe funkcjonalności" sugeruje szerszy zakres.

---

## 6. Priorytetyzowana mapa drogowa

| # | Usprawnienie | Wpływ | Koszt | Priorytet |
|---|--------------|-------|-------|-----------|
| G1 | Konstytucja projektu (faza 0 + skill) | wysoki | śr. | **1** |
| G2 | Agent `feature-analyzer` (spójność spec↔plan↔tasks) | wysoki | niski | **2** |
| G4 | Checklista akceptacji spec (bramka `ready`) | śr. | niski | **3** |
| G3 | Plasterki wertykalne per UC + znacznik `[P]` | śr. | śr. | **4** |
| G6 | Deterministyczne prerekwizyty (hook/skrypt) | śr. | niski | **5** |
| G5 | Wydzielone kontrakty/model danych | niski-śr. | śr. | 6 |
| G7 | Instalator + warstwowanie szablonów | niski | śr. | 7 |
| G9 | Bramka prostoty w planie (po G1) | niski | niski | 8 |
| G8 | Eksport tasks → Issues | niski | śr. | 9 |
| G10 | Doprecyzowanie zakresu .NET-only w README | niski | niski | 10 |

**Rekomendowany pierwszy krok:** G2 (`feature-analyzer`) — najwyższy zwrot przy najniższym koszcie,
nie narusza istniejących artefaktów, a domyka pętlę jakości między fazą dokumentacyjną a kodem.
Zaraz po nim G1 (konstytucja), bo odblokowuje G4 i G9.

---

## 7. Drobne obserwacje techniczne

- **Limit iteracji „3–5"** jest nieostry — warto ustalić jedną wartość domyślną (np. 4) i ewentualnie
  uzależnić od rozmiaru taska (S/M/L).
- **Brak bramki bezpieczeństwa** mimo spec §10 — można podpiąć skill `security-review` w fazie 5
  dla tasków dotykających auth/danych wrażliwych.
- **Podwójne `dotnet build/test`** (orchestrator krok 5 + verifier krok 6) jest celowe (niezależność),
  ale warto to jawnie zaznaczyć jako decyzję, by nie wyglądało na duplikację do „optymalizacji".
- **Root `README.md` meta-repo** jest pusty (`# AgenticWorkee`) — dodać 2–3 zdania kontekstu i
  link do `backend-feature-workflow/README.md`.
- **`decisions.md` (ADR)** to dobry element, którego Spec Kit nie ma wprost — zachować i ewentualnie
  spiąć z konstytucją (decyzje przekrojowe → konstytucja, decyzje feature → `decisions.md`).

---

## Źródła

- [github/spec-kit](https://github.com/github/spec-kit)
- [spec-kit/spec-driven.md](https://github.com/github/spec-kit/blob/main/spec-driven.md)
- [Spec Kit — Quick Start](https://github.github.com/spec-kit/quickstart.html)
- [Microsoft for Developers — Diving Into Spec-Driven Development With GitHub Spec Kit](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)
