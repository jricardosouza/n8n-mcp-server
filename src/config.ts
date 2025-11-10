/**
 * Configuração do servidor
 * Carrega variáveis de ambiente e define valores padrão
 */

import dotenv from 'dotenv';
import { z } from 'zod';

// Carregar .env
dotenv.config();

// Schema de validação da configuração
const configSchema = z.object({
  n8n: z.object({
    apiUrl: z.string().url(),
    apiKey: z.string().optional(),
    username: z.string().optional(),
    password: z.string().optional(),
    timeout: z.number().default(30000),
    maxRetries: z.number().default(3),
  }),
  server: z.object({
    port: z.number().default(3000),
    logLevel: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
  }),
});

// Construir objeto de configuração
const rawConfig = {
  n8n: {
    apiUrl: process.env.N8N_API_URL || '',
    apiKey: process.env.N8N_API_KEY,
    username: process.env.N8N_USERNAME,
    password: process.env.N8N_PASSWORD,
    timeout: parseInt(process.env.REQUEST_TIMEOUT || '30000'),
    maxRetries: parseInt(process.env.MAX_RETRIES || '3'),
  },
  server: {
    port: parseInt(process.env.PORT || '3000'),
    logLevel: (process.env.LOG_LEVEL || 'info') as 'debug' | 'info' | 'warn' | 'error',
  },
};

// Validar e exportar configuração
export const config = configSchema.parse(rawConfig);

export type Config = z.infer<typeof configSchema>;
