/**
 * Konfigurationsdienst mit verschlüsselter Speicherung
 */

export interface TenantConfig {
  tenantUrl: string;
  appId: string;
  certThumbprint?: string;
  clientSecret?: string;
  siteUrl: string;
}

export class ConfigService {
  private readonly configPath = './config/tenant.enc.json';

  async save(config: TenantConfig): Promise<void> {
    // Verschlüsselt speichern (AES-256)
    throw new Error('Nicht implementiert');
  }

  async load(): Promise<TenantConfig | null> {
    // Entschlüsseln und laden
    throw new Error('Nicht implementiert');
  }
}
