export type InstallationStep = 'pending' | 'running' | 'completed' | 'failed';

export interface InstallationLog {
  timestamp: Date;
  level: 'info' | 'warning' | 'error';
  message: string;
}

export interface InstallationState {
  moduleId: string;
  steps: Array<{ name: string; status: InstallationStep }>;
  logs: InstallationLog[];
  startedAt?: Date;
  completedAt?: Date;
}
