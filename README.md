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

## What's NOT in Phase 1

ASR, recitation, word hiding/revealing, error logging, analytics, auth — those come in later phases.
