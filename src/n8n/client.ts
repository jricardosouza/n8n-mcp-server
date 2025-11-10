/**
 * Cliente HTTP para comunicação com a API do n8n
 */

import axios, { AxiosInstance, AxiosError } from 'axios';
import https from 'https';
import { logger } from '../utils/logger.js';
import { sanitizeUrl, sanitizeHeaders, sanitizeObject } from '../utils/sanitizer.js';
import type {
  Workflow,
  WorkflowListItem,
  Execution,
  ExecutionListItem,
  Credential,
  N8nClientConfig,
} from './types.js';

export class N8nClient {
  private client: AxiosInstance;
  private config: N8nClientConfig;

  constructor(config: N8nClientConfig) {
    this.config = config;
    
    // Validate URL uses HTTPS (except localhost)
    this.validateApiUrl(config.apiUrl);

    // Configurar cliente axios
    this.client = axios.create({
      baseURL: config.apiUrl,
      timeout: config.timeout || 30000,
      headers: {
        'Content-Type': 'application/json',
        // Security headers
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block',
      },
      // SSL/TLS validation
      httpsAgent: new https.Agent({
        rejectUnauthorized: config.validateSsl !== false,
        minVersion: 'TLSv1.2',
      }),
      // Response size limit
      maxContentLength: config.maxResponseSize || 10 * 1024 * 1024,
      maxBodyLength: config.maxRequestSize || 5 * 1024 * 1024,
    });

    // Adicionar autenticação
    if (config.apiKey) {
      this.client.defaults.headers.common['X-N8N-API-KEY'] = config.apiKey;
    } else if (config.username && config.password) {
      const auth = Buffer.from(`${config.username}:${config.password}`).toString('base64');
      this.client.defaults.headers.common['Authorization'] = `Basic ${auth}`;
    }

    // Interceptor para logging (with sanitization)
    this.client.interceptors.request.use(
      (config) => {
        const sanitizedUrl = sanitizeUrl(config.url || '');
        const sanitizedHeaders = sanitizeHeaders(config.headers || {});
        logger.debug(`→ ${config.method?.toUpperCase()} ${sanitizedUrl}`);
        logger.debug('Headers:', sanitizedHeaders);
        return config;
      },
      (error) => {
        logger.error('Erro na requisição:', sanitizeObject(error));
        return Promise.reject(error);
      }
    );

    this.client.interceptors.response.use(
      (response) => {
        const sanitizedUrl = sanitizeUrl(response.config.url || '');
        logger.debug(`← ${response.status} ${sanitizedUrl}`);
        return response;
      },
      (error: AxiosError) => {
        const status = error.response?.status || 'unknown';
        const url = sanitizeUrl(error.config?.url || 'unknown');
        logger.error(`← ${status} ${url}`, error.message);
        return Promise.reject(error);
      }
    );
  }

  /**
   * Validate API URL for security
   */
  private validateApiUrl(url: string): void {
    try {
      const urlObj = new URL(url);
      
      // Allow HTTP only for localhost
      if (urlObj.protocol === 'http:') {
        const hostname = urlObj.hostname;
        if (hostname !== 'localhost' && hostname !== '127.0.0.1' && hostname !== '[::1]') {
          logger.warn(
            '⚠️  WARNING: Using HTTP for non-localhost connection is insecure. ' +
            'Please use HTTPS for production environments.'
          );
        }
      }
      
      // Validate allowed hosts if configured
      if (this.config.allowedHosts && this.config.allowedHosts.length > 0) {
        const hostname = urlObj.hostname;
        if (!this.config.allowedHosts.includes(hostname)) {
          throw new Error(
            `Host ${hostname} is not in the allowed hosts list: ${this.config.allowedHosts.join(', ')}`
          );
        }
      }
    } catch (error) {
      if (error instanceof Error) {
        throw new Error(`Invalid API URL: ${error.message}`);
      }
      throw error;
    }
  }

  /**
   * Listar todos os workflows
   */
  async listWorkflows(): Promise<WorkflowListItem[]> {
    try {
      const response = await this.client.get<{ data: WorkflowListItem[] }>('/workflows');
      return response.data.data;
    } catch (error) {
      throw this.handleError(error, 'Erro ao listar workflows');
    }
  }

