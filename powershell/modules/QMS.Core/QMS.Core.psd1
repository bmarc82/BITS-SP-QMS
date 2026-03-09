@{
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'QMS Team'
    Description       = 'QMS Kernmodul: Hilfsfunktionen, Logging, Konfigurationsverwaltung'
    PowerShellVersion = '7.0'
    RootModule        = 'QMS.Core.psm1'
    FunctionsToExport = @('Write-QMSLog', 'Get-QMSConfig', 'Test-QMSConnection', 'Invoke-QMSWithRetry')
}
