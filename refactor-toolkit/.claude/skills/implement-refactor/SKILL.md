---
name: implement-refactor
description: ETAP 4 — bezpieczna implementacja zadań z zaakceptowanego refactor-plan.md, zadanie po zadaniu, z uruchamianiem testów po KAŻDYM zadaniu i zachowaniem zachowania zewnętrznego (behaviour preservation). Trigger — /refactor-continue po GATE 3 lub kontynuacja kolejnego zadania. Używany przez subagenta refactor-implementer. Kończy na GATE 4 po każdym zadaniu.
---

# implement-refactor — bezpieczna implementacja zmian

**Trigger:** `/refactor-continue` po zaakceptowanym GATE 3, albo kontynuacja kolejnego zadania
po GATE 4. Wymaga zaakceptowanego `refactor-plan.md` i zielonego baseline testów.

Realizujesz plan w małych, bezpiecznych krokach z testami jako siatką. Dewiza: **Behaviour
Preservation First** — refaktoryzacja nie zmienia zachowania zewnętrznego.

## Kroki
1. **Wczytaj plan i baseline.** Brak zaakceptowanego planu → STOP (reguła #2). Brak zielonego
   baseline → wróć do ETAPU 3.
2. **Wybierz JEDNO zadanie** zgodnie z kolejnością z planu (lub wskazane przez użytkownika).
3. **Zaimplementuj minimalnie** to zadanie — najmniejsza zmiana realizująca jego kryterium
   ukończenia. Trzymaj się zakresu zadania; nie poszerzaj.
4. **Pilnuj zachowania zachowania:**
   - **mechanizm wyjątków** → zaktualizuj **wszystkie** powiązane bloki `catch`/obsługi
     (Grep po typach wyjątków, call-site'ach); patrz `dotnet-patterns`,
   - **Extract Method/Class** → publiczne sygnatury bez zmian bez powodu z planu,
   - **zmiana typu zwracanego** (np. → `Result<T>`) → prześledź i zaktualizuj **wszystkie** wywołania,
   - **zasoby** → zachowaj `using`/`finally`/dispose.
5. **Uruchom pełny zestaw testów** (`dotnet test`/runner). **Muszą przejść.**
6. **Jeśli czerwone → STOP.** Zgłoś użytkownikowi: które zadanie, który test, prawdopodobna
   przyczyna. **Nie** modyfikuj testów, by je „naprawić" (reguła #3) — czerwień = błąd w refaktorze.
7. **Pokaż diff + zielony wynik testów** dla zadania (commit per zadanie, jeśli git).

## Format outputu
- Zmiany w kodzie produkcyjnym (diff/commit per zadanie).
- Konsola po każdym zadaniu:
  ```
  Zadanie N: <nazwa> — DONE
  Pliki: <lista>
  Testy: <X passed> (PASS)
  Behaviour preservation: <potwierdzenie / zaktualizowane call-site'y>
  ```

## Obsługa błędów i edge cases
- **Testy czerwone po zmianie** → STOP, raport do użytkownika; nigdy nie dopasowuj testów.
- **Zadanie wymaga decyzji spoza planu** → STOP, zapytaj; nie zgaduj projektowo.
- **Zmiana okazuje się szersza niż jedno zadanie** → zatrzymaj się, zaproponuj rozbicie/aktualizację
  planu (powrót do plannera), zamiast „przemycać" zakres.
- **Build nie kompiluje** (np. .NET) → napraw błędy kompilacji w obrębie zadania, dopiero potem testy.
- **Brak commitów/git** → zachowaj czytelny diff w odpowiedzi; nie wymuszaj operacji git bez zgody.

## Integracja z gate'ami
Po **każdym** zadaniu **STOP na GATE 4**: pokaż diff i zielone testy, poproś o akceptację przed
kolejnym zadaniem (`/refactor-continue`). Po ostatnim zadaniu → przejście do ETAPU 5 (review).
Nie łączysz zadań bez testów pomiędzy nimi (reguła #6).
