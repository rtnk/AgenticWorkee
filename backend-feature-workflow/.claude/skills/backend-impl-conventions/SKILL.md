---
name: backend-impl-conventions
description: Load for any backend feature IMPLEMENTATION work (phase 5+ of the workflow) in a .NET 10 service. Implementation counterpart of backend-doc-conventions. Defines what may be changed (src/ and tests/ in the target project, running build/test), how to read repo conventions before coding, scope boundaries, the "don't guess — block & escalate" rule, the extended tasks.md status machine, and commit/idempotency discipline. Loaded first by feature-implementation-orchestrator, feature-test-author, feature-implementer and feature-verifier.
---

# Backend Impl Conventions (wspólne reguły fazy implementacyjnej)

Wspólne zasady dla agentów fazy 5+ (orchestrator → autor testów → implementer → weryfikator);
ładowany **jako pierwszy**. To implementacyjny odpowiednik `backend-doc-conventions`. **Różnica
wobec faz 1–4:** tu wolno modyfikować kod produkcyjny i testy oraz uruchamiać build/test. Reszta
dyscypliny (język, „nie zgaduj", idempotentność, wąskie role) obowiązuje nadal.

## 1. Co wolno, a czego nie

- **Wolno**: tworzyć/modyfikować pliki w **`src/`** i **`tests/`** projektu docelowego w zakresie
  bieżącego taska; uruchamiać **`dotnet build`/`dotnet test`** (i pomocnicze `dotnet`/CLI repo);
  aktualizować **Status** taska w `docs/features/<slug>/tasks.md`; tworzyć **commit per task**
  (jeśli włączone).
- **Nie wolno**: zmieniać `spec.md`/`plan.md`/`tasks.md` poza polem **Status** taska (treść
  decyzyjna należy do faz 1–4); dotykać kodu/konfiguracji/migracji **spoza zakresu** taska;
  podejmować decyzji projektowych nieobecnych w `spec.md`/`tasks.md` (patrz §4).

## 2. Czytaj konwencje repo PRZED kodowaniem

Nie zakładaj stosu na sztywno. Zanim napiszesz test lub linię kodu:

0. **`docs/constitution.md`** (jeśli istnieje) — **nadrzędne** źródło zasad (warstwy, Result vs
   wyjątki, naming, progi NFR, bezpieczeństwo, prostota P-15/P-16). Kod **musi** respektować `P-*`;
   verifier je egzekwuje. Konstytucja ma pierwszeństwo przed domysłem z kodu.
1. Przeczytaj `CLAUDE.md`/`README.md`/`docs/` w roocie — źródło prawdy o wzorcach.
2. Poznaj układ `src/` i projektów `*.csproj` (warstwy API/Application/Domain/Infrastructure,
   namespacy, target framework, referencje).
3. Wychwyć wzorce: **Result vs wyjątki**, naming handlerów (np. `XxxCommandHandler`), walidacja
   (FluentValidation?), mapowanie, DI.
4. Poznaj **styl testów**: framework (xUnit/NUnit/MSTest), asercje (FluentAssertions?), mocki
   (Moq/NSubstitute), układ projektów `*.Tests`, nazewnictwo.
5. Zajrzyj do `spec.md`/`plan.md` feature — definiują kontrakty, model danych, reguły i
   bezpieczeństwo, których kod musi dotrzymać.

Czego nie da się potwierdzić z repo/spec — **nigdy** nie zgaduj (patrz §4).

## 3. Granice zakresu

- Realizujesz **TYLKO** wybrany task, w obrębie tego, co opisuje `spec.md`.
- Implementacja **minimalna**: tyle kodu, ile trzeba, by spełnić kryteria akceptacji taska i
  przejść testy. Bez refaktorów „przy okazji", funkcji „na zapas" ani zmian poza plikami taska
  (pole „Obszar kodu / pliki" to wskazówka, nie pozwolenie na rozszerzanie zakresu).
- Jeśli realizacja wymaga zmian, których task nie obejmuje → task jest źle pocięty: zatrzymaj się
  i eskaluj, nie poszerzaj zakresu po cichu.

## 4. „Nie zgaduj — blokuj i eskaluj"

Najważniejsza reguła, przeniesiona z faz 1–4 do świata kodu.

- Brak **decyzji projektowej** (kontrakt, reguła, format, zachowanie brzegowe), gdy
  `spec.md`/`tasks.md` milczą lub są sprzeczne — **nie wymyślaj** i nie dotykaj kodu „na próbę".
- **Kto zgłasza, kto zapisuje**: subagent (test-author/implementer/verifier) **nie** edytuje pola
  `Status` — **raportuje blokadę** orkiestratorowi (konkretna luka + opcje). Status
  `blocked (reason: <opis / [DO USTALENIA] #X>)` ustawia **wyłącznie orchestrator**, on też eskaluje
  pytanie do człowieka (§5, single-writer). Jako orchestrator — ustaw `blocked` i eskaluj sam.
- Drobny, bezpieczny brak (np. nazwa pola spójna z konwencją repo) możesz przyjąć jako jawne
  `[ZAŁOŻENIE]` w podsumowaniu. Ale **wszystko, co zmienia kontrakt, model danych lub regułę
  biznesową, jest decyzją projektową** → blokada, nie domysł.

## 5. Notacja statusów w `tasks.md` (rozszerzenie `feature-tasks`)

Faza 4 ustawia tylko `todo | blocked`. Faza 5+ rozszerza maszynę stanów (kompatybilnie wstecz;
wartości to artefakt narzędziowy, **po angielsku**):

```
todo → in_progress → tests_written → implemented → done
                                                    (blocked — w dowolnym momencie)
```

| Status | Znaczenie | Kto ustawia |
|--------|-----------|-------------|
| `todo` | gotowy do podjęcia (stan z fazy 4) | task-decomposer |
| `in_progress` | orchestrator wybrał task, cykl wystartował | orchestrator |
| `tests_written` | RED gotowa: testy istnieją i failują z właściwego powodu | orchestrator (po test-author) |
| `implemented` | GREEN: kod gotowy, build czysty, testy zielone | orchestrator (po implementer) |
| `done` | verifier orzekł PASS (kryteria + zgodność ze spec) | orchestrator (po verifier) |
| `blocked (reason: ...)` | luka decyzyjna lub przekroczony limit iteracji → eskalacja | orchestrator (na zgłoszenie subagenta) |

Status edytuje **wyłącznie** orchestrator (subagenci raportują wynik; orchestrator przepisuje pole
**Status**). Edycja punktowa — zmienia tylko jedną linię `- **Status**: ...`, nic poza nią.

## 6. Bramka bezpieczeństwa (taski wrażliwe)

Dla tasków dotykających **uwierzytelniania, autoryzacji, danych wrażliwych, sekretów lub
kryptografii** (spec §10):

- Task `Security-critical: yes` (lub dotykający auth/danych/sekretów) podlega bramce obowiązkowo.
- Implementer respektuje `P-12`–`P-14` konstytucji (jeśli jest) oraz §10 spec: brak sekretów w
  kodzie/logach, poprawne authZ na endpointach, maskowanie/szyfrowanie danych wrażliwych.
- Kontrola jest **inline** w `feature-verifier` (bez zewnętrznych skilli, bez GitHub): przegląd
  zmian `src/` pod kątem sekretów/authZ/maskowania; istotne ustalenia = `FAIL` (§10 / `P-12`–`P-14`).
- Naruszenie bezpieczeństwa nie jest „drobnym brakiem" — to twarda blokada, nigdy domysł.

## 7. Dyscyplina commitów i idempotentność

- **Commit per task** (jeśli włączone): jeden zrealizowany task = jeden commit z jasnym opisem,
  np. `feat(<slug>): T-007 walidacja limitu wypłaty`. Obejmuje kod, testy i aktualizację statusu.
- **Idempotentność**: ponowne uruchomienie na tym samym tasku **nie duplikuje** pracy ani testów.
  Przed pisaniem sprawdź, czy testy/kod już istnieją (po nazwach klas/metod i obszarze taska) i
  **aktualizuj** zamiast doklejać kopie. Task `done` pomijasz.
- Nie usuwaj cudzego kodu ani testów bez wyraźnej potrzeby wynikającej z taska; przy konflikcie z
  istniejącym kodem — zatrzymaj się i eskaluj.

## 8. Bramka legalności zależności (NuGet — slopcheck)

Nowy pakiet **nie jest** drobnym brakiem — to decyzja podlegająca weryfikacji (analog „Registry
Safety Gate" GSD; chroni przed **halucynacją** nieistniejącego pakietu).

- Gdy task dodaje `PackageReference`, orchestrator uruchamia `.claude/scripts/check-packages.sh`:
  - `[OK]` — pakiet resolvuje się z feedu (istnieje) → wolno.
  - `[SUS]` — brak dokładnego trafienia / możliwy typo-squat → **checkpoint**: jawne potwierdzenie
    człowieka, nigdy ciche przyjęcie.
  - `[SLOP]` — pakiet nie istnieje w żadnym feedzie (halucynacja) → **twardy FAIL**, usuń/zastąp.
- Preferuj pakiety **już obecne** w repo; nowa zależność wymaga uzasadnienia (po co, alternatywy).
