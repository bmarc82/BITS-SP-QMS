/**
 * PnP Bridge Service
 * Kommunikation zwischen Admin Tool und PnP PowerShell
 */

export interface PnPBridgeOptions {
  tenantUrl: string;
  appId: string;
  certThumbprint: string;
}

export class PnPBridgeService {
  async testConnection(options: PnPBridgeOptions): Promise<boolean> {
    // PowerShell-Bridge aufrufen
    throw new Error('Nicht implementiert');
  }

  async runScript(scriptPath: string, params: Record<string, string>): Promise<string> {
    // PowerShell-Skript ausführen und Output zurückgeben
    throw new Error('Nicht implementiert');
  }
}
