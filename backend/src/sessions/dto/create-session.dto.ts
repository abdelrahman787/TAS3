import { Difficulty, ScopeType } from '../entities/session.entity';

export class CreateSessionDto {
  userId?: string;
  scope: {
    type: ScopeType;
    pageStart: number;
    pageEnd: number;
  };
  difficulty: Difficulty;
}

export class LogErrorsDto {
  errors: Array<{
    wordId: number;
    expectedWord: string;
    recognizedText?: string | null;
    errorType: 'forget' | 'substitution' | 'order_error' | 'pronunciation' | 'asr_failure';
    attemptCount: number;
    confidence?: number | null;
  }>;
}

export class CompleteSessionDto {
  endTime: string;
  stats: {
    totalWords: number;
    correctWords: number;
    forgottenWords: number;
    substitutions: number;
    orderErrors: number;
    pronunciationErrors: number;
  };
}
