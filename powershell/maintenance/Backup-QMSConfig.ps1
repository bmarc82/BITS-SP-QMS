#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    QMS-Konfiguration als PnP-Template exportieren
#>
[CmdletBinding()]
param([string]$OutputPath = "./backup/QMS-Backup-$(Get-Date -Format 'yyyyMMdd').pnp")

$Config = Get-QMSConfig
Connect-PnPOnline -Url $Config.SiteUrl -ClientId $Config.AppId -Thumbprint $Config.CertThumbprint -Tenant $Config.TenantId
Get-PnPSiteTemplate -Out $OutputPath
Write-QMSLog "Backup erstellt: $OutputPath"
