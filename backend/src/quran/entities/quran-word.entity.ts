import { Column, Entity, Index, PrimaryGeneratedColumn, Unique } from 'typeorm';

@Entity('quran_words')
@Unique('uq_quran_word', ['page', 'surah', 'ayah', 'wordIndex'])
@Index('idx_quran_words_page', ['page'])
@Index('idx_quran_words_surah_ayah', ['surah', 'ayah'])
export class QuranWord {
  @PrimaryGeneratedColumn()
  id: number;

  @Column('int')
  page: number;

  @Column('int')
  surah: number;

  @Column('int')
  ayah: number;

  @Column('int')
  line: number;

  @Column('int', { name: 'word_index' })
  wordIndex: number;

  @Column('varchar', { length: 120, name: 'uthmani_text' })
  uthmaniText: string;

  @Column('varchar', { length: 120, name: 'normalized_text' })
  normalizedText: string;

  @Column('float', { name: 'bbox_x', nullable: true })
  bboxX: number | null;

  @Column('float', { name: 'bbox_y', nullable: true })
  bboxY: number | null;

  @Column('float', { name: 'bbox_w', nullable: true })
  bboxW: number | null;

  @Column('float', { name: 'bbox_h', nullable: true })
  bboxH: number | null;
}
