# Backend tests

## Unit
`npm test` — runs Jest with `--passWithNoTests`. Add `*.spec.ts` next to
the file under test when needed.

## End-to-end
```bash
docker-compose up -d postgres        # or supply TEST_DATABASE_URL
TEST_DATABASE_URL=postgresql://admin:password@localhost:5432/quran_tasmee3 npm run test:e2e
```

Set `SKIP_E2E=1` to no-op the entire suite (used by CI until a Postgres
service container is wired). The schema relies on Postgres-specific
features (`gen_random_uuid()`, `FILTER` aggregates, `BIGSERIAL`) so
SQLite is not a viable substitute.

The suite assumes the `quran_words` table is seeded; an empty DB still
passes most cases but `GET /quran/page/1` will return an empty `words`
array.
