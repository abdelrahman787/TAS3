import { MigrationInterface, QueryRunner } from 'typeorm';

export class Sessions1700000000001 implements MigrationInterface {
  name = 'Sessions1700000000001';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "pgcrypto";`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS sessions (
        id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id     VARCHAR(64),
        scope_type  VARCHAR(16) NOT NULL,
        page_start  INT NOT NULL,
        page_end    INT NOT NULL,
        difficulty  VARCHAR(16) NOT NULL,
        created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
        ended_at    TIMESTAMPTZ,
        total_words           INT,
        correct_words         INT,
        forgotten_words       INT,
        substitutions         INT,
        order_errors          INT,
        pronunciation_errors  INT
      );
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS session_errors (
        id              BIGSERIAL PRIMARY KEY,
        session_id      UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        word_id         INT NOT NULL,
        expected_word   VARCHAR(120) NOT NULL,
        recognized_text VARCHAR(255),
        error_type      VARCHAR(32) NOT NULL,
        attempt_count   INT NOT NULL DEFAULT 1,
        confidence      FLOAT,
        created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
      );
    `);

    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_session_errors_session ON session_errors(session_id);`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_session_errors_word ON session_errors(word_id);`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS session_errors;`);
    await queryRunner.query(`DROP TABLE IF EXISTS sessions;`);
  }
}
