import { DataSourceOptions } from 'typeorm';
import { QuranWord } from '../quran/entities/quran-word.entity';
import { InitialSchema1700000000000 } from '../../migrations/1700000000000-InitialSchema';

export const typeOrmConfig: DataSourceOptions = {
  type: 'postgres',
  url: process.env.DATABASE_URL ?? 'postgresql://admin:password@localhost:5432/quran_tasmee3',
  entities: [QuranWord],
  migrations: [InitialSchema1700000000000],
  synchronize: false,
  logging: false,
};
