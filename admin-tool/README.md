# Admin Tool

Grafische Oberfläche zur Installation, Konfiguration und Wartung des QMS M365 Systems.

## Zweck

Richtet sich an QM-Administratoren ohne tiefe PowerShell-Kenntnisse.

## Funktionen

- **Verbindungsverwaltung**: Tenant-URL, AppID, Zertifikat verschlüsselt speichern
- **Modulinstallation**: Schritt-für-Schritt Installationsassistent
- **Dashboard**: Status aller Module und Health Check
- **Wartung**: Backup, Update, Logs, Deinstallation

## Technologie

- Electron (Desktop) oder PWA (Browser)
- React + TypeScript
- PnP PowerShell Bridge

## Setup

```bash
cd admin-tool
npm install
npm run dev
```

## Abhängigkeiten

- Node.js >= 18
- PnP PowerShell >= 2.x
- Azure AD App Registration mit App-Only Berechtigungen
