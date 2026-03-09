# PowerShell Scripts

Vollständige Provisionierung und Wartung der M365-Infrastruktur als Code.

## Alle Scripts sind idempotent und für CI/CD-Pipelines geeignet.

## Reihenfolge der Provisionierungsschritte

1. `01_Create-QMSSite.ps1` – Communication Site anlegen
2. `02_Deploy-ContentTypes.ps1` – Inhaltstypen im Content Type Hub
3. `03_Configure-Library.ps1` – Dokumentenbibliothek konfigurieren
4. `04_Create-ProcessList.ps1` – Prozesslandkarte (SharePoint Liste)
5. `05_Set-Permissions.ps1` – Berechtigungsgruppen und Rollen
6. `06_Deploy-SPFx.ps1` – SPFx Webparts deployen
7. `07_Import-FlowTemplates.ps1` – Power Automate Flows importieren

## Voraussetzungen

- PowerShell 7.x
- PnP PowerShell 2.x
- Azure AD App Registration (App-Only)

## Setup

```powershell
# Verbindungskonfiguration anpassen
.\config\connection.config.ps1

# Ersten Schritt ausführen
.\provisioning\01_Create-QMSSite.ps1
```
