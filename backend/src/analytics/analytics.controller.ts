import { Controller, DefaultValuePipe, Get, ParseIntPipe, Query } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';

@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analytics: AnalyticsService) {}

  @Get('progress')
  progress(@Query('userId') userId?: string) {
    return this.analytics.getProgress(userId);
  }

  @Get('sessions')
  sessions(
    @Query('userId') userId?: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit?: number,
  ) {
    return this.analytics.listSessions(userId, limit);
  }

  @Get('difficult-words')
  difficultWords(
    @Query('userId') userId?: string,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit?: number,
  ) {
    return this.analytics.getDifficultWords(userId, limit);
  }
}
