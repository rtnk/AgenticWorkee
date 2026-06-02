---
name: dotnet-patterns
description: Wiedza specyficzna dla .NET/C# używana w całym workflowie refaktoryzacji — wzorce projektowe do wykrywania i sugerowania (Repository/UoW, Result<T>, CQRS/MediatR, Options, Factory, Decorator, Specification), twarde reguły obsługi wyjątków .NET oraz narzędzia (dotnet build/test, xUnit + FluentAssertions + Moq, cel pokrycia 70%). Trigger — projekt zawiera .csproj/.sln/kod C#. Wczytywany przez wszystkie subagenty refactor-* przy projektach .NET.
---

# dotnet-patterns — wzorce i reguły .NET / C#

**Trigger:** projekt zawiera `.sln`/`.csproj`/pliki `.cs`, albo użytkownik wskazał .NET/C#.
Ten skill jest **wiedzą poprzeczną** — wczytują go analyzer, planner, test-writer, implementer i
reviewer, gdy pracują nad kodem .NET.

## 1. Wzorce do wykrywania i sugerowania

Dla każdego wzorca: **kiedy sugerować** (sygnał w kodzie) i **na co uważać**.

- **Repository + Unit of Work**
  - Sugeruj, gdy: zapytania EF/SQL rozsiane po warstwie aplikacji/kontrolerach; brak abstrakcji
    nad persystencją; transakcje rozjechane między operacjami.
  - Uwaga: nie owijaj `DbContext` (sam jest UoW/Repository) bez realnej potrzeby (KISS/YAGNI).
