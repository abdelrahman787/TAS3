import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { QuranWord } from './entities/quran-word.entity';
import { QuranController } from './quran.controller';
import { QuranService } from './quran.service';

@Module({
  imports: [TypeOrmModule.forFeature([QuranWord])],
  controllers: [QuranController],
  providers: [QuranService],
  exports: [QuranService],
})
export class QuranModule {}
