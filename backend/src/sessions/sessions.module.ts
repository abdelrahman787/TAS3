import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Session } from './entities/session.entity';
import { SessionError } from './entities/session-error.entity';
import { SessionsController } from './sessions.controller';
import { SessionsService } from './sessions.service';

@Module({
  imports: [TypeOrmModule.forFeature([Session, SessionError])],
  controllers: [SessionsController],
  providers: [SessionsService],
})
export class SessionsModule {}
