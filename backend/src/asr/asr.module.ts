import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from '../auth/auth.module';
import { AsrController } from './asr.controller';
import { AsrService } from './asr.service';

@Module({
  imports: [
    HttpModule.register({ timeout: 30000, maxRedirects: 0 }),
    ConfigModule,
    AuthModule,
  ],
  controllers: [AsrController],
  providers: [AsrService],
})
export class AsrModule {}
