#Requires -Version 7.0
<#
.SYNOPSIS
    QMS SharePoint-Operationen
#>

function New-QMSSite {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$TenantUrl,
        [Parameter(Mandatory)][string]$SiteAlias,
        [string]$SiteTitle = 'QMS',
        [string]$Owner
    )
    Write-QMSLog "Erstelle QMS Communication Site: $SiteAlias" -Module 'SharePoint'
    # New-PnPSite -Type CommunicationSite ...
    throw 'Nicht implementiert'
}

function Set-QMSContentTypes {
    [CmdletBinding()]
    param([string]$SiteUrl)
    Write-QMSLog "Deploye Inhaltstypen" -Module 'SharePoint'
    throw 'Nicht implementiert'
}

function Set-QMSLibrary {
    [CmdletBinding()]
    param([string]$SiteUrl)
    Write-QMSLog "Konfiguriere Dokumentenbibliothek" -Module 'SharePoint'
    throw 'Nicht implementiert'
}

function Set-QMSPermissions {
    [CmdletBinding()]
    param([string]$SiteUrl)
    Write-QMSLog "Konfiguriere Berechtigungen" -Module 'SharePoint'
    throw 'Nicht implementiert'
}
