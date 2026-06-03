/**
 * Arabic text normalization for matching.
 *  1. Strip diacritics (tashkeel): U+0610–U+061A, U+064B–U+065F, U+0670 (dagger alif)
 *  2. Alif variants أ إ آ ٱ → ا
 *  3. Ya Maqsura ى → ي
 *  4. Remove tatweel ـ
 */
export function normalizeArabic(text: string): string {
  return text
    .replace(/[ؐ-ًؚ-ٰٟ]/g, '')
    .replace(/[آأإٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ـ/g, '')
    .trim();
}
