import {
  Controller,
  FileTypeValidator,
  HttpCode,
  HttpStatus,
  MaxFileSizeValidator,
  ParseFilePipe,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ThrottlerGuard } from '@nestjs/throttler';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AsrService } from './asr.service';

interface UploadedAudio {
  buffer: Buffer;
  mimetype: string;
  size: number;
  originalname: string;
}

const MAX_BYTES = 10 * 1024 * 1024; // 10 MB

@Controller('asr')
@UseGuards(JwtAuthGuard, ThrottlerGuard)
export class AsrController {
  constructor(private readonly asr: AsrService) {}

  @Post('transcribe')
  @HttpCode(HttpStatus.OK)
  @UseInterceptors(FileInterceptor('audio'))
  async transcribe(
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: MAX_BYTES }),
          new FileTypeValidator({
            fileType: /^(audio\/(mp4|m4a|webm|mpeg|x-m4a))$/,
          }),
        ],
      }),
    )
    file: UploadedAudio,
  ): Promise<{ text: string }> {
    return this.asr.transcribe(file.buffer, file.mimetype);
  }
}
