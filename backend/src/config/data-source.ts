import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import { typeOrmConfig } from './database.config';

config();

export default new DataSource(typeOrmConfig);
