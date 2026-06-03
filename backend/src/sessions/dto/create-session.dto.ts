import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

const ERROR_TYPES = [
  'forget',
  'substitution',
  'order_error',
  'pronunciation',
  'asr_failure',
] as const;

class ScopeDto {
  @IsString()
  @IsIn(['page', 'surah', 'range'])
  type: 'page' | 'surah' | 'range';

  @IsInt()
  @Min(1)
  @Max(604)
  pageStart: number;

  @IsInt()
  @Min(1)
  @Max(604)
  pageEnd: number;
}

export class CreateSessionDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @ValidateNested()
  @Type(() => ScopeDto)
  scope: ScopeDto;

  @IsString()
  @IsIn(['easy', 'normal', 'strict'])
  difficulty: 'easy' | 'normal' | 'strict';
}

class ErrorEntryDto {
  @IsInt()
  @Min(1)
  wordId: number;

  @IsString()
  @IsNotEmpty()
  expectedWord: string;

  @IsOptional()
  @IsString()
  recognizedText?: string | null;

  @IsString()
  @IsIn(ERROR_TYPES as unknown as string[])
  errorType: (typeof ERROR_TYPES)[number];

  @IsInt()
  @Min(1)
  attemptCount: number;

  @IsOptional()
  @IsNumber()
  confidence?: number | null;
}

export class LogErrorsDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ErrorEntryDto)
  errors: ErrorEntryDto[];
}

class SessionStatsDto {
  @IsInt() @Min(0) totalWords: number;
  @IsInt() @Min(0) correctWords: number;
  @IsInt() @Min(0) forgottenWords: number;
  @IsInt() @Min(0) substitutions: number;
  @IsInt() @Min(0) orderErrors: number;
  @IsInt() @Min(0) pronunciationErrors: number;
}

export class CompleteSessionDto {
  @IsDateString()
  endTime: string;

  @ValidateNested()
  @Type(() => SessionStatsDto)
  stats: SessionStatsDto;
}
