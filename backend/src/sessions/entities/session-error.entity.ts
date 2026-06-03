import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Session } from './session.entity';

export type ErrorType =
  | 'forget'
  | 'substitution'
  | 'order_error'
  | 'pronunciation'
  | 'asr_failure';

@Entity('session_errors')
@Index('idx_session_errors_session', ['session'])
@Index('idx_session_errors_word', ['wordId'])
export class SessionError {
  @PrimaryGeneratedColumn('increment', { type: 'bigint' })
  id: string;

  @ManyToOne(() => Session, (s) => s.errors, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'session_id' })
  session: Session;

  @Column('int', { name: 'word_id' })
  wordId: number;

  @Column('varchar', { length: 120, name: 'expected_word' })
  expectedWord: string;

  @Column('varchar', { length: 255, name: 'recognized_text', nullable: true })
  recognizedText: string | null;

  @Column('varchar', { length: 32, name: 'error_type' })
  errorType: ErrorType;

  @Column('int', { name: 'attempt_count', default: 1 })
  attemptCount: number;

  @Column('float', { nullable: true })
  confidence: number | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
