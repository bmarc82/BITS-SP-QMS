#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Schritt 4: QMS-Prozesslandkarte (SharePoint Liste) erstellen
.DESCRIPTION
    Legt die Liste "QMS-Prozesse" an und konfiguriert alle Spalten.
    Prozessart und Bereich werden als Managed Metadata Felder angelegt.
    Voraussetzung: 02b_Create-TermStore.ps1 wurde ausgeführt.

    Wenn ein neuer Eintrag in dieser Liste angelegt wird, löst ein
    Power Automate Flow (process-to-termstore) automatisch die Erstellung
    des entsprechenden Terms im Term Set "Prozesse" aus.
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Erstelle Prozesslandkarte (QMS-Prozesse)..." -Module 'ProcessList'

# ── Term Set IDs laden ────────────────────────────────────────────────────────

$idsPath = "$PSScriptRoot/../config/termstore-ids.json"
if (-not (Test-Path $idsPath)) {
    Write-QMSLog "termstore-ids.json nicht gefunden. Bitte zuerst 02b_Create-TermStore.ps1 ausführen." -Level ERROR
    exit 1
}
$termSetIds = Get-Content $idsPath -Raw | ConvertFrom-Json

# ── Liste sicherstellen ───────────────────────────────────────────────────────

$listName = 'QMS-Prozesse'
$list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if (-not $list) {
    if ($PSCmdlet.ShouldProcess($listName, 'Liste erstellen')) {
        New-PnPList -Title $listName -Template GenericList -EnableVersioning
        Write-QMSLog "Liste erstellt: $listName" -Module 'ProcessList'
    }
}

# ── Hilfsfunktion ─────────────────────────────────────────────────────────────

function Add-QMSFieldIfMissing {
    param([string]$List, [string]$Name, [scriptblock]$CreateAction)
    $f = Get-PnPField -List $List -Identity $Name -ErrorAction SilentlyContinue
    if ($f) {
        Write-QMSLog "Spalte bereits vorhanden: $Name" -Level WARNING -Module 'ProcessList'
        return
    }
    Write-QMSLog "Füge Spalte hinzu: $Name" -Module 'ProcessList'
    & $CreateAction
    Write-QMSLog "Spalte hinzugefügt: $Name" -Module 'ProcessList'
}

# ── Standard-Spalten ──────────────────────────────────────────────────────────

Add-QMSFieldIfMissing -List $listName -Name 'QMSProzessverantwortlicher' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSProzessverantwortlicher' `
        -InternalName 'QMSProzessverantwortlicher' -Type User -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSProzessbeschreibung' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSProzessbeschreibung' `
        -InternalName 'QMSProzessbeschreibung' -Type Note -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSISOKapitel' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSISOKapitel' `
        -InternalName 'QMSISOKapitel' -Type Text -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSStatus' -CreateAction {
    $xml = "<Field Type='Choice' DisplayName='QMSStatus' Name='QMSStatus' Required='FALSE'>" +
           "<Default>Aktiv</Default><CHOICES>" +
           "<CHOICE>Aktiv</CHOICE><CHOICE>In Überarbeitung</CHOICE><CHOICE>Inaktiv</CHOICE>" +
           "</CHOICES></Field>"
    Add-PnPFieldFromXml -List $listName -FieldXml $xml | Out-Null
}

# ── Managed Metadata Spalten (Term Store) ─────────────────────────────────────

Add-QMSFieldIfMissing -List $listName -Name 'QMSProzessart' -CreateAction {
    Add-PnPTaxonomyField -List $listName `
        -DisplayName    'QMSProzessart' `
        -InternalName   'QMSProzessart' `
        -TaxonomyItemId $termSetIds.Prozessart `
        -MultiValue:    $false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSBereich' -CreateAction {
    Add-PnPTaxonomyField -List $listName `
        -DisplayName    'QMSBereich' `
        -InternalName   'QMSBereich' `
        -TaxonomyItemId $termSetIds.Bereich `
        -MultiValue:    $false | Out-Null
}

# ── Standardansicht konfigurieren ─────────────────────────────────────────────

Write-QMSLog "Konfiguriere Standardansicht..." -Module 'ProcessList'
$view = Get-PnPView -List $listName -Identity 'Alle Elemente' -ErrorAction SilentlyContinue
if ($view) {
    Set-PnPView -List $listName -Identity $view.Id -Fields @(
        'Title'
        'QMSProzessart'
        'QMSBereich'
        'QMSProzessverantwortlicher'
        'QMSISOKapitel'
        'QMSStatus'
    ) | Out-Null
    Write-QMSLog "Standardansicht konfiguriert." -Module 'ProcessList'
}

Write-QMSLog "Prozesslandkarte vollständig erstellt." -Module 'ProcessList'
