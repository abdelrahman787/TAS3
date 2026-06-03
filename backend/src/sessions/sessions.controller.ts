import { Body, Controller, Param, Patch, Post, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SessionsService } from './sessions.service';
import { CompleteSessionDto, CreateSessionDto, LogErrorsDto } from './dto/create-session.dto';

interface AuthedRequest {
  user: { userId: string; email: string };
}

@Controller('sessions')
@UseGuards(JwtAuthGuard)
export class SessionsController {
  constructor(private readonly sessions: SessionsService) {}

  @Post()
  create(@Body() dto: CreateSessionDto, @Request() req: AuthedRequest) {
    return this.sessions.create(dto, req.user.userId);
  }

  @Post(':id/errors')
  logErrors(@Param('id') id: string, @Body() dto: LogErrorsDto, @Request() req: AuthedRequest) {
    return this.sessions.logErrors(id, dto, req.user.userId);
  }

  @Patch(':id/complete')
  complete(
    @Param('id') id: string,
    @Body() dto: CompleteSessionDto,
    @Request() req: AuthedRequest,
  ) {
    return this.sessions.complete(id, dto, req.user.userId);
  }
}
