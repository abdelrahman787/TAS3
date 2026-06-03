import {
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
} from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { AxiosError } from 'axios';
import FormData from 'form-data';
import { firstValueFrom } from 'rxjs';

const GROQ_URL = 'https://api.groq.com/openai/v1/audio/transcriptions';
const RETRY_DELAY_MS = 1000;

@Injectable()
export class AsrService {
  private readonly logger = new Logger(AsrService.name);

  constructor(
    private readonly http: HttpService,
    private readonly config: ConfigService,
  ) {}

  async transcribe(
    audioBuffer: Buffer,
    mimetype: string,
  ): Promise<{ text: string }> {
    const apiKey = this.config.get<string>('GROQ_API_KEY');
    if (!apiKey) {
      this.logger.error('GROQ_API_KEY not configured');
      throw new HttpException(
        'ASR not configured',
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }

    return this._postWithRetry(audioBuffer, mimetype, apiKey, /*attempt*/ 0);
  }

  private async _postWithRetry(
    audioBuffer: Buffer,
    mimetype: string,
    apiKey: string,
    attempt: number,
  ): Promise<{ text: string }> {
    const form = new FormData();
    form.append('file', audioBuffer, {
      filename: 'audio.m4a',
      contentType: mimetype,
    });
    form.append('model', 'whisper-large-v3');
    form.append('language', 'ar');
    form.append('response_format', 'json');

    try {
      const response = await firstValueFrom(
        this.http.post(GROQ_URL, form, {
          headers: {
            ...form.getHeaders(),
            Authorization: `Bearer ${apiKey}`,
          },
          maxBodyLength: Infinity,
          maxContentLength: Infinity,
          timeout: 30000,
        }),
      );
      const text = (response.data?.text as string | undefined) ?? '';
      return { text };
    } catch (err) {
      const axiosErr = err as AxiosError;
      const status = axiosErr.response?.status;

      if (status === 429) {
        // Never log the request body — audio is sensitive.
        this.logger.warn('Groq rate limited (429)');
        throw new HttpException('ASR rate limit', HttpStatus.TOO_MANY_REQUESTS);
      }

      if (status && status >= 500 && attempt === 0) {
        this.logger.warn(`Groq ${status} — retrying once in ${RETRY_DELAY_MS}ms`);
        await new Promise((r) => setTimeout(r, RETRY_DELAY_MS));
        return this._postWithRetry(audioBuffer, mimetype, apiKey, attempt + 1);
      }

      this.logger.error(
        `ASR upstream failure: status=${status ?? 'n/a'} message=${axiosErr.message}`,
      );
      throw new HttpException(
        'ASR unavailable',
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }
  }
}
