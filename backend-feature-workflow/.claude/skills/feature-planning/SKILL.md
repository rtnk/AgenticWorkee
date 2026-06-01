---
name: feature-planning
description: Load when turning a ready feature specification into an implementation plan (plan.md) for a .NET 10 service. Defines the plan.md format — approach, layer/component decomposition, ordering & milestones, dependencies, technical risks, spikes — with a ready-to-copy markdown skeleton. Used by feature-planner.
---

# Feature Planning — szablon `plan.md`

Ten skill definiuje format **planu wdrożenia** wyprowadzonego z gotowej (`status: ready`)
specyfikacji. Plan opisuje **strategię i kolejność budowy**, nie sam kod. Implementacja jest
poza zakresem — plan jest mostem między `spec.md` a `tasks.md`.

Stosuj reguły ze skilla `backend-doc-conventions` (polski, „nie zgaduj — dopytaj”, notacja
założeń/otwartych kwestii, zapis tylko do `docs/features/<slug>/`).

## Reguły wypełniania

- Plan wynika **wyłącznie** z `spec.md`. Każda pozycja planu musi mapować się na sekcję specyfikacji.
- Dekompozycja po warstwach .NET (potwierdź układ z repo): **API → aplikacja/handlery → domena →
  infrastruktura/dane**. Jeśli repo ma inny podział — użyj jego.
- Kolejność = realna zależność „co musi powstać przed czym” (kontrakty i model danych zwykle wcześnie).
- Otwarte kwestie ze spec (`[DO USTALENIA]`) przenieś do punktów decyzyjnych / spike'ów i oznacz
  jako blokujące. Nie planuj na ślepo wokół nierozstrzygniętej decyzji.

## Artefakty pomocnicze planu (wydzielone)

Oprócz `plan.md` faza 3 wydziela **maszynowo czytelne / łatwe do zdiffowania** artefakty do
`docs/features/<slug>/` (twórz tylko te, które dotyczą feature):

- **`contracts/`** — kontrakty API jako osobne pliki: `api-spec.json` (OpenAPI) lub `*.md` dla
  komend/eventów. Źródłem prawdy o kontrakcie staje się ten plik; `spec.md §6` go streszcza i linkuje.
- **`data-model.md`** — szczegółowy model danych (tabele, kolumny, klucze, indeksy, migracje EF);
  `spec.md §7` go streszcza i linkuje.
- **`research.md`** (opcjonalnie) — wynik spike'ów / decyzji technicznych z porównaniem opcji.

Te pliki pozwalają `feature-test-author` generować testy kontraktowe, a `feature-verifier`
porównywać implementację z kontraktem maszynowo. Jeśli feature jest trywialne — można zostawić
kontrakt inline w spec i pominąć wydzielanie (odnotuj to jako `[ZAŁOŻENIE]`).

## Bramka prostoty i zgodności z konstytucją

Jeśli istnieje `docs/constitution.md`:

- Sprawdź, czy plan **nie łamie** zasad `P-*` — w szczególności **bramkę prostoty** (P-15/P-16:
  brak „future-proofing", używaj frameworka wprost, limit liczby projektów, brak zbędnych abstrakcji).
- Każde odstępstwo od konstytucji **musi** trafić do sekcji **„8. Complexity Tracking"** planu z
  uzasadnieniem — albo plan zostaje uproszczony. Cicha nadmiarowa architektura jest niedopuszczalna.
- Brak konstytucji nie blokuje planu, ale wtedy stosuj domyślny minimalizm (YAGNI) jawnie.

## Szkielet do skopiowania

```markdown
# Plan wdrożenia: <Nazwa feature>

- **Slug**: <kebab-case>
- **Na podstawie**: spec.md (status: ready, data: <YYYY-MM-DD>)
- **Data**: <YYYY-MM-DD>

## 1. Podejście / strategia
- <ogólna strategia: np. najpierw kontrakty + model danych, potem handlery za feature flagą>
- <zasady przekrojowe: backward-compat, migracje rozłączne, idempotencja>

## 2. Dekompozycja na komponenty/warstwy
- **API**: <endpointy/kontrakty do dodania/zmiany>
- **Aplikacja / handlery**: <komendy, query, pipeline behaviors, walidacja>
- **Domena**: <encje, reguły, agregaty, eventy domenowe>
- **Infrastruktura / dane**: <repozytoria, migracje EF, integracje Kafka/Redis/HTTP>
- **Przekrojowe**: <obserwowalność, bezpieczeństwo, feature flags, konfiguracja>

## 3. Kolejność i kamienie milowe
- **M1 — <nazwa>**: <co musi być gotowe; kryterium ukończenia>
- **M2 — <nazwa>**: <...>
- **M3 — <nazwa>**: <...>
> Reguła: kontrakty API i model danych powstają przed logiką, która z nich korzysta.

## 4. Zależności
| Element | Zależy od | Uwagi |
|---------|-----------|-------|
| <element planu> | <element/-y> | <np. blokuje, równoległe> |

## 5. Ryzyka techniczne i mitigacje
| Ryzyko | Prawdopodobieństwo | Wpływ | Mitigacja |
|--------|--------------------|-------|-----------|
| <opis> | niskie/śr./wys. | niski/śr./wys. | <działanie> |

## 6. Spike'i / punkty decyzyjne
- **S-1: <pytanie/research>** — cel, kryterium zakończenia, czy blokuje implementację.
  - Powiązane `[DO USTALENIA]` ze spec: <odniesienie>

## 7. Mapowanie plan → spec
| Pozycja planu | Sekcja(e) spec.md |
|---------------|-------------------|
| <pozycja> | <np. §6 Kontrakty API, §7 Model danych> |

## 8. Complexity Tracking (odstępstwa od konstytucji)
> Wypełniaj tylko, gdy plan świadomie odstępuje od zasady `P-*` z `docs/constitution.md`.
> Brak odstępstw → „Brak — plan zgodny z konstytucją."

| Zasada | Odstępstwo | Uzasadnienie | Prostsza odrzucona opcja |
|--------|-----------|--------------|--------------------------|
| P-<n> | <co łamiemy> | <dlaczego konieczne> | <co i czemu odrzucono> |

## 9. Wydzielone artefakty
- Kontrakty: `contracts/<plik>` — <co zawiera> | „inline w spec §6".
- Model danych: `data-model.md` — <zakres> | „inline w spec §7".
- Research/spike'i: `research.md` — <co> | „nie dotyczy".
```
