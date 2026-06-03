import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1700000000000 implements MigrationInterface {
  name = 'InitialSchema1700000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS quran_words (
        id              SERIAL PRIMARY KEY,
        page            INT NOT NULL,
        surah           INT NOT NULL,
        ayah            INT NOT NULL,
        line            INT NOT NULL,
        word_index      INT NOT NULL,
        uthmani_text    VARCHAR(120) NOT NULL,
        normalized_text VARCHAR(120) NOT NULL,
        bbox_x          FLOAT,
        bbox_y          FLOAT,
        bbox_w          FLOAT,
        bbox_h          FLOAT,
        CONSTRAINT uq_quran_word UNIQUE (page, surah, ayah, word_index)
      );
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_quran_words_page ON quran_words(page);`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS idx_quran_words_surah_ayah ON quran_words(surah, ayah);`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS idx_quran_words_surah_ayah;`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_quran_words_page;`);
    await queryRunner.query(`DROP TABLE IF EXISTS quran_words;`);
  }
}
