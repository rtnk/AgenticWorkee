# project-hld-generator

Skill Claude Code: **interaktywny generator HLD i CLAUDE.md** dla istniejącego projektu.
Działa jak tech lead wchodzący do nowego repo — najpierw sam robi rekonesans kodu, potem
zadaje tylko pytania, na które kod nie odpowiada (max 5–7 tur po 1–3 pytania), a na końcu
generuje dokumentację gotową do commita.

## Co produkuje

1. **`docs/**/*.md`** — drzewiasta struktura HLD podzielona tematycznie: architecture
   (overview C4 + Mermaid, data model, ADR index), integrations, operations
   (deployment, runbook), development (conventions, testing, local setup).
2. **`CLAUDE.md`** w root repo — dense reference dla Claude Code: zweryfikowane komendy,
   falsyfikowalne konwencje, explicit zakazy, navigation hints. Budżet ~400–600 tokenów,
   mierzony i raportowany.

Język treści podąża za językiem odpowiedzi dewelopera (PL→PL, EN→EN); nazwy plików
i frontmatter zawsze po angielsku. Istniejąca dokumentacja (README, docs/, ADR) nie jest
nadpisywana — skill ją indeksuje i uzupełnia.

## Struktura

```
project-hld-generator/
├── SKILL.md                          # workflow 5 faz: rekonesans → Q&A → docs/ → CLAUDE.md → iteracja
├── references/
│   ├── doc-templates.md              # template'y wszystkich plików docs/ + ADR + szkielet CLAUDE.md
│   └── claude-md-patterns.md         # anty-wzorce CLAUDE.md, test falsyfikowalności, budżet tokenów
└── evals/
    ├── evals.json                    # 4 test case'y (skill-creator) ze skryptowanymi odpowiedziami Q&A
    └── fixtures/
        ├── dotnet-microservices/     # fixture: .NET 8, Api/Worker/Domain/Infrastructure, Kafka, Postgres
        └── node-monorepo/            # fixture: npm workspaces, istniejący README.md
```

## Instalacja

Skopiuj katalog skilla do lokalizacji skilli Claude Code, np.:

```bash
cp -r project-hld-generator ~/.claude/skills/
# lub w środowisku zarządzanym:
cp -r project-hld-generator /mnt/skills/
```

## Triggery

„wygeneruj HLD dla projektu", „stwórz dokumentację architektury", „zrób CLAUDE.md dla
tego repo", „onboard mnie do tego projektu", „udokumentuj architekturę systemu",
„zrób high-level design", "project documentation from codebase".
