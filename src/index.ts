#!/usr/bin/env node

/**
 * n8n-mcp-server
 * Model Context Protocol server para integração com n8n
 * 
 * @author jricardosouza
 * @license MIT
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { config } from './config.js';
import { N8nClient } from './n8n/client.js';
import { tools } from './tools/index.js';
import { logger } from './utils/logger.js';

/**
 * Inicializa e configura o servidor MCP
 */
async function main() {
  logger.info('🚀 Iniciando n8n-MCP Server...');
  
  // Validar configuração
  if (!config.n8n.apiUrl) {
    logger.error('❌ N8N_API_URL não configurado. Verifique o arquivo .env');
    process.exit(1);
  }

  // Inicializar cliente n8n
  const n8nClient = new N8nClient({
    apiUrl: config.n8n.apiUrl,
    apiKey: config.n8n.apiKey,
    timeout: config.n8n.timeout,
    validateSsl: config.n8n.validateSsl,
    maxResponseSize: config.n8n.maxResponseSize,
    maxRequestSize: config.n8n.maxRequestSize,
  });

  // Criar servidor MCP
  const server = new Server(
    {
      name: 'n8n-mcp-server',
      version: '1.0.0',
    },
    {
      capabilities: {
        tools: {},
        resources: {},
      },
    }
  );

  /**
   * Handler: Listar ferramentas disponíveis
   */
  server.setRequestHandler(ListToolsRequestSchema, async () => {
    logger.debug('📋 Listando ferramentas disponíveis');
    
    return {
      tools: tools.map(tool => ({
        name: tool.name,
        description: tool.description,
        inputSchema: tool.inputSchema,
      })),
    };
  });

  /**
   * Handler: Executar ferramenta
   */
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    
    logger.info(`🔧 Executando ferramenta: ${name}`);
    logger.debug('Argumentos:', args);

    // Encontrar ferramenta
    const tool = tools.find(t => t.name === name);
    
    if (!tool) {
      logger.error(`❌ Ferramenta não encontrada: ${name}`);
      throw new Error(`Ferramenta desconhecida: ${name}`);
    }

    try {
      // Executar ferramenta
      const result = await tool.execute(args || {}, n8nClient);
      
      logger.info(`✅ Ferramenta ${name} executada com sucesso`);
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Erro desconhecido';
      logger.error(`❌ Erro ao executar ${name}:`, errorMessage);
      
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              error: errorMessage,
              tool: name,
            }, null, 2),
          },
        ],
        isError: true,
      };
    }
  });

  /**
   * Handler: Listar recursos disponíveis
   */
  server.setRequestHandler(ListResourcesRequestSchema, async () => {
    logger.debug('📚 Listando recursos disponíveis');
    
    try {
      const workflows = await n8nClient.listWorkflows();
      
      return {
        resources: workflows.map(workflow => ({
          uri: `n8n://workflow/${workflow.id}`,
          name: workflow.name,
          description: `Workflow: ${workflow.name} (${workflow.active ? 'Ativo' : 'Inativo'})`,
          mimeType: 'application/json',
        })),
      };
    } catch (error) {
      logger.error('❌ Erro ao listar recursos:', error);
      return { resources: [] };
    }
  });

  /**
   * Handler: Ler recurso específico
   */
  server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
    const uri = request.params.uri;
    logger.debug(`📖 Lendo recurso: ${uri}`);
    
    // Parse URI: n8n://workflow/{id}
    const match = uri.match(/^n8n:\/\/workflow\/(.+)$/);
    
    if (!match) {
      throw new Error(`URI inválida: ${uri}`);
    }

    const workflowId = match[1];
    
    try {
      const workflow = await n8nClient.getWorkflow(workflowId);
      
      return {
        contents: [
          {
            uri,
            mimeType: 'application/json',
            text: JSON.stringify(workflow, null, 2),
          },
        ],
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Erro desconhecido';
      logger.error(`❌ Erro ao ler workflow ${workflowId}:`, errorMessage);
      throw error;
    }
  });

  // Iniciar servidor
  const transport = new StdioServerTransport();
  await server.connect(transport);

  logger.info('✅ n8n-MCP Server iniciado com sucesso!');
  logger.info(`📡 Conectado ao n8n: ${config.n8n.apiUrl}`);
  logger.info(`🔧 ${tools.length} ferramentas disponíveis`);
  
  // Graceful shutdown
  process.on('SIGINT', async () => {
    logger.info('🛑 Encerrando servidor...');
    await server.close();
    process.exit(0);
  });
}

// Executar servidor
main().catch((error) => {
  logger.error('❌ Erro fatal:', error);
  process.exit(1);
});
