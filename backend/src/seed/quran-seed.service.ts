import axios from 'axios';
import { DataSource } from 'typeorm';
import { QuranWord } from '../quran/entities/quran-word.entity';
import { normalizeArabic } from '../quran/normalize';

const QURAN_API = 'https://api.quran.com/api/v4';
const TOTAL_PAGES = 604;
const DELAY_MS = 300;

interface ApiWord {
  position: number;
  text_uthmani: string;
  text_simple?: string;
  char_type_name: string;
  location: string; // "surah:ayah:word"
  page_number: number;
  line_number: number;
}

interface ApiVerse {
  verse_number: number;
  chapter_id: number;
  words: ApiWord[];
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function fetchPage(page: number): Promise<ApiVerse[]> {
  const { data } = await axios.get(`${QURAN_API}/verses/by_page/${page}`, {
    params: {
      words: true,
      word_fields: 'text_uthmani,text_simple,location,char_type_name,line_number,page_number',
      per_page: 50,
    },
    timeout: 20000,
  });
  return data.verses ?? [];
}

export async function seedQuran(dataSource: DataSource) {
  const repo = dataSource.getRepository(QuranWord);
  const existing = await repo.count();
  if (existing > 0) {
    console.log(`Existing rows: ${existing}. Seed is idempotent — will skip duplicates.`);
  }

  let totalInserted = 0;

  for (let page = 1; page <= TOTAL_PAGES; page++) {
    let verses: ApiVerse[];
    try {
      verses = await fetchPage(page);
    } catch (err: any) {
      console.error(`Page ${page} fetch failed: ${err.message}. Retrying once in 2s...`);
      await sleep(2000);
      verses = await fetchPage(page);
    }

    const rows: Partial<QuranWord>[] = [];
    for (const verse of verses) {
      for (const w of verse.words) {
        if (w.char_type_name !== 'word') continue;
        const [surahStr, ayahStr, wordIdxStr] = w.location.split(':');
        rows.push({
          page: w.page_number,
          surah: parseInt(surahStr, 10),
          ayah: parseInt(ayahStr, 10),
          line: w.line_number,
          wordIndex: parseInt(wordIdxStr, 10),
          uthmaniText: w.text_uthmani,
          normalizedText: normalizeArabic(w.text_simple ?? w.text_uthmani),
        });
      }
    }

    if (rows.length > 0) {
      const result = await repo
        .createQueryBuilder()
        .insert()
        .into(QuranWord)
        .values(rows)
        .orIgnore()
        .execute();
      totalInserted += rows.length;
      const inserted = result.identifiers.filter(Boolean).length;
      console.log(`Page ${page}/${TOTAL_PAGES} — ${rows.length} words processed (${inserted} new)`);
    } else {
      console.log(`Page ${page}/${TOTAL_PAGES} — no words returned`);
    }

    await sleep(DELAY_MS);
  }

  console.log(`Done. Total words processed: ${totalInserted}`);
}
