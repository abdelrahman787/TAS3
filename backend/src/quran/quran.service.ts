import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { QuranWord } from './entities/quran-word.entity';

@Injectable()
export class QuranService {
  constructor(
    @InjectRepository(QuranWord)
    private readonly wordRepo: Repository<QuranWord>,
  ) {}

  async getPage(pageNumber: number) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw new NotFoundException(`Page ${pageNumber} out of range (1–604)`);
    }
    const words = await this.wordRepo.find({
      where: { page: pageNumber },
      order: { surah: 'ASC', ayah: 'ASC', wordIndex: 'ASC' },
    });
    return {
      page: pageNumber,
      total_words: words.length,
      words: words.map((w) => ({
        id: w.id,
        page: w.page,
        surah: w.surah,
        ayah: w.ayah,
        line: w.line,
        word_index: w.wordIndex,
        uthmani_text: w.uthmaniText,
        normalized_text: w.normalizedText,
        bbox_x: w.bboxX,
        bbox_y: w.bboxY,
        bbox_w: w.bboxW,
        bbox_h: w.bboxH,
      })),
    };
  }

  async getSurah(surahNumber: number) {
    if (surahNumber < 1 || surahNumber > 114) {
      throw new NotFoundException(`Surah ${surahNumber} out of range (1–114)`);
    }
    const rows = await this.wordRepo
      .createQueryBuilder('w')
      .select('MIN(w.page)', 'pageStart')
      .addSelect('MAX(w.page)', 'pageEnd')
      .addSelect('MAX(w.ayah)', 'ayahCount')
      .where('w.surah = :surah', { surah: surahNumber })
      .getRawOne();

    if (!rows || rows.pageStart === null) {
      throw new NotFoundException(`Surah ${surahNumber} not seeded`);
    }

    return {
      surah: surahNumber,
      page_start: Number(rows.pageStart),
      page_end: Number(rows.pageEnd),
      ayah_count: Number(rows.ayahCount),
    };
  }
}
