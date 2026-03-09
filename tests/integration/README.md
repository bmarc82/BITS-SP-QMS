# Integrationstests

End-to-End Integrationstests gegen einen Test-Tenant.

## Voraussetzungen

- Separater M365 Test-Tenant
- Umgebungsvariable `QMS_ENV=TEST`

## Ausführen

```powershell
$env:QMS_ENV = 'TEST'
Invoke-Pester ./tests/integration -Output Detailed
```
