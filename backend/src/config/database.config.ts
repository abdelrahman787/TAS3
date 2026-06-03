import { DataSourceOptions } from 'typeorm';
import { QuranWord } from '../quran/entities/quran-word.entity';
import { Session } from '../sessions/entities/session.entity';
import { SessionError } from '../sessions/entities/session-error.entity';
import { User } from '../auth/entities/user.entity';
import { InitialSchema1700000000000 } from '../../migrations/1700000000000-InitialSchema';
import { Sessions1700000000001 } from '../../migrations/1700000000001-Sessions';
import { Users1700000000002 } from '../../migrations/1700000000002-Users';
import { BackfillLegacyUser1700000000003 } from '../../migrations/1700000000003-BackfillLegacyUser';

export const typeOrmConfig: DataSourceOptions = {
  type: 'postgres',
  url: process.env.DATABASE_URL ?? 'postgresql://admin:password@localhost:5432/quran_tasmee3',
  entities: [QuranWord, Session, SessionError, User],
  migrations: [
    InitialSchema1700000000000,
    Sessions1700000000001,
    Users1700000000002,
    BackfillLegacyUser1700000000003,
  ],
  synchronize: false,
  logging: false,
};
