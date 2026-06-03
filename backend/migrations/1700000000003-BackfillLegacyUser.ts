import { MigrationInterface, QueryRunner } from 'typeorm';

const LEGACY_USER_ID = '00000000-0000-0000-0000-000000000000';

export class BackfillLegacyUser1700000000003 implements MigrationInterface {
  name = 'BackfillLegacyUser1700000000003';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `INSERT INTO users (id, email, password_hash, display_name)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) DO NOTHING;`,
      [
        LEGACY_USER_ID,
        'legacy@qurantasmee3.app',
        // bcrypt-shaped sentinel — intentionally unusable for login.
        '$2b$12$legacy_hash_placeholder_____________________________________',
        'Legacy',
      ],
    );

    await queryRunner.query(
      `UPDATE sessions SET user_id = $1 WHERE user_id IS NULL;`,
      [LEGACY_USER_ID],
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `UPDATE sessions SET user_id = NULL WHERE user_id = $1;`,
      [LEGACY_USER_ID],
    );
    // Intentionally do not delete the legacy user row here — leaving it
    // makes re-running up() idempotent. Cleanup is manual.
  }
}