- **Result pattern (`Result<T>`)**
  - Sugeruj, gdy: wyjątki sterują **normalnym** przepływem (walidacja, „nie znaleziono"),
    wyjątki używane do zwykłych ścieżek biznesowych.
  - Uwaga: przejście wyjątki → `Result<T>` zmienia kontrakt → **wszystkie call-site'y** muszą
    obsłużyć `Result` (patrz §2 i §3). To zawsze osobne zadanie w planie.
- **CQRS (MediatR)**
  - Sugeruj, gdy: grube serwisy aplikacyjne mieszające odczyt i zapis; powtarzalne cross-cutting
    (walidacja, logowanie) → pipeline behaviors.
  - Uwaga: nie wprowadzaj MediatR dla trywialnego CRUD-a (YAGNI).
- **Options pattern (`IOptions<T>`)**
  - Sugeruj, gdy: konfiguracja czytana przez `IConfiguration["..."]`/stringi rozsiane po kodzie.
  - Uwaga: `IOptionsSnapshot`/`IOptionsMonitor` tylko gdy potrzebny reload.
- **Factory / Abstract Factory**
  - Sugeruj, gdy: złożona konstrukcja obiektów, `new` po typie w wielu miejscach, `switch` tworzący
    warianty.
- **Decorator (cross-cutting concerns)**
  - Sugeruj, gdy: logowanie/walidacja/cache/retry wplecione w logikę domenową — wydziel jako
    dekoratory (np. przez DI / Scrutor) zamiast `if` w metodach.
- **Specification pattern**
  - Sugeruj, gdy: powtarzane, składane reguły filtrowania/zapytań rozsiane po repozytoriach.
  - Uwaga: nie buduj frameworka specyfikacji dla jednego warunku (KISS).

## 2. Obsługa wyjątków .NET — twarde reguły

Wyjątki to **zachowanie zewnętrzne** — każda zmiana mechanizmu wymaga aktualizacji wszystkich
powiązanych miejsc i jest osobnym zadaniem (reguła ogólna #4).

| Wykrycie | Klasyfikacja | Akcja |
|----------|--------------|-------|
| `catch (Exception ex)` bez re-throw ani logowania (połknięty wyjątek) | **Błąd** | Zaloguj i/lub re-throw, albo świadomie obsłuż; nie połykaj |
| `throw new Exception(...)` zamiast wyjątku dziedzinowego/wbudowanego | **Ostrzeżenie** | Użyj custom/typowanego wyjątku (np. `DomainException`, `ArgumentException`) |
| `throw ex;` zamiast `throw;` (utrata stack trace) | **Błąd** | Zmień na `throw;`; przy zmianie sprawdź **wszystkie** bloki catch obok |
| Przejście wyjątki → `Result<T>` | **Krytyczne** | **WSZYSTKIE** call-site'y muszą obsłużyć `Result`; brak — regresja |
| Zasób `IDisposable` bez `using`/`finally`/dispose | **Błąd** | Owinąć w `using`/`await using` lub `try/finally` |
| `catch` zawężający typ szerzej niż trzeba (łapie za dużo) | **Ostrzeżenie** | Łap najwęższy sensowny typ |
| Wyjątek używany do sterowania normalnym przepływem | **Ostrzeżenie** | Rozważ `Result<T>`/guard zamiast wyjątku |

**Checklisty behaviour preservation (dla implementera/reviewera):**
- Zmiana `throw ex` → `throw`: zweryfikuj, że żaden catch w górę nie polega na zresetowanym
  stack trace; potwierdź testem, że typ/komunikat wyjątku bez zmian.
- Zmiana mechanizmu (wyjątki → Result): Grep po metodzie i jej wywołaniach; każdy call-site
  obsługuje sukces i błąd; testy ścieżek błędów zaktualizowane (ale nie „pod kod").

## 3. Aktualizacja call-site'ów (jak szukać)
- `grep`/`Grep` po nazwie metody, typie wyjątku, typie zwracanym.
- Sprawdź interfejsy/abstrakcje i ich implementacje (zmiana sygnatury = wszystkie implementacje).
- DI: zmiana rejestracji/lifetime może zmienić zachowanie — sprawdź `Program.cs`/moduły DI.

## 4. Narzędzia .NET (uruchamiane w skillach)
- **`dotnet build`** — weryfikacja kompilacji przed testami; napraw błędy kompilacji w obrębie zadania.
- **`dotnet test`** — uruchamianie testów po każdym zadaniu (ETAP 4) i w baseline (ETAP 3).
- **Stack testowy (preferowany):** **xUnit** + **FluentAssertions** + **Moq**.
  - xUnit: `[Fact]`/`[Theory]`; FluentAssertions: `result.Should().Be(...)`,
    `act.Should().Throw<TException>()`; Moq: `mock.Setup(...)`, `mock.Verify(...)`.
- **Cel pokrycia:** minimum **70%** dla refaktoryzowanego kodu — nowe testy baseline muszą to
  zapewnić (ETAP 3). Jeśli nieosiągalne, udokumentuj przyczynę w `test-baseline-report.md`.
- Pokrycie: `dotnet test --collect:"XPlat Code Coverage"` (coverlet), jeśli skonfigurowane;
  inaczej oznacz „brak danych".

## 5. Edge cases .NET
- **`async`/`await`:** nie połykaj `Task` (brak `await` = zgubione wyjątki); unikaj `.Result`/
  `.Wait()` (deadlocki). Testy async: `async Task` + `await`.
- **Wyjątki w `async`** opakowane są w `Task`; `Throw`/asercje muszą być na awaitowanej operacji.
- **Nullable reference types** (`#nullable enable`): zmiana adnotacji nullability to zmiana
  kontraktu — traktuj jak zmianę API.
- **Brak SDK/restore** → zgłoś blokadę (np. `dotnet restore` niemożliwy), nie raportuj fałszywego
  PASS.

## Integracja z gate'ami
Ten skill **nie ma własnego gate'u** — dostarcza wiedzy etapom, które gate'y posiadają (1–5).
Jego reguły wyjątków i checklisty zasilają w szczególności GATE 4 (behaviour preservation) i
GATE 5 (werdykt końcowy).
