# sql-prep — Postgres Interview Coach

A self-contained SQL interview practice system: it teaches you to *learn*,
not to copy answers.

- **Socratic coach skill** for AI agents (opencode, Claude Code, Cursor, ...)
  that grades nothing for you — hints, prompts, and interviewer-style pressure
  instead.
- **Practice Postgres database** that seeds itself with realistic, messy
  e-commerce/HR data on first boot.
- **File-based exercises** — your attempts and outputs are kept on disk, so
  every agent session picks up where the last one stopped.
- Falls back to a local SQLite database if you don't have Docker running.
- **Note**: everything is Postgres-flavored (it's Postgres 17, not MySQL).

## Requirements

- Docker
- An AI agent that supports the skills format (npx comes with Node.js)

## Setup (npx only)

Install the coach skill for your agent:

```bash
npx skills add <your-github-username>/sql-prep@sql-interview-coach
```

Then in your agent: *"start SQL interview coaching"*. The coach bootstraps
its own Postgres container on first run (writes the compose file, starts it,
loads the practice dataset), then runs a short 5-question assessment to place
you in the curriculum. Your data persists across sessions — reboot safe, and
re-seeding after a machine wipe is one command.

## Setup (full repo alternative)

```bash
git clone https://github.com/<your-github-username>/sql-prep
cd sql-prep
docker compose up -d db   # first boot auto-seeds the practice dataset
```

Then install the skill the same way (or point your agent at the skill kept in
`.opencode/skills/sql-interview-coach/`).

## No agent? Still usable

- pgAdmin UI: http://localhost:5050 (login `admin@example.com` /
  `adminpassword`), server `db`
- raw psql: `docker exec -it postgres_db psql -U myuser -d mydatabase`

The curriculum and coaching method are in
[`.opencode/skills/sql-interview-coach/SKILL.md`](.opencode/skills/sql-interview-coach/SKILL.md) —
useful for self-study too.

## How practice works

- Coach creates/updates `progress.md` (assessment, topics, recurring slips)
- Exercises appear under `practice/exercises/NN-slug/`
  (`problem.md`, `attempt.sql`, `output.out` — yours, not committed)
- All attempts run against Postgres wrapped in a transaction + rollback, so
  the seed data is never mutated by accident
- Wrong answers are debugged by comparing your actual output against
  expected, never by being handed the fix
- Mock interview mode: silent interviewer, one question at a time, realistic
  problem statements

## Dataset

10 customers, 10 products, 18 orders, 22 line items, 12 employees across
5 departments, and 10 shipments. Deliberately dirty: NULL emails/cities/
totals, cancelled and returned orders, near-duplicate orders, products never
ordered, employees without departments, an order with no shipment row,
mismatched order totals. Ideal for anti-joins, dedup exercises, window
functions, gaps-and-islands, and interview traps.

11 curriculum stages, from SELECT/WHERE foundations through window functions
to EXPLAIN ANALYZE performance.

## Stack

- Postgres 17 (Docker)
- pgAdmin 4
- One skill at `.opencode/skills/sql-interview-coach/` — discovered
  recursively by `npx skills add` and adaptable to any skills-format agent
