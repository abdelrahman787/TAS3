import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { typeOrmConfig } from './config/database.config';
import { AuthModule } from './auth/auth.module';
import { QuranModule } from './quran/quran.module';
import { SessionsModule } from './sessions/sessions.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { AsrModule } from './asr/asr.module';
import { HealthController } from './health/health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot(typeOrmConfig),
    // 20 requests per minute. Only AsrController opts into this guard;
    // sessions and analytics are explicitly unthrottled (5c.3).
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 20 }]),
    AuthModule,
    QuranModule,
    SessionsModule,
    AnalyticsModule,
    AsrModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
