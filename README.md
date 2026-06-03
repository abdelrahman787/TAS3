# Quran Tasmee3 (قرآن تسميع)

Voice-driven Quran memorization app. Words stay hidden and reveal only on correct recitation.

This monorepo contains Phase 1: the Quran data layer and page viewer.

## Structure

```
.
├── backend/           NestJS + TypeORM + PostgreSQL API
├── mobile/            Flutter app (Android + iOS)
└── docker-compose.yml Local dev stack (postgres + redis + backend)
```

## Quick start

```bash
# 1. Start backend stack
cd backend
cp .env.example .env
docker-compose up -d postgres redis
npm install
npm run migration:run
npm run seed          # fetches all 604 pages from Quran.com (~5 min)
npm run start:dev

# 2. Run Flutter app (in another terminal)
cd mobile
flutter pub get
flutter run
```

Backend listens on `http://localhost:3000`. Health check: `GET /health`.

## Phase 1 endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Service health |
| GET | `/quran/page/:n` | All words for page n (1–604) |
| GET | `/quran/surah/:n` | Surah metadata (name, ayah count, page range) |
| POST | `/sessions` | Create a recitation session |
| POST | `/sessions/:id/errors` | Log a batch of word errors |
| PATCH | `/sessions/:id/complete` | Finalize a session with stats |
| GET | `/analytics/progress` | Aggregate stats (sessions, accuracy, error totals) |
| GET | `/analytics/sessions` | Recent completed sessions (most recent first) |
| GET | `/analytics/difficult-words` | Words sorted by error count |

## Phase status

- ✅ **Phase 1** — Quran viewer (Mushaf RTL layout, page swipe, surah picker)
- ✅ **Phase 2** — Recitation engine (hide/reveal, Groq Whisper ASR, MatchingEngine, silence detection, manual reveal, session logging)
- ✅ **Phase 3** — Error handling polish (order-error detection, onboarding, settings screen, persisted preferences)
- ✅ **Phase 4** — Analytics (progress dashboard, difficult words, recent sessions)
- ⏳ **Phase 5** — Optimization (vocab boosting, polish, offline)
