import { DataSourceOptions } from 'typeorm';
import { QuranWord } from '../quran/entities/quran-word.entity';
import { Session } from '../sessions/entities/session.entity';
import { SessionError } from '../sessions/entities/session-error.entity';
import { InitialSchema1700000000000 } from '../../migrations/1700000000000-InitialSchema';
import { Sessions1700000000001 } from '../../migrations/1700000000001-Sessions';

export const typeOrmConfig: DataSourceOptions = {
  type: 'postgres',
  url: process.env.DATABASE_URL ?? 'postgresql://admin:password@localhost:5432/quran_tasmee3',
  entities: [QuranWord, Session, SessionError],
  migrations: [InitialSchema1700000000000, Sessions1700000000001],
  synchronize: false,
  logging: false,
};
