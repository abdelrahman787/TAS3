import { Controller, Get, Param, ParseIntPipe } from '@nestjs/common';
import { QuranService } from './quran.service';

@Controller('quran')
export class QuranController {
  constructor(private readonly quran: QuranService) {}

  @Get('page/:pageNumber')
  getPage(@Param('pageNumber', ParseIntPipe) pageNumber: number) {
    return this.quran.getPage(pageNumber);
  }

  @Get('surah/:surahNumber')
  getSurah(@Param('surahNumber', ParseIntPipe) surahNumber: number) {
    return this.quran.getSurah(surahNumber);
  }
}
