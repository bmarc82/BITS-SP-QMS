#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Schritt 06: Deploy-SPFx
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Starte: Deploy-SPFx..."

# TODO: Implementierung
throw "Noch nicht implementiert: Deploy-SPFx"
