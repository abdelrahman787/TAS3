import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Session } from './entities/session.entity';
import { SessionError } from './entities/session-error.entity';
import { CompleteSessionDto, CreateSessionDto, LogErrorsDto } from './dto/create-session.dto';

@Injectable()
export class SessionsService {
  constructor(
    @InjectRepository(Session) private readonly sessions: Repository<Session>,
    @InjectRepository(SessionError) private readonly errors: Repository<SessionError>,
  ) {}

  async create(dto: CreateSessionDto, userId: string) {
    const session = this.sessions.create({
      userId,
      scopeType: dto.scope.type,
      pageStart: dto.scope.pageStart,
      pageEnd: dto.scope.pageEnd,
      difficulty: dto.difficulty,
    });
    const saved = await this.sessions.save(session);
    return { sessionId: saved.id, createdAt: saved.createdAt.toISOString() };
  }

  async logErrors(sessionId: string, dto: LogErrorsDto, userId: string) {
    const session = await this._loadOwned(sessionId, userId);

    const rows = dto.errors.map((e) =>
      this.errors.create({
        session,
        wordId: e.wordId,
        expectedWord: e.expectedWord,
        recognizedText: e.recognizedText ?? null,
        errorType: e.errorType,
        attemptCount: e.attemptCount,
        confidence: e.confidence ?? null,
      }),
    );
    await this.errors.save(rows);
    return { logged: rows.length };
  }

  async complete(sessionId: string, dto: CompleteSessionDto, userId: string) {
    const session = await this._loadOwned(sessionId, userId);

    session.endedAt = new Date(dto.endTime);
    session.totalWords = dto.stats.totalWords;
    session.correctWords = dto.stats.correctWords;
    session.forgottenWords = dto.stats.forgottenWords;
    session.substitutions = dto.stats.substitutions;
    session.orderErrors = dto.stats.orderErrors;
    session.pronunciationErrors = dto.stats.pronunciationErrors;
    await this.sessions.save(session);
    return { ok: true };
  }

  private async _loadOwned(sessionId: string, userId: string) {
    const session = await this.sessions.findOne({ where: { id: sessionId } });
    if (!session) throw new NotFoundException('Session not found');
    if (session.userId && session.userId !== userId) {
      throw new ForbiddenException('Session belongs to another user');
    }
    return session;
  }
}
