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
    apiUrl: z.string().url().refine(
      (url) => url.startsWith('https://') || url.startsWith('http://localhost') || url.startsWith('http://127.0.0.1'),
      { message: 'API URL must use HTTPS or be localhost for security' }
    ),
    apiKey: z.string().optional(),
    username: z.string().optional(),
    password: z.string().optional(),
    timeout: z.number().min(1000).max(300000).default(30000), // 1s to 5min
    maxRetries: z.number().min(0).max(10).default(3),
    validateSsl: z.boolean().default(true),
    maxResponseSize: z.number().default(10 * 1024 * 1024), // 10MB default
    maxRequestSize: z.number().default(5 * 1024 * 1024), // 5MB default
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
    validateSsl: process.env.VALIDATE_SSL !== 'false', // default true
    maxResponseSize: parseInt(process.env.MAX_RESPONSE_SIZE || String(10 * 1024 * 1024)),
    maxRequestSize: parseInt(process.env.MAX_REQUEST_SIZE || String(5 * 1024 * 1024)),
  },
  server: {
    port: parseInt(process.env.PORT || '3000'),
    logLevel: (process.env.LOG_LEVEL || 'info') as 'debug' | 'info' | 'warn' | 'error',
  },
};

// Validar e exportar configuração
export const config = configSchema.parse(rawConfig);

export type Config = z.infer<typeof configSchema>;