  /**
   * Obter workflow específico
   */
  async getWorkflow(id: string): Promise<Workflow> {
    try {
      const response = await this.client.get<Workflow>(`/workflows/${id}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, `Erro ao obter workflow ${id}`);
    }
  }

  /**
   * Criar novo workflow
   */
  async createWorkflow(workflow: Partial<Workflow>): Promise<Workflow> {
    try {
      const response = await this.client.post<Workflow>('/workflows', workflow);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Erro ao criar workflow');
    }
  }

  /**
   * Atualizar workflow existente
   */
  async updateWorkflow(id: string, workflow: Partial<Workflow>): Promise<Workflow> {
    try {
      const response = await this.client.patch<Workflow>(`/workflows/${id}`, workflow);
      return response.data;
    } catch (error) {
      throw this.handleError(error, `Erro ao atualizar workflow ${id}`);
    }
  }

  /**
   * Deletar workflow
   */
  async deleteWorkflow(id: string): Promise<void> {
    try {
      await this.client.delete(`/workflows/${id}`);
    } catch (error) {
      throw this.handleError(error, `Erro ao deletar workflow ${id}`);
    }
  }

  /**
   * Ativar/desativar workflow
   */
  async toggleWorkflow(id: string, active: boolean): Promise<Workflow> {
    try {
      const response = await this.client.patch<Workflow>(`/workflows/${id}`, { active });
      return response.data;
    } catch (error) {
      throw this.handleError(error, `Erro ao ${active ? 'ativar' : 'desativar'} workflow ${id}`);
    }
  }

  /**
   * Executar workflow manualmente
   */
  async executeWorkflow(id: string, data?: any): Promise<Execution> {
    try {
      const response = await this.client.post<Execution>(`/workflows/${id}/execute`, data);
      return response.data;
    } catch (error) {
      throw this.handleError(error, `Erro ao executar workflow ${id}`);
    }
  }

  /**
   * Listar execuções
   */
  async listExecutions(workflowId?: string): Promise<ExecutionListItem[]> {
    try {
      const params = workflowId ? { workflowId } : {};
      const response = await this.client.get<{ data: ExecutionListItem[] }>('/executions', { params });
      return response.data.data;
    } catch (error) {
      throw this.handleError(error, 'Erro ao listar execuções');
    }
  }

  /**
   * Obter execução específica
   */
  async getExecution(id: string): Promise<Execution> {
    try {
      const response = await this.client.get<Execution>(`/executions/${id}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, `Erro ao obter execução ${id}`);
    }
  }

  /**
   * Deletar execução
   */
  async deleteExecution(id: string): Promise<void> {
    try {
      await this.client.delete(`/executions/${id}`);
    } catch (error) {
      throw this.handleError(error, `Erro ao deletar execução ${id}`);
    }
  }

  /**
   * Listar credenciais
   */
  async listCredentials(): Promise<Credential[]> {
    try {
      const response = await this.client.get<{ data: Credential[] }>('/credentials');
      return response.data.data;
    } catch (error) {
      throw this.handleError(error, 'Erro ao listar credenciais');
    }
  }

  /**
   * Verificar saúde da API
   */
  async healthCheck(): Promise<boolean> {
    try {
      await this.client.get('/workflows');
      return true;
    } catch (error) {
      logger.error('Health check falhou:', error);
      return false;
    }
  }

  /**
   * Tratamento de erros unificado
   */
  private handleError(error: unknown, message: string): Error {
    if (axios.isAxiosError(error)) {
      const status = error.response?.status;
      const data = error.response?.data;
      
      if (status === 401) {
        return new Error(`${message}: Não autorizado. Verifique suas credenciais.`);
      } else if (status === 404) {
        return new Error(`${message}: Recurso não encontrado.`);
      } else if (status === 403) {
        return new Error(`${message}: Acesso negado.`);
      } else if (status === 413) {
        return new Error(`${message}: Payload muito grande. Verifique MAX_REQUEST_SIZE.`);
      } else if (error.code === 'ECONNABORTED') {
        return new Error(`${message}: Timeout na requisição. Verifique REQUEST_TIMEOUT.`);
      } else if (error.code === 'ERR_BAD_REQUEST' && error.message.includes('maxContentLength')) {
        return new Error(`${message}: Resposta muito grande. Verifique MAX_RESPONSE_SIZE.`);
      } else if (data?.message) {
        return new Error(`${message}: ${data.message}`);
      }
      
      // Sanitize error message for logging
      const sanitizedError = sanitizeObject(error);
      logger.debug('Detailed error:', sanitizedError);
      
      return new Error(`${message}: ${error.message}`);
    }
    
    return error instanceof Error ? error : new Error(message);
  }
}
