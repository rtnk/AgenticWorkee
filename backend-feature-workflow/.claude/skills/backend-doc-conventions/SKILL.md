---
name: backend-doc-conventions
description: Load for any backend feature documentation work (spec, refinement, planning, task decomposition) in a .NET 10 service. Defines shared language, file layout, slug rules, the "don't guess — ask" rule, assumption/open-question notation, and how to read repo conventions. Loaded by feature-spec-author, feature-spec-refiner, feature-planner and feature-task-decomposer.
---

# Backend Doc Conventions (wspólne reguły)

Ten skill definiuje **wspólne** zasady obowiązujące we wszystkich fazach workflow
dokumentacyjnego: specyfikacja → doprecyzowanie → plan → zadania. Każdy agent ładuje go
jako pierwszy.

## 1. Język i styl

- **Treść dokumentów** (`spec.md`, `plan.md`, `tasks.md`, `decisions.md`): **język polski**.
- **Styl**: rzeczowo, konkretnie, bez lania wody. Krótkie zdania, listy zamiast akapitów tam,
  gdzie to możliwe. Żadnych ozdobników, marketingu ani powtórzeń.
- **Artefakty narzędziowe** (frontmatter YAML, nazwy skilli/agentów, klucze, identyfikatory
  techniczne np. `T-001`, nazwy sekcji w szablonie): **język angielski** / forma kanoniczna.
- Terminy techniczne (np. `MediatR`, `EF Core`, `idempotency key`, `outbox`) zostawiaj
  w oryginale — nie tłumacz na siłę.

## 2. Lokalizacja plików i konwencja `slug`

Wszystkie dokumenty feature żyją w **projekcie docelowym** (nie w tym meta-repo) pod:

```
docs/features/<slug>/
  spec.md         # specyfikacja techniczna (faza 1–2)
  decisions.md    # log decyzji projektowych (ADR), wypełniany w fazie 2
  plan.md         # plan wdrożenia (faza 3)
  tasks.md        # dekompozycja na zadania (faza 4)
```

**Reguła `slug`**: kebab-case wyprowadzony z nazwy feature.
- małe litery, słowa rozdzielone `-`, tylko `[a-z0-9-]`;
- usuń polskie znaki diakrytyczne (ą→a, ć→c, ę→e, ł→l, ń→n, ó→o, ś→s, ż/ź→z);
- usuń słowa-wypełniacze, zostaw rdzeń znaczeniowy;
- przykłady: „Limity wypłat dla kont premium” → `withdrawal-limits-premium`,
  „Webhook powiadomień o płatnościach” → `payment-notification-webhook`.

Jeśli `docs/features/<slug>/` już istnieje, **nie nadpisuj na ślepo** — pracuj na istniejących
plikach (edycje idempotentne) albo dopytaj o intencję.

## 3. „Nie zgaduj — dopytaj”

Najważniejsza reguła całego workflow.

- Gdy brakuje informacji potrzebnej do **decyzji projektowej**, **nie wymyślaj** odpowiedzi.
- Masz dwie ścieżki w zależności od fazy:
  - **Faza interaktywna** (refiner): zadaj użytkownikowi skupioną porcję pytań.
  - **Faza nieinteraktywna / brak odpowiedzi**: zapisz lukę jawnie jako otwartą kwestię i jedź dalej.
- Każde przyjęte uproszczenie/domysł oznacz jawnie — patrz notacja niżej.

### Notacja założeń i otwartych kwestii

W treści dokumentu używaj cytatów blokowych z prefiksem:

```
> [ZAŁOŻENIE] Przyjmuję, że limit dotyczy doby kalendarzowej w UTC.
> [DO USTALENIA] Czy limit jest twardy (odrzucenie) czy miękki (ostrzeżenie)?
```

- `> [ZAŁOŻENIE] ...` — świadome uproszczenie przyjęte, by móc kontynuować. Założenie jest
  **propozycją do potwierdzenia**, nie faktem.
- `> [DO USTALENIA] ...` — luka wymagająca decyzji człowieka. Wszystkie `[DO USTALENIA]`
  muszą być też wylistowane w sekcji **14. Ryzyka i otwarte pytania** specyfikacji.
- Dokument jest „gotowy” (`status: ready`) dopiero, gdy **nie zawiera żadnego `[DO USTALENIA]`**.

## 4. Kontekst .NET 10 i czytanie konwencji repo

Załóż typowy backend **.NET 10**, ale **potwierdź każdą warstwę z repozytorium** — nie zakładaj
stosu na sztywno. Typowy zestaw (do weryfikacji):

- ASP.NET Core (Minimal API lub kontrolery), DI z `Microsoft.Extensions.*`.
- Command/query dispatcher w stylu MediatR (handlery, pipeline behaviors).
- EF Core + MS SQL Server, migracje EF.
- Opcjonalnie: Kafka (eventy/outbox), Redis (cache/locki), YARP (gateway/reverse proxy),
  IdentityServer / OpenIddict (auth), OpenTelemetry (obserwowalność).

**Jak ustalać rzeczywiste konwencje** (zanim cokolwiek założysz):

1. Przeczytaj `CLAUDE.md` / `README.md` / `docs/` w roocie projektu — to źródło prawdy o wzorcach.
2. Przejrzyj istniejące moduły/warstwy (`src/`, układ projektów `*.csproj`, namespacy), żeby
   poznać nazewnictwo, podział na warstwy i wzorce (np. Result vs wyjątki, naming handlerów).
3. Zajrzyj do wcześniejszych `docs/features/*/spec.md` — przejmij ich strukturę i słownictwo.
4. Dopiero gdy repo milczy w danej kwestii → `[ZAŁOŻENIE]` albo pytanie.

To, czego nie da się potwierdzić z repo, **nigdy** nie ląduje w dokumencie jako fakt.

## 5. Wspólne reguły zapisu

- **Tylko `docs/features/<slug>/`.** Agenci czytają cały repo dla kontekstu, ale **piszą wyłącznie**
  do katalogu feature. **Żadnych modyfikacji kodu produkcyjnego, konfiguracji, migracji ani plików
  poza `docs/features/<slug>/`.**
- **Edycje idempotentne.** Ponowne uruchomienie agenta na tym samym wejściu nie duplikuje treści —
  aktualizuje istniejące sekcje zamiast doklejać kopie. Zachowuj nagłówki sekcji szablonu.
- **Jeden agent = jeden plik wyjściowy** (plus ewentualnie `decisions.md` w fazie doprecyzowania).
- Nie usuwaj treści wniesionej przez człowieka bez wyraźnej potrzeby; przy konflikcie — `[DO USTALENIA]`.
- Zachowuj kolejność i komplet sekcji z odpowiedniego skilla szablonowego (`feature-spec`,
  `feature-planning`, `feature-tasks`).
