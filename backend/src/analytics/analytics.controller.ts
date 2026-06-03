import { Controller, DefaultValuePipe, Get, ParseIntPipe, Query, Request, UseGuards } from '@nestjs/common';
import { OptionalJwtGuard } from '../auth/guards/optional-jwt.guard';
import { AnalyticsService } from './analytics.service';

interface MaybeAuthedRequest {
  user?: { userId: string; email: string } | null;
}

@Controller('analytics')
@UseGuards(OptionalJwtGuard)
export class AnalyticsController {
  constructor(private readonly analytics: AnalyticsService) {}

  @Get('progress')
  progress(@Request() req: MaybeAuthedRequest) {
    return this.analytics.getProgress(req.user?.userId);
  }

  @Get('sessions')
  sessions(
    @Request() req: MaybeAuthedRequest,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit?: number,
  ) {
    return this.analytics.listSessions(req.user?.userId, limit);
  }

  @Get('difficult-words')
  difficultWords(
    @Request() req: MaybeAuthedRequest,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit?: number,
  ) {
    return this.analytics.getDifficultWords(req.user?.userId, limit);
  }
}
