---
name: backend-testing
description: Load when writing or verifying tests for a .NET 10 service in the implementation phase (phase 5+). Defines the test stack confirmed from the repo (default xUnit, but verify NUnit/MSTest, FluentAssertions, Moq/NSubstitute), the unit-vs-integration split, AAA pattern, test naming and *.Tests layout, integration testing with WebApplicationFactory / Testcontainers, mapping every task acceptance criterion to a concrete test case, and the hard gates "build clean" and "tests green". Used by feature-test-author and feature-verifier.
---

# Backend Testing (konwencje testów .NET 10)

Ten skill definiuje, **jak pisać i oceniać testy** w fazie implementacyjnej dla usługi
.NET 10. Ładowany razem z `backend-impl-conventions` (która idzie pierwsza).

## 1. Stack testowy — potwierdzany z repo

Domyślnie zakładaj **xUnit**, ale **zawsze potwierdź z repozytorium** zanim napiszesz
test — nie zakładaj na sztywno:

- **Framework testów**: xUnit (`[Fact]`/`[Theory]`) vs NUnit (`[Test]`) vs MSTest
  (`[TestMethod]`). Sprawdź `*.Tests.csproj` (referencje pakietów) i istniejące testy.
- **Asercje**: FluentAssertions (`result.Should().Be(...)`) vs natywne `Assert.*`.
- **Mocki/fakes**: Moq (`new Mock<T>()`) vs NSubstitute (`Substitute.For<T>()`) vs ręczne
  fakes.
- **Pomocnicze**: `Bogus`/buildery danych, `Respawn`/`Testcontainers`, `FakeTimeProvider`.

Wybór sprawdzasz przez: referencje w `*.Tests.csproj`, `using`-i i wzorce w istniejących
testach, ewentualnie `CLAUDE.md`. Nowe testy piszesz w **stylu już obecnym w repo**.
Jeśli repo nie ma jeszcze testów, użyj domyślnego stosu (xUnit + FluentAssertions) i
oznacz to jako `[ZAŁOŻENIE]` w podsumowaniu.

## 2. Unit vs integration

- **Unit**: pojedyncza jednostka (handler, encja domenowa, walidator, serwis) w izolacji;
  zależności zamockowane; bez I/O, bez bazy, bez sieci; szybkie i deterministyczne.
- **Integration**: realne złożenie warstw przez granicę (API → handler → repo → baza/
  kolejka). Wolniejsze; uruchamiane przeciw realnym lub kontenerowym zależnościom.
- Wybór poziomu wynika z **kryterium akceptacji** taska: regułę domenową testuj unitowo;
  kontrakt endpointu lub zapis do bazy — integracyjnie.

## 3. Wzorzec AAA, nazewnictwo i układ projektów

- **AAA**: `// Arrange` → `// Act` → `// Assert`. Jedno logiczne zachowanie na test.
- **Nazewnictwo** (dopasuj do repo; typowo): `Metoda_Warunek_OczekiwanyWynik`, np.
  `Handle_WhenLimitExceeded_ReturnsRejected`. Nazwy testów po angielsku (artefakt
  narzędziowy), opisy/komentarze pomocnicze mogą być po polsku.
- **Układ**: projekty `*.Tests` lustrzane do produkcyjnych, np. `Domain` →
  `Domain.Tests`, `Application` → `Application.Tests`, integracyjne np.
  `Api.IntegrationTests`. Plik testów = klasa/feature testowany. Zachowaj konwencję repo.

## 4. Testy integracyjne

- **HTTP / API**: `WebApplicationFactory<TEntryPoint>` (pakiet
  `Microsoft.AspNetCore.Mvc.Testing`) — uruchamia hosta w pamięci, testuje realny
  pipeline (routing, walidacja, auth, serializacja). Podmieniaj zależności przez
  `WithWebHostBuilder`/`ConfigureTestServices`.
- **Infrastruktura** (gdy task tego dotyczy): **Testcontainers** dla MS SQL Server,
  Kafka, Redis — realny silnik w kontenerze zamiast mocka, gdy weryfikujemy migracje,
  zapytania EF Core, produkcję/konsumpcję eventów czy zachowanie cache/TTL.
- Integrację stosuj **tylko** gdy kryterium akceptacji jej wymaga; w innym wypadku
  preferuj szybszy test unitowy.

## 5. Mapowanie kryteriów akceptacji → testy

Twarda reguła fazy 5+: **każde** kryterium akceptacji taska (`- [ ]` w `tasks.md`) ma
co najmniej **jeden konkretny przypadek testowy**.

- Prowadź jawną tabelę mapowania w podsumowaniu (autor testów i weryfikator):

  ```
  | Kryterium akceptacji (task) | Test (klasa.metoda) | Poziom |
  |-----------------------------|---------------------|--------|
  | Po przekroczeniu limitu wypłata odrzucona | WithdrawalHandlerTests.Handle_WhenLimitExceeded_ReturnsRejected | unit |
  | Endpoint zwraca 409 przy odrzuceniu | WithdrawalApiTests.Post_OverLimit_Returns409 | integration |
  ```

- Kryterium bez odpowiadającego testu = luka pokrycia → task **nie** może przejść do
  `done`.
- Uwzględniaj scenariusze brzegowe i błędne z `spec.md` (§8 Przepływy, §13 Testowanie),
  nie tylko happy path.

## 6. Twarde bramki: „testy zielone" i „build czysty"

To bramki, nie zalecenia. Weryfikator orzeka je obiektywnie:

- **Build czysty** = `dotnet build` kończy się sukcesem, **bez błędów**; ostrzeżenia
  traktuj zgodnie z konfiguracją repo (jeśli `TreatWarningsAsErrors`, to też blokują).
- **Testy zielone** = `dotnet test` przechodzi w 100% (0 failed, 0 errored). Testy
  pominięte (`skipped`) wymagają uzasadnienia — domyślnie traktuj jako niespełnioną
  bramkę.
- **Faza RED (autor testów)**: na tym etapie testy mają **failować z właściwego powodu**
  (brakująca implementacja: nieistniejący typ/metoda, asercja niespełniona), a nie
  z przypadkowego błędu kompilacji w niepowiązanym miejscu. Potwierdź czerwień jednym
  uruchomieniem i opisz powód failu.
- Reszta projektu (testy spoza zakresu taska) musi pozostać zielona — nie psujesz
  istniejącego zestawu.
