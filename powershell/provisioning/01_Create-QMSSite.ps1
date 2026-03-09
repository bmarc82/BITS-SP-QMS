#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core, QMS.SharePoint
<#
.SYNOPSIS
    Schritt 1: QMS Communication Site anlegen
.DESCRIPTION
    Erstellt die QMS-SharePoint-Site als Communication Site im angegebenen Tenant.
    Idempotent: Prüft zuerst, ob die Site bereits existiert.
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$SiteAlias = 'qms',
    [string]$SiteTitle = 'Qualitätsmanagementsystem'
)

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

$siteUrl = "$($Config.TenantUrl)/sites/$SiteAlias"

Write-QMSLog "Prüfe ob Site bereits existiert: $siteUrl"
$existingSite = Get-PnPTenantSite -Url $siteUrl -ErrorAction SilentlyContinue

if ($existingSite) {
    Write-QMSLog "Site existiert bereits – überspringe Erstellung" -Level WARNING
} else {
    Write-QMSLog "Erstelle Communication Site: $siteUrl"
    if ($PSCmdlet.ShouldProcess($siteUrl, 'Communication Site erstellen')) {
        New-PnPSite -Type CommunicationSite -Title $SiteTitle -Url $siteUrl -Owner $Config.AdminEmail
        Write-QMSLog "Site erfolgreich erstellt"
    }
}
