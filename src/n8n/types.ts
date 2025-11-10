/**
 * Tipos TypeScript para a API do n8n
 */

// Configuração do cliente
export interface N8nClientConfig {
  apiUrl: string;
  apiKey?: string;
  username?: string;
  password?: string;
  timeout?: number;
  maxRetries?: number;
}

// Workflow
export interface Workflow {
  id: string;
  name: string;
  active: boolean;
  nodes: WorkflowNode[];
  connections: WorkflowConnections;
  settings?: WorkflowSettings;
  staticData?: any;
  tags?: Tag[];
  createdAt: string;
  updatedAt: string;
}

export interface WorkflowListItem {
  id: string;
  name: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
  tags?: Tag[];
}

export interface WorkflowNode {
  id: string;
  name: string;
  type: string;
  typeVersion: number;
  position: [number, number];
  parameters: Record<string, any>;
  credentials?: Record<string, string>;
  webhookId?: string;
  disabled?: boolean;
  notes?: string;
}

export interface WorkflowConnections {
  [nodeName: string]: {
    [outputName: string]: Array<{
      node: string;
      type: string;
      index: number;
    }>;
  };
}

export interface WorkflowSettings {
  executionOrder?: 'v0' | 'v1';
  saveDataErrorExecution?: 'all' | 'none';
  saveDataSuccessExecution?: 'all' | 'none';
  saveManualExecutions?: boolean;
  callerPolicy?: string;
  errorWorkflow?: string;
  timezone?: string;
  executionTimeout?: number;
}

// Execução
export interface Execution {
  id: string;
  workflowId: string;
  mode: 'manual' | 'trigger' | 'webhook' | 'retry';
  startedAt: string;
  stoppedAt?: string;
  status: 'running' | 'success' | 'error' | 'waiting' | 'canceled';
  data?: ExecutionData;
  retryOf?: string;
  retrySuccessId?: string;
  waitTill?: string;
}

export interface ExecutionListItem {
  id: string;
  workflowId: string;
  mode: string;
  startedAt: string;
  stoppedAt?: string;
  status: string;
}

export interface ExecutionData {
  resultData: {
    runData: Record<string, NodeRunData[]>;
    lastNodeExecuted?: string;
    error?: ExecutionError;
  };
  executionData?: {
    contextData: Record<string, any>;
    nodeExecutionStack: any[];
    waitingExecution: any;
  };
}

export interface NodeRunData {
  startTime: number;
  executionTime: number;
  data: {
    main: any[][];
  };
  source: Array<{
    previousNode: string;
  }> | null;
}

export interface ExecutionError {
  message: string;
  stack?: string;
  name: string;
  node?: string;
}

// Credenciais
export interface Credential {
  id: string;
  name: string;
  type: string;
  createdAt: string;
  updatedAt: string;
}

// Tags
export interface Tag {
  id: string;
  name: string;
  createdAt: string;
  updatedAt: string;
}

// Webhook
export interface WebhookData {
  workflowId: string;
  webhookPath: string;
  webhookId: string;
  node: string;
}
