import 'reflect-metadata';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import request from 'supertest';

import { QuranModule } from '../src/quran/quran.module';
import { SessionsModule } from '../src/sessions/sessions.module';
import { AnalyticsModule } from '../src/analytics/analytics.module';
import { HealthController } from '../src/health/health.controller';
import { QuranWord } from '../src/quran/entities/quran-word.entity';
import { Session } from '../src/sessions/entities/session.entity';
import { SessionError } from '../src/sessions/entities/session-error.entity';

// E2E tests run against a real PostgreSQL instance.
// Set TEST_DATABASE_URL to a clean DB; defaults to local docker-compose dev DB.
// SQLite-in-memory cannot host these tests because the schema uses pg-specific
// features (gen_random_uuid, FILTER aggregates, BIGSERIAL).
const TEST_DB_URL =
  process.env.TEST_DATABASE_URL ??
  process.env.DATABASE_URL ??
  'postgresql://admin:password@localhost:5432/quran_tasmee3';

// CI guard: when SKIP_E2E=1 the entire suite is no-op. The CI workflow sets
// this when no Postgres service is available so `npm run test:e2e` still
// exits zero. TODO: spin up a postgres service container in CI to drop this.
const skipE2e = process.env.SKIP_E2E === '1';
const describeOrSkip = skipE2e ? describe.skip : describe;

describeOrSkip('Quran Tasmee3 e2e', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [
        TypeOrmModule.forRoot({
          type: 'postgres',
          url: TEST_DB_URL,
          entities: [QuranWord, Session, SessionError],
          synchronize: false,
        }),
        QuranModule,
        SessionsModule,
        AnalyticsModule,
      ],
      controllers: [HealthController],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
  });

  afterAll(async () => {
    await app?.close();
  });

  it('GET /health → 200 ok', async () => {
    const res = await request(app.getHttpServer()).get('/health').expect(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('GET /quran/page/1 → 200 with page=1 and words array', async () => {
    const res = await request(app.getHttpServer()).get('/quran/page/1').expect(200);
    expect(res.body.page).toBe(1);
    expect(Array.isArray(res.body.words)).toBe(true);
  });

  it('GET /quran/page/605 → 404 (out of range)', async () => {
    // Service throws NotFoundException for >604 — Nest maps to 404.
    await request(app.getHttpServer()).get('/quran/page/605').expect(404);
  });

  it('GET /quran/surah/1 → 200', async () => {
    const res = await request(app.getHttpServer()).get('/quran/surah/1').expect(200);
    expect(res.body.surah).toBe(1);
  });

  it('GET /quran/surah/115 → 404 (out of range)', async () => {
    await request(app.getHttpServer()).get('/quran/surah/115').expect(404);
  });

  it('POST /sessions with valid body → 201', async () => {
    const res = await request(app.getHttpServer())
      .post('/sessions')
      .send({
        scope: { type: 'page', pageStart: 1, pageEnd: 1 },
        difficulty: 'normal',
      })
      .expect(201);
    expect(typeof res.body.sessionId).toBe('string');
  });

  it('POST /sessions missing pageStart → 400 (validates 5a.1 pipe)', async () => {
    await request(app.getHttpServer())
      .post('/sessions')
      .send({
        scope: { type: 'page', pageEnd: 1 },
        difficulty: 'normal',
      })
      .expect(400);
  });

  it('POST /sessions with extra field → 400 (whitelist enforced)', async () => {
    await request(app.getHttpServer())
      .post('/sessions')
      .send({
        scope: { type: 'page', pageStart: 1, pageEnd: 1 },
        difficulty: 'normal',
        injectedField: 'malicious',
      })
      .expect(400);
  });

  it('GET /analytics/progress → 200', async () => {
    const res = await request(app.getHttpServer()).get('/analytics/progress').expect(200);
    expect(typeof res.body.sessionCount).toBe('number');
  });

  it('GET /analytics/difficult-words → 200 array', async () => {
    const res = await request(app.getHttpServer())
      .get('/analytics/difficult-words')
      .expect(200);
    expect(Array.isArray(res.body)).toBe(true);
  });
});
