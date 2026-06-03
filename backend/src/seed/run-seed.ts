import 'reflect-metadata';
import { config } from 'dotenv';
import dataSource from '../config/data-source';
import { seedQuran } from './quran-seed.service';

config();

async function main() {
  await dataSource.initialize();
  console.log('DB connected. Starting Quran seed (this takes ~5 minutes)...');
  await seedQuran(dataSource);
  await dataSource.destroy();
  process.exit(0);
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
