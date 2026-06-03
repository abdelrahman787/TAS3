import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Session } from '../sessions/entities/session.entity';
import { SessionError } from '../sessions/entities/session-error.entity';

@Injectable()
export class AnalyticsService {
  constructor(
    @InjectRepository(Session) private readonly sessions: Repository<Session>,
    @InjectRepository(SessionError) private readonly errors: Repository<SessionError>,
  ) {}

  /// List recent sessions (most recent first). Optionally scoped to a user.
  async listSessions(userId?: string, limit = 50) {
    const qb = this.sessions
      .createQueryBuilder('s')
      .where('s.ended_at IS NOT NULL')
      .orderBy('s.created_at', 'DESC')
      .limit(limit);
    if (userId) {
      qb.andWhere('s.user_id = :userId', { userId });
    } else {
      qb.andWhere('s.user_id IS NULL');
    }
    const rows = await qb.getMany();
    return rows.map((s) => ({
      id: s.id,
      createdAt: s.createdAt,
      endedAt: s.endedAt,
      pageStart: s.pageStart,
      pageEnd: s.pageEnd,
      difficulty: s.difficulty,
      totalWords: s.totalWords,
      correctWords: s.correctWords,
      forgottenWords: s.forgottenWords,
      substitutions: s.substitutions,
      orderErrors: s.orderErrors,
      pronunciationErrors: s.pronunciationErrors,
      accuracy:
        s.totalWords && s.totalWords > 0
          ? (s.correctWords ?? 0) / s.totalWords
          : null,
    }));
  }

  /// Overall stats (totals and rolling averages).
  async getProgress(userId?: string) {
    const qb = this.sessions
      .createQueryBuilder('s')
      .select('COUNT(*)', 'sessionCount')
      .addSelect('COALESCE(SUM(s.total_words),0)', 'totalWords')
      .addSelect('COALESCE(SUM(s.correct_words),0)', 'correctWords')
      .addSelect('COALESCE(SUM(s.forgotten_words),0)', 'forgottenWords')
      .addSelect('COALESCE(SUM(s.substitutions),0)', 'substitutions')
      .addSelect('COALESCE(SUM(s.order_errors),0)', 'orderErrors')
      .addSelect('COALESCE(SUM(s.pronunciation_errors),0)', 'pronunciationErrors')
      .where('s.ended_at IS NOT NULL');
    if (userId) {
      qb.andWhere('s.user_id = :userId', { userId });
    } else {
      qb.andWhere('s.user_id IS NULL');
    }
    const row = await qb.getRawOne();
    const total = Number(row.totalWords);
    const correct = Number(row.correctWords);
    return {
      sessionCount: Number(row.sessionCount),
      totalWords: total,
      correctWords: correct,
      forgottenWords: Number(row.forgottenWords),
      substitutions: Number(row.substitutions),
      orderErrors: Number(row.orderErrors),
      pronunciationErrors: Number(row.pronunciationErrors),
      accuracy: total > 0 ? correct / total : 0,
    };
  }

  /// Most-error-prone words.
  async getDifficultWords(userId?: string, limit = 20) {
    const qb = this.errors
      .createQueryBuilder('e')
      .innerJoin('e.session', 's')
      .select('e.word_id', 'wordId')
      .addSelect('e.expected_word', 'expectedWord')
      .addSelect('COUNT(*)::int', 'errorCount')
      .addSelect(`COUNT(*) FILTER (WHERE e.error_type = 'forget')::int`, 'forgetCount')
      .addSelect(`COUNT(*) FILTER (WHERE e.error_type = 'substitution')::int`, 'substitutionCount')
      .addSelect(`COUNT(*) FILTER (WHERE e.error_type = 'order_error')::int`, 'orderErrorCount')
      .addSelect(`COUNT(*) FILTER (WHERE e.error_type = 'pronunciation')::int`, 'pronunciationCount')
      .groupBy('e.word_id')
      .addGroupBy('e.expected_word')
      .orderBy('COUNT(*)', 'DESC')
      .limit(limit);
    if (userId) {
      qb.andWhere('s.user_id = :userId', { userId });
    } else {
      qb.andWhere('s.user_id IS NULL');
    }
    return qb.getRawMany();
  }
}
