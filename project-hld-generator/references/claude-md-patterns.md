# CLAUDE.md — wzorce i anty-wzorce

CLAUDE.md jest doczytywany do kontekstu Claude Code przy **każdej** sesji w repo. Każdy
zbędny token płaci się przy każdym zadaniu, a ogólniki rozmywają reguły, które naprawdę
mają znaczenie. Stąd twardy budżet i wymóg falsyfikowalności.

## Budżet tokenów

- Cel: **400–600 tokenów** całego pliku.
- Pomiar po wygenerowaniu: `wc -c CLAUDE.md`; szacunek tokenów ≈ znaki / 4 dla treści
  angielskiej, ≈ znaki / 3.5 dla polskiej. Werdykt „tnij / nie tnij" wydawaj według
  przelicznika języka treści (tego samego, który raportujesz deweloperowi).
- Powyżej 600: tnij wg priorytetu. Najpierw skracaj Project Overview i Docs, potem
  przenoś szczegóły Architecture/Testing do `docs/` zostawiając link. **Nie tnij**
  Key Conventions, What NOT To Do ani Build & Run — to sekcje, dla których plik istnieje.

## Test falsyfikowalności

Każda reguła musi przejść test: *czy recenzent patrząc na diff potrafi obiektywnie
stwierdzić, że reguła została złamana?* Jeśli nie — reguła jest filozofią i wylatuje.

| ❌ Niefalsyfikowalne | ✅ Falsyfikowalne |
|----------------------|-------------------|
| Pisz czysty, czytelny kod | Max 1 publiczna klasa na plik |
| Dbaj o wydajność | Nie używaj `Thread.Sleep` — używaj `Task.Delay` |
| Testuj swoje zmiany | Każdy nowy handler ma test w `tests/Unit/` (xUnit + FluentAssertions) |
| Zachowuj ostrożność przy DB | Nie zmieniaj schematu DB bez migracji EF Core |
| Stosuj dobre praktyki REST | Nowe endpointy ZAWSZE przez MediatR handler, nie logika w kontrolerze |

## Anty-wzorce (czego unikać)

1. **Powtarzanie docs/.** CLAUDE.md to dense reference — jeśli sekcja opisuje to, co już
   stoi w `docs/architecture/overview.md`, zastąp ją jedną linią z linkiem. Duplikaty
   nieuchronnie się rozjeżdżają i Claude dostaje sprzeczne instrukcje.
2. **Proza architektoniczna.** Akapity o "warstwowej architekturze zapewniającej
   separację odpowiedzialności" nic nie dają. Architecture = lista `komponent → ścieżka`.
3. **Komendy z głowy, nie z repo.** Każda komenda w Build & Run musi istnieć w
   `package.json` scripts / `Makefile` / CI workflow / dokumentacji SDK. Niedziałająca
   komenda jest gorsza niż brak komendy — Claude będzie ją uparcie próbował.
4. **Tłumaczenie Claude'owi rzeczy, które wie.** "Używaj git do wersjonowania",
   "pisz testy jednostkowe do logiki" — szum. Zapisuj wyłącznie to, co **specyficzne
   dla tego repo** i czego nie da się wywnioskować z kodu.
5. **Reguły-filozofia.** Patrz test falsyfikowalności wyżej. "Bez filozofii" znaczy:
   żadnych wartości, zasad ogólnych, SOLID-mantr — tylko decyzje.
6. **Sekcje-ściany.** Sekcja > 10 linii to sygnał, że treść należy do `docs/`.
   Zostaw 1–2 najważniejsze punkty + link.
7. **Brak zakazów.** Sekcja What NOT To Do jest najwyżej działającą częścią pliku —
   pusta sekcja to zmarnowana okazja. Jeśli deweloper nie podał zakazów w Q&A,
   zaproponuj wynikające z rekonesansu (np. katalogi generowane, migracje, vendored code).
8. **Nieoznaczone założenia.** Jeśli reguła pochodzi z założenia (deweloper odpowiedział
   "nie wiem"), nie wpisuj jej do CLAUDE.md jako pewnik — pewniki trzymaj w CLAUDE.md,
   niepewności w `docs/` pod `## Open Questions`.
9. **Nagłówki po polsku / niestandardowe.** Struktura sekcji jest stała i po angielsku
   (Project Overview, Architecture, Build & Run, Key Conventions, What NOT To Do,
   Navigation Hints, Testing, Docs) — narzędzia i ludzie polegają na tych nazwach.
   Treść pod nagłówkami — w języku dewelopera.
10. **Nadpisywanie istniejącego CLAUDE.md.** Istniejące reguły mogły powstać po bolesnych
    incydentach. Scal: zachowaj stare reguły (chyba że jawnie sprzeczne z odpowiedziami
    z Q&A — wtedy zapytaj), dołóż nowe, pokaż deweloperowi diff.

## Wzorzec dobrej sekcji — przykład

```markdown
## What NOT To Do
- Nie dodawaj NuGet packages bez konsultacji
- Nie zmieniaj schematu DB bez migracji EF Core (`dotnet ef migrations add`)
- Nie modyfikuj `/src/Contracts/generated/` — generowane z proto przy buildzie
- Nie używaj `Thread.Sleep` — używaj `Task.Delay`
```

Krótko, konkretnie, każdy punkt sprawdzalny na diffie. Tak ma wyglądać cały plik.
