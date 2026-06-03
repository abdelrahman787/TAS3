import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { SessionError } from './session-error.entity';

export type ScopeType = 'page' | 'surah' | 'range';
export type Difficulty = 'easy' | 'normal' | 'strict';

@Entity('sessions')
export class Session {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('varchar', { length: 64, nullable: true, name: 'user_id' })
  userId: string | null;

  @Column('varchar', { length: 16, name: 'scope_type' })
  scopeType: ScopeType;

  @Column('int', { name: 'page_start' })
  pageStart: number;

  @Column('int', { name: 'page_end' })
  pageEnd: number;

  @Column('varchar', { length: 16 })
  difficulty: Difficulty;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @Column('timestamptz', { name: 'ended_at', nullable: true })
  endedAt: Date | null;

  @Column('int', { name: 'total_words', nullable: true })
  totalWords: number | null;

  @Column('int', { name: 'correct_words', nullable: true })
  correctWords: number | null;

  @Column('int', { name: 'forgotten_words', nullable: true })
  forgottenWords: number | null;

  @Column('int', { nullable: true })
  substitutions: number | null;

  @Column('int', { name: 'order_errors', nullable: true })
  orderErrors: number | null;

  @Column('int', { name: 'pronunciation_errors', nullable: true })
  pronunciationErrors: number | null;

  @OneToMany(() => SessionError, (e) => e.session)
  errors: SessionError[];
}
