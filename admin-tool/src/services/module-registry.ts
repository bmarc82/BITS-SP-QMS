/**
 * Modul-Registry – Lädt Moduldefinitionen und prüft Abhängigkeiten
 */

import modulesData from '../../config/modules-registry.json';

export interface Module {
  id: string;
  name: string;
  version: string;
  required: boolean;
  description: string;
  dependencies: string[];
  permissions: string[];
}

export class ModuleRegistry {
  private modules: Module[] = modulesData.modules as Module[];

  getAll(): Module[] {
    return this.modules;
  }

  checkDependencies(moduleId: string): string[] {
    const mod = this.modules.find(m => m.id === moduleId);
    return mod?.dependencies ?? [];
  }
}
