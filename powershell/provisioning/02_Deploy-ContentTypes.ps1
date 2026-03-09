#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Schritt 2: Inhaltstypen im Content Type Hub deployen
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Deploye Inhaltstypen..."

$contentTypes = @(
    @{ Name = 'QMS-Prozessbeschreibung';  Description = 'Beschreibung eines Geschäftsprozesses' },
    @{ Name = 'QMS-Arbeitsanweisung';     Description = 'Detaillierte Arbeitsanweisung' },
    @{ Name = 'QMS-Formular';             Description = 'QMS-Formular und Vorlage' },
    @{ Name = 'QMS-Nachweis';             Description = 'Nachweis und Aufzeichnung' }
)

foreach ($ct in $contentTypes) {
    $existing = Get-PnPContentType -Identity $ct.Name -ErrorAction SilentlyContinue
    if ($existing) {
        Write-QMSLog "Inhaltstyp bereits vorhanden: $($ct.Name)" -Level WARNING
    } else {
        if ($PSCmdlet.ShouldProcess($ct.Name, 'Inhaltstyp erstellen')) {
            Add-PnPContentType -Name $ct.Name -Description $ct.Description -Group 'QMS Inhaltstypen'
            Write-QMSLog "Inhaltstyp erstellt: $($ct.Name)"
        }
    }
}
