#Requires -Version 7.0
<#
.SYNOPSIS
    QMS.SharePoint – Wrapper-Modul für SharePoint-Operationen
.DESCRIPTION
    Kapselt die häufig genutzten SharePoint-Operationen der Provisioning-Scripts.
    Alle Funktionen sind idempotent und nutzen QMS.Core für Logging.
.VERSION
    1.0.0
#>

# ── New-QMSSite ───────────────────────────────────────────────────────────────

function New-QMSSite {
    <#
    .SYNOPSIS
        QMS Communication Site anlegen (idempotent)
    .PARAMETER TenantUrl
        Root-URL des Tenants (z.B. https://contoso.sharepoint.com)
    .PARAMETER SiteAlias
        URL-Alias der Site (z.B. 'qms' → /sites/qms)
    .PARAMETER SiteTitle
        Anzeigename der Site
    .PARAMETER Owner
        E-Mail-Adresse des Site-Besitzers
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$TenantUrl,
        [Parameter(Mandatory)][string]$SiteAlias,
        [string]$SiteTitle = 'Qualitätsmanagementsystem',
        [Parameter(Mandatory)][string]$Owner
    )

    $siteUrl = "$TenantUrl/sites/$SiteAlias"
    Write-QMSLog "Prüfe Site: $siteUrl" -Module 'SharePoint'

    $existing = Get-PnPTenantSite -Url $siteUrl -ErrorAction SilentlyContinue
    if ($existing) {
        Write-QMSLog "Site bereits vorhanden: $siteUrl" -Level WARNING -Module 'SharePoint'
        return $existing
    }

    if ($PSCmdlet.ShouldProcess($siteUrl, 'Communication Site erstellen')) {
        Write-QMSLog "Erstelle Communication Site: $siteUrl" -Module 'SharePoint'
        $site = New-PnPSite -Type CommunicationSite `
            -Title $SiteTitle `
            -Url   $siteUrl `
            -Owner $Owner `
            -Lcid  2055    # de-CH
        Write-QMSLog "Site erstellt: $siteUrl" -Module 'SharePoint'
        return $site
    }
}

# ── Set-QMSContentTypes ───────────────────────────────────────────────────────

function Set-QMSContentTypes {
    <#
    .SYNOPSIS
        QMS-Inhaltstypen im Content Type Hub deployen (idempotent)
    .PARAMETER SiteUrl
        URL der QMS-Site
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$SiteUrl
    )

    $contentTypes = @(
        @{ Name = 'QMS-Prozessbeschreibung'; Description = 'Beschreibung eines Geschäftsprozesses'; Group = 'QMS Inhaltstypen' }
        @{ Name = 'QMS-Arbeitsanweisung';    Description = 'Detaillierte Arbeitsanweisung';          Group = 'QMS Inhaltstypen' }
        @{ Name = 'QMS-Formular';            Description = 'QMS-Formular und Vorlage';               Group = 'QMS Inhaltstypen' }
        @{ Name = 'QMS-Nachweis';            Description = 'Nachweis und Aufzeichnung';              Group = 'QMS Inhaltstypen' }
    )

    Write-QMSLog "Deploye $($contentTypes.Count) Inhaltstypen..." -Module 'SharePoint'

    foreach ($ct in $contentTypes) {
        $existing = Get-PnPContentType -Identity $ct.Name -ErrorAction SilentlyContinue
        if ($existing) {
            Write-QMSLog "Inhaltstyp bereits vorhanden: $($ct.Name)" -Level WARNING -Module 'SharePoint'
            continue
        }
        if ($PSCmdlet.ShouldProcess($ct.Name, 'Inhaltstyp erstellen')) {
            Add-PnPContentType -Name $ct.Name -Description $ct.Description -Group $ct.Group | Out-Null
            Write-QMSLog "Inhaltstyp erstellt: $($ct.Name)" -Module 'SharePoint'
        }
    }
}

# ── Set-QMSLibrary ────────────────────────────────────────────────────────────

function Set-QMSLibrary {
    <#
    .SYNOPSIS
        QMS-Dokumentenbibliothek konfigurieren (idempotent)
    .DESCRIPTION
        Delegiert an 03_Configure-Library.ps1. Kann auch direkt aufgerufen werden.
    .PARAMETER SiteUrl
        URL der QMS-Site
    .PARAMETER TermStoreIdsPath
        Pfad zur termstore-ids.json Datei
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$SiteUrl,
        [string]$TermStoreIdsPath = "$PSScriptRoot/../../config/termstore-ids.json"
    )

    if (-not (Test-Path $TermStoreIdsPath)) {
        throw "termstore-ids.json nicht gefunden: $TermStoreIdsPath. Bitte 02b_Create-TermStore.ps1 ausführen."
    }

    Write-QMSLog "Konfiguriere Dokumentenbibliothek via Script..." -Module 'SharePoint'
    & "$PSScriptRoot/../../provisioning/03_Configure-Library.ps1"
}

# ── Set-QMSPermissions ────────────────────────────────────────────────────────

function Set-QMSPermissions {
    <#
    .SYNOPSIS
        QMS-Berechtigungsgruppen und Rollen konfigurieren (idempotent)
    .DESCRIPTION
        Delegiert an 05_Set-Permissions.ps1. Kann auch direkt aufgerufen werden.
    .PARAMETER SiteUrl
        URL der QMS-Site
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$SiteUrl
    )

    Write-QMSLog "Konfiguriere Berechtigungen via Script..." -Module 'SharePoint'
    & "$PSScriptRoot/../../provisioning/05_Set-Permissions.ps1"
}

# ── Get-QMSDocuments ──────────────────────────────────────────────────────────

function Get-QMSDocuments {
    <#
    .SYNOPSIS
        QMS-Dokumente aus der Bibliothek abrufen
    .PARAMETER Status
        Filtert nach QMSStatus (z.B. 'Freigegeben')
    .PARAMETER DueForReview
        Gibt nur Dokumente zurück, deren Review in X Tagen fällig ist
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Entwurf','In Prüfung','Freigegeben','Archiviert','Alle')]
        [string]$Status = 'Alle',
        [int]$DueForReviewInDays = 0
    )

    $camlQuery = '<View><Query><Where>'

    if ($Status -ne 'Alle') {
        $camlQuery += "<Eq><FieldRef Name='QMSStatus'/><Value Type='Choice'>$Status</Value></Eq>"
    }

    if ($DueForReviewInDays -gt 0) {
        $dueDate = (Get-Date).AddDays($DueForReviewInDays).ToString('yyyy-MM-ddTHH:mm:ssZ')
        $dueCaml = "<Leq><FieldRef Name='QMSNaechstesPruefDatum'/><Value Type='DateTime'>$dueDate</Value></Leq>"
        if ($Status -ne 'Alle') {
            $camlQuery = '<View><Query><Where><And>' + $camlQuery.Replace('<View><Query><Where>','') + $dueCaml + '</And>'
        } else {
            $camlQuery += $dueCaml
        }
    }

    $camlQuery += '</Where></Query></View>'

    return Get-PnPListItem -List 'QMS-Dokumente' -Query $camlQuery
}
