import 'reflect-metadata';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import request from 'supertest';

import { AuthModule } from '../src/auth/auth.module';
import { QuranModule } from '../src/quran/quran.module';
import { SessionsModule } from '../src/sessions/sessions.module';
import { AnalyticsModule } from '../src/analytics/analytics.module';
import { AsrModule } from '../src/asr/asr.module';
import { HealthController } from '../src/health/health.controller';
import { QuranWord } from '../src/quran/entities/quran-word.entity';
import { Session } from '../src/sessions/entities/session.entity';
import { SessionError } from '../src/sessions/entities/session-error.entity';
import { User } from '../src/auth/entities/user.entity';

const TEST_DB_URL =
  process.env.TEST_DATABASE_URL ??
  process.env.DATABASE_URL ??
  'postgresql://admin:password@localhost:5432/quran_tasmee3';

const skipE2e = process.env.SKIP_E2E === '1';
const describeOrSkip = skipE2e ? describe.skip : describe;

describeOrSkip('Quran Tasmee3 e2e', () => {
  let app: INestApplication;
  let token: string;
  const uniqueEmail = `e2e-${Date.now()}@qurantasmee3.app`;
  const password = 'super-secret-pw';

  beforeAll(async () => {
    process.env.JWT_SECRET = 'e2e-test-secret';
    const moduleRef = await Test.createTestingModule({
      imports: [
        TypeOrmModule.forRoot({
          type: 'postgres',
          url: TEST_DB_URL,
          entities: [QuranWord, Session, SessionError, User],
          synchronize: false,
        }),
        AuthModule,
        QuranModule,
        SessionsModule,
        AnalyticsModule,
        AsrModule,
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

  // ── Phase 1–4 endpoints ──────────────────────────────────────────
  it('GET /health → 200 ok', async () => {
    const res = await request(app.getHttpServer()).get('/health').expect(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('GET /quran/page/1 → 200', async () => {
    const res = await request(app.getHttpServer()).get('/quran/page/1').expect(200);
    expect(res.body.page).toBe(1);
    expect(Array.isArray(res.body.words)).toBe(true);
  });

  it('GET /quran/page/605 → 404', async () => {
    await request(app.getHttpServer()).get('/quran/page/605').expect(404);
  });

  it('GET /quran/surah/1 → 200', async () => {
    const res = await request(app.getHttpServer()).get('/quran/surah/1').expect(200);
    expect(res.body.surah).toBe(1);
  });

  it('GET /quran/surah/115 → 404', async () => {
    await request(app.getHttpServer()).get('/quran/surah/115').expect(404);
  });

  // ── Auth ─────────────────────────────────────────────────────────
  it('POST /auth/register valid → 201 with accessToken', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email: uniqueEmail, password, displayName: 'E2E' })
      .expect(201);
    expect(typeof res.body.accessToken).toBe('string');
    expect(res.body.user.email).toBe(uniqueEmail);
    token = res.body.accessToken;
  });

  it('POST /auth/register duplicate email → 409', async () => {
    await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email: uniqueEmail, password, displayName: 'E2E' })
      .expect(409);
  });

  it('POST /auth/login valid → 200 with accessToken', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: uniqueEmail, password })
      .expect(200);
    expect(typeof res.body.accessToken).toBe('string');
  });

  it('POST /auth/login wrong password → 401', async () => {
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: uniqueEmail, password: 'wrong-password' })
      .expect(401);
  });

  it('GET /auth/me without token → 401', async () => {
    await request(app.getHttpServer()).get('/auth/me').expect(401);
  });

  it('GET /auth/me with valid token → 200', async () => {
    const res = await request(app.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(res.body.email).toBe(uniqueEmail);
  });

  // ── Sessions are now guarded ────────────────────────────────────
  it('POST /sessions without token → 401', async () => {
    await request(app.getHttpServer())
      .post('/sessions')
      .send({
        scope: { type: 'page', pageStart: 1, pageEnd: 1 },
        difficulty: 'normal',
      })
      .expect(401);
  });

  it('POST /sessions with valid token → 201', async () => {
    const res = await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${token}`)
      .send({
        scope: { type: 'page', pageStart: 1, pageEnd: 1 },
        difficulty: 'normal',
      })
      .expect(201);
    expect(typeof res.body.sessionId).toBe('string');
  });

  it('POST /sessions missing pageStart → 400 (5a.1 pipe still works)', async () => {
    await request(app.getHttpServer())
      .post('/sessions')
      .set('Authorization', `Bearer ${token}`)
      .send({ scope: { type: 'page', pageEnd: 1 }, difficulty: 'normal' })
      .expect(400);
  });

  // ── Analytics (optional auth) ────────────────────────────────────
  it('GET /analytics/progress without token → 200 (anonymous aggregate)', async () => {
    const res = await request(app.getHttpServer())
      .get('/analytics/progress')
      .expect(200);
    expect(typeof res.body.sessionCount).toBe('number');
  });

  it('GET /analytics/difficult-words with token → 200 array', async () => {
    const res = await request(app.getHttpServer())
      .get('/analytics/difficult-words')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  // ── ASR proxy ────────────────────────────────────────────────────
  // The happy path (token + valid audio + actual Groq call) is intentionally
  // not exercised here — it would require a real GROQ_API_KEY and would
  // make CI flaky. We assert the auth wall, the file-required wall and the
  // mimetype wall; the upstream behaviour is covered by AsrService unit
  // tests once Groq is mockable.
  it('POST /asr/transcribe without token → 401', async () => {
    await request(app.getHttpServer())
      .post('/asr/transcribe')
      .expect(401);
  });

  it('POST /asr/transcribe with token but no file → 400', async () => {
    await request(app.getHttpServer())
      .post('/asr/transcribe')
      .set('Authorization', `Bearer ${token}`)
      .expect(400);
  });

  it('POST /asr/transcribe with token + wrong mimetype → 400', async () => {
    await request(app.getHttpServer())
      .post('/asr/transcribe')
      .set('Authorization', `Bearer ${token}`)
      .attach('audio', Buffer.from('not-real-audio'), {
        filename: 'audio.txt',
        contentType: 'text/plain',
      })
      .expect(400);
  });
});
