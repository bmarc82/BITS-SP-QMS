#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Erweiterungsmodul installieren: ISO 45001 Arbeitssicherheit
.DESCRIPTION
    Aktiviert das ISO 45001 Arbeitssicherheit-Erweiterungsmodul ohne die Kernstruktur zu verändern.
.VERSION
    1.0.0
#>
[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Installiere Erweiterungsmodul: ISO 45001 Arbeitssicherheit"
# TODO: Implementierung
throw "Noch nicht implementiert"
