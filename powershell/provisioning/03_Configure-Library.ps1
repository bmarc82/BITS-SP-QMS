#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Schritt 3: QMS-Dokumentenbibliothek konfigurieren
.DESCRIPTION
    Legt die QMS-Dokumentenbibliothek an und konfiguriert alle Spalten.
    Prozessart, Bereich und Prozess werden als Managed Metadata Felder
    angelegt (Term Store). Voraussetzung: 02b_Create-TermStore.ps1 wurde
    bereits ausgeführt (termstore-ids.json muss vorhanden sein).
.VERSION
    1.1.0
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Konfiguriere Dokumentenbibliothek..."

# ── Term Set IDs laden (aus 02b_Create-TermStore.ps1) ────────────────────────

$idsPath = "$PSScriptRoot/../config/termstore-ids.json"
if (-not (Test-Path $idsPath)) {
    Write-QMSLog "termstore-ids.json nicht gefunden. Bitte zuerst 02b_Create-TermStore.ps1 ausführen." -Level ERROR
    exit 1
}
$termSetIds = Get-Content $idsPath -Raw | ConvertFrom-Json

# ── Bibliothek sicherstellen ──────────────────────────────────────────────────

$listName = 'QMS-Dokumente'
$list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if (-not $list) {
    if ($PSCmdlet.ShouldProcess($listName, 'Bibliothek erstellen')) {
        New-PnPList -Title $listName -Template DocumentLibrary -EnableVersioning -MajorVersions 10
        Write-QMSLog "Bibliothek erstellt: $listName"
    }
}

# ── Hilfsfunktion: Spalte idempotent anlegen ──────────────────────────────────

function Add-QMSFieldIfMissing {
    param([string]$List, [string]$Name, [scriptblock]$CreateAction)
    $f = Get-PnPField -List $List -Identity $Name -ErrorAction SilentlyContinue
    if ($f) {
        Write-QMSLog "Spalte bereits vorhanden: $Name" -Level WARNING
        return
    }
    Write-QMSLog "Füge Spalte hinzu: $Name"
    & $CreateAction
    Write-QMSLog "Spalte hinzugefügt: $Name"
}

# ── Standard-Spalten (Choice / User / DateTime / Text) ───────────────────────

Add-QMSFieldIfMissing -List $listName -Name 'QMSStatus' -CreateAction {
    $xml = "<Field Type='Choice' DisplayName='QMSStatus' Name='QMSStatus' Required='FALSE'>" +
           "<Default>Entwurf</Default><CHOICES>" +
           "<CHOICE>Entwurf</CHOICE><CHOICE>In Prüfung</CHOICE>" +
           "<CHOICE>Freigegeben</CHOICE><CHOICE>Archiviert</CHOICE>" +
           "</CHOICES></Field>"
    Add-PnPFieldFromXml -List $listName -FieldXml $xml | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSProzessverantwortlicher' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSProzessverantwortlicher' `
        -InternalName 'QMSProzessverantwortlicher' -Type User -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSGueltigAb' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSGueltigAb' `
        -InternalName 'QMSGueltigAb' -Type DateTime -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSNaechstesPruefDatum' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSNaechstesPruefDatum' `
        -InternalName 'QMSNaechstesPruefDatum' -Type DateTime -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSISOKapitel' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSISOKapitel' `
        -InternalName 'QMSISOKapitel' -Type Text -Required:$false | Out-Null
}

# ── Managed Metadata Spalten (Term Store) ─────────────────────────────────────

Add-QMSFieldIfMissing -List $listName -Name 'QMSProzessart' -CreateAction {
    Add-PnPTaxonomyField -List $listName `
        -DisplayName      'QMSProzessart' `
        -InternalName     'QMSProzessart' `
        -TaxonomyItemId   $termSetIds.Prozessart `
        -MultiValue:      $false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSBereich' -CreateAction {
    Add-PnPTaxonomyField -List $listName `
        -DisplayName      'QMSBereich' `
        -InternalName     'QMSBereich' `
        -TaxonomyItemId   $termSetIds.Bereich `
        -MultiValue:      $false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSProzess' -CreateAction {
    # Verknüpfung zu einem Term aus dem dynamischen Term Set "Prozesse"
    # Wird befüllt wenn ein Dokument einem Prozess zugeordnet wird
    Add-PnPTaxonomyField -List $listName `
        -DisplayName      'QMSProzess' `
        -InternalName     'QMSProzess' `
        -TaxonomyItemId   $termSetIds.Prozesse `
        -MultiValue:      $false | Out-Null
}

Write-QMSLog "Dokumentenbibliothek vollständig konfiguriert."
