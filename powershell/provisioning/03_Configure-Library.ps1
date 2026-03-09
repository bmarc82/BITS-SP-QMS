#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Schritt 3: QMS-Dokumentenbibliothek konfigurieren
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Konfiguriere Dokumentenbibliothek..."

$listName = 'QMS-Dokumente'
$existing = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if (-not $existing) {
    if ($PSCmdlet.ShouldProcess($listName, 'Bibliothek erstellen')) {
        New-PnPList -Title $listName -Template DocumentLibrary -EnableVersioning -MajorVersions 10
        Write-QMSLog "Bibliothek erstellt: $listName"
    }
}

# Spalten hinzufügen
$fields = @(
    @{ Name = 'QMSStatus';               Type = 'Choice'; Choices = @('Entwurf','In Prüfung','Freigegeben','Archiviert') },
    @{ Name = 'QMSProzessverantwortlicher'; Type = 'User' },
    @{ Name = 'QMSGueltigAb';            Type = 'DateTime' },
    @{ Name = 'QMSNaechstesPruefDatum';  Type = 'DateTime' },
    @{ Name = 'QMSISOKapitel';           Type = 'Text' },
    @{ Name = 'QMSProzessart';           Type = 'Choice'; Choices = @('Führungsprozess','Kernprozess','Supportprozess') }
)

foreach ($field in $fields) {
    Write-QMSLog "Füge Spalte hinzu: $($field.Name)"
    # Add-PnPField ...
}
