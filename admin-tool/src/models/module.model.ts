export type ModuleStatus = 'not-installed' | 'installing' | 'installed' | 'error' | 'update-available';

export interface ModuleModel {
  id: string;
  name: string;
  version: string;
  status: ModuleStatus;
  installedAt?: Date;
  lastChecked?: Date;
  errorMessage?: string;
}
