import { Body, Controller, Param, Patch, Post } from '@nestjs/common';
import { SessionsService } from './sessions.service';
import { CompleteSessionDto, CreateSessionDto, LogErrorsDto } from './dto/create-session.dto';

@Controller('sessions')
export class SessionsController {
  constructor(private readonly sessions: SessionsService) {}

  @Post()
  create(@Body() dto: CreateSessionDto) {
    return this.sessions.create(dto);
  }

  @Post(':id/errors')
  logErrors(@Param('id') id: string, @Body() dto: LogErrorsDto) {
    return this.sessions.logErrors(id, dto);
  }

  @Patch(':id/complete')
  complete(@Param('id') id: string, @Body() dto: CompleteSessionDto) {
    return this.sessions.complete(id, dto);
  }
}
