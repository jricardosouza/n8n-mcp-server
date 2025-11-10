/**
 * Cliente HTTP para comunicação com a API do n8n
 */

import axios, { AxiosInstance, AxiosError } from 'axios';
import { logger } from '../utils/logger.js';
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

    // Configurar cliente axios
    this.client = axios.create({
      baseURL: config.apiUrl,
      timeout: config.timeout || 30000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Adicionar autenticação
    if (config.apiKey) {
      this.client.defaults.headers.common['X-N8N-API-KEY'] = config.apiKey;
    } else if (config.username && config.password) {
      const auth = Buffer.from(`${config.username}:${config.password}`).toString('base64');
      this.client.defaults.headers.common['Authorization'] = `Basic ${auth}`;
    }

    // Interceptor para logging
    this.client.interceptors.request.use(
      (config) => {
        logger.debug(`→ ${config.method?.toUpperCase()} ${config.url}`);
        return config;
      },
      (error) => {
        logger.error('Erro na requisição:', error);
        return Promise.reject(error);
      }
    );

    this.client.interceptors.response.use(
      (response) => {
        logger.debug(`← ${response.status} ${response.config.url}`);
        return response;
      },
      (error: AxiosError) => {
        const status = error.response?.status || 'unknown';
        const url = error.config?.url || 'unknown';
        logger.error(`← ${status} ${url}`, error.message);
        return Promise.reject(error);
      }
    );
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
      } else if (data?.message) {
        return new Error(`${message}: ${data.message}`);
      }
      
      return new Error(`${message}: ${error.message}`);
    }
    
    return error instanceof Error ? error : new Error(message);
  }
}
