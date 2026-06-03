import { MigrationInterface, QueryRunner } from 'typeorm';

export class Users1700000000002 implements MigrationInterface {
  name = 'Users1700000000002';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "pgcrypto";`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS users (
        id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email         VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        display_name  VARCHAR(100),
        created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
      );
    `);

    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);`,
    );

    // sessions.user_id already exists as a varchar column from Phase 2; we
    // drop it and re-add as a proper UUID FK so analytics can join cleanly.
    await queryRunner.query(`ALTER TABLE sessions DROP COLUMN IF EXISTS user_id;`);
    await queryRunner.query(
      `ALTER TABLE sessions ADD COLUMN user_id UUID REFERENCES users(id) ON DELETE SET NULL;`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS idx_sessions_user_id;`);
    await queryRunner.query(`ALTER TABLE sessions DROP COLUMN IF EXISTS user_id;`);
    await queryRunner.query(`ALTER TABLE sessions ADD COLUMN user_id VARCHAR(64);`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_users_email;`);
    await queryRunner.query(`DROP TABLE IF EXISTS users;`);
  }
}
