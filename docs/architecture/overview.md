# Gesamtarchitektur – QMS M365

## Architekturprinzipien

- **IaC**: Alle Konfigurationen als Code versioniert
- **App-Only Auth**: Keine interaktiven Logins in Produktion
- **Modularität**: Jedes Modul unabhängig deploybar
- **Sicherheit**: Verschlüsselte Credentials, Least Privilege

## Systemkomponenten

```
┌─────────────────────────────────────────────────────┐
│                  Microsoft 365 Tenant                │
│                                                     │
│  ┌──────────┐  ┌─────────────┐  ┌───────────────┐  │
│  │SharePoint│  │Power Automate│  │  Teams/Bot    │  │
│  │  + SPFx  │  │   Flows      │  │  Framework    │  │
│  └──────────┘  └─────────────┘  └───────────────┘  │
│                                                     │
│  ┌──────────┐  ┌─────────────┐  ┌───────────────┐  │
│  │Power Apps│  │Adaptive Cards│  │  Copilot Std. │  │
│  └──────────┘  └─────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────┘
           ↑ PnP PowerShell (App-Only)
┌──────────────────────┐
│     Admin Tool        │
│  (Electron / PWA)     │
└──────────────────────┘
```

## Abhängigkeiten

Siehe [module-dependencies.md](module-dependencies.md)
