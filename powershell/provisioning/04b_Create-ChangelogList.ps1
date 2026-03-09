#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Schritt 4b: QMS-Changelog Liste erstellen
.DESCRIPTION
    Legt die Liste "QMS-Changelog" an. Pro Genehmigung wird automatisch
    ein Eintrag durch den Power Automate Freigabe-Workflow erstellt.

    Spaltenstruktur:
    ┌──────────────────────────────┬───────────┬─────────────────────────────┐
    │ Spalte                       │ Typ       │ Beschreibung                │
    ├──────────────────────────────┼───────────┼─────────────────────────────┤
    │ Title                        │ Text      │ Dokumentname (auto)         │
    │ QMSVersion                   │ Text      │ Versionsnummer (z.B. 1.2)   │
    │ QMSAenderungsart             │ Choice    │ Art der Änderung            │
    │ QMSAenderungsbeschreibung    │ Note      │ Was wurde geändert?         │
    │ QMSDokumentId                │ Number    │ SP Item ID des Dokuments    │
    │ QMSDokumentUrl               │ URL       │ Direktlink zum Dokument     │
    │ QMSProzess                   │ Taxonomy  │ Verknüpfter Prozess         │
    │ QMSBereich                   │ Taxonomy  │ Bereich                     │
    │ QMSErsteller                 │ User      │ Wer hat eingereicht         │
    │ QMSFreigeber                 │ User      │ Wer hat genehmigt           │
    │ QMSFreigegebenAm             │ DateTime  │ Genehmigungszeitpunkt       │
    │ QMSFreigabeKommentar         │ Note      │ Kommentar des Freigebers    │
    └──────────────────────────────┴───────────┴─────────────────────────────┘

    Ergänzend werden in QMS-Dokumente drei neue Felder angelegt:
    - QMSVersion, QMSAenderungsart, QMSAenderungsbeschreibung
    Diese werden vor der Einreichung via Adaptive Card befüllt.
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Erstelle QMS-Changelog Liste..." -Module 'Changelog'

# ── Term Set IDs laden ────────────────────────────────────────────────────────

$idsPath = "$PSScriptRoot/../config/termstore-ids.json"
if (-not (Test-Path $idsPath)) {
    Write-QMSLog "termstore-ids.json nicht gefunden. Bitte zuerst 02b_Create-TermStore.ps1 ausführen." -Level ERROR
    exit 1
}
$termSetIds = Get-Content $idsPath -Raw | ConvertFrom-Json

# ── Hilfsfunktion ─────────────────────────────────────────────────────────────

function Add-QMSFieldIfMissing {
    param([string]$List, [string]$Name, [scriptblock]$CreateAction)
    $f = Get-PnPField -List $List -Identity $Name -ErrorAction SilentlyContinue
    if ($f) {
        Write-QMSLog "Spalte bereits vorhanden: $Name" -Level WARNING -Module 'Changelog'
        return
    }
    Write-QMSLog "Füge Spalte hinzu: $Name" -Module 'Changelog'
    & $CreateAction
    Write-QMSLog "Spalte hinzugefügt: $Name" -Module 'Changelog'
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEIL 1: QMS-Changelog Liste anlegen
# ═══════════════════════════════════════════════════════════════════════════════

$changelogName = 'QMS-Changelog'
$list = Get-PnPList -Identity $changelogName -ErrorAction SilentlyContinue

if (-not $list) {
    if ($PSCmdlet.ShouldProcess($changelogName, 'Liste erstellen')) {
        New-PnPList -Title $changelogName -Template GenericList `
            -EnableVersioning -OnQuickLaunch:$false
        Write-QMSLog "Liste erstellt: $changelogName" -Module 'Changelog'
    }
}

# Schreibschutz für alle ausser Administratoren und Power Automate Service Account
# (Einträge werden nur durch den Flow erstellt – nicht manuell)
Set-PnPListPermission -Identity $changelogName -Group 'QMS-Leser'                  -AddRole 'Read'         | Out-Null
Set-PnPListPermission -Identity $changelogName -Group 'QMS-Prozessverantwortliche' -AddRole 'Read'         | Out-Null
Set-PnPListPermission -Identity $changelogName -Group 'QMS-Freigeber'              -AddRole 'Read'         | Out-Null
Set-PnPListPermission -Identity $changelogName -Group 'QMS-Administratoren'        -AddRole 'Full Control' | Out-Null

# ── Spalten Changelog ─────────────────────────────────────────────────────────

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSVersion' -CreateAction {
    Add-PnPField -List $changelogName -DisplayName 'QMSVersion' `
        -InternalName 'QMSVersion' -Type Text -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSAenderungsart' -CreateAction {
    $xml = "<Field Type='Choice' DisplayName='QMSAenderungsart' Name='QMSAenderungsart' Required='FALSE'>" +
           "<CHOICES>" +
           "<CHOICE>Erstausgabe</CHOICE>" +
           "<CHOICE>Inhaltliche Änderung</CHOICE>" +
           "<CHOICE>Formale Korrektur</CHOICE>" +
           "<CHOICE>Archiviert</CHOICE>" +
           "</CHOICES></Field>"
    Add-PnPFieldFromXml -List $changelogName -FieldXml $xml | Out-Null
}

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSAenderungsbeschreibung' -CreateAction {
    Add-PnPField -List $changelogName -DisplayName 'QMSAenderungsbeschreibung' `
        -InternalName 'QMSAenderungsbeschreibung' -Type Note -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSDokumentId' -CreateAction {
    Add-PnPField -List $changelogName -DisplayName 'QMSDokumentId' `
        -InternalName 'QMSDokumentId' -Type Number -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSDokumentUrl' -CreateAction {
    Add-PnPField -List $changelogName -DisplayName 'QMSDokumentUrl' `
        -InternalName 'QMSDokumentUrl' -Type URL -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSErsteller' -CreateAction {
    Add-PnPField -List $changelogName -DisplayName 'QMSErsteller' `
        -InternalName 'QMSErsteller' -Type User -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSFreigeber' -CreateAction {
    Add-PnPField -List $changelogName -DisplayName 'QMSFreigeber' `
        -InternalName 'QMSFreigeber' -Type User -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSFreigegebenAm' -CreateAction {
    Add-PnPField -List $changelogName -DisplayName 'QMSFreigegebenAm' `
        -InternalName 'QMSFreigegebenAm' -Type DateTime -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSFreigabeKommentar' -CreateAction {
    Add-PnPField -List $changelogName -DisplayName 'QMSFreigabeKommentar' `
        -InternalName 'QMSFreigabeKommentar' -Type Note -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSProzess' -CreateAction {
    Add-PnPTaxonomyField -List $changelogName `
        -DisplayName    'QMSProzess' `
        -InternalName   'QMSProzess' `
        -TaxonomyItemId $termSetIds.Prozesse `
        -MultiValue:    $false | Out-Null
}

Add-QMSFieldIfMissing -List $changelogName -Name 'QMSBereich' -CreateAction {
    Add-PnPTaxonomyField -List $changelogName `
        -DisplayName    'QMSBereich' `
        -InternalName   'QMSBereich' `
        -TaxonomyItemId $termSetIds.Bereich `
        -MultiValue:    $false | Out-Null
}

# ── Standardansicht konfigurieren ─────────────────────────────────────────────

$view = Get-PnPView -List $changelogName -Identity 'Alle Elemente' -ErrorAction SilentlyContinue
if ($view) {
    Set-PnPView -List $changelogName -Identity $view.Id -Fields @(
        'Title'
        'QMSVersion'
        'QMSAenderungsart'
        'QMSAenderungsbeschreibung'
        'QMSFreigeber'
        'QMSFreigegebenAm'
        'QMSProzess'
        'QMSBereich'
    ) | Out-Null
}

Write-QMSLog "QMS-Changelog Liste vollständig erstellt." -Module 'Changelog'

# ═══════════════════════════════════════════════════════════════════════════════
# TEIL 2: Änderungsfelder in QMS-Dokumente ergänzen
# ═══════════════════════════════════════════════════════════════════════════════

Write-QMSLog "Ergänze Änderungsfelder in QMS-Dokumente..." -Module 'Changelog'

$docLib = 'QMS-Dokumente'

Add-QMSFieldIfMissing -List $docLib -Name 'QMSVersion' -CreateAction {
    Add-PnPField -List $docLib -DisplayName 'QMSVersion' `
        -InternalName 'QMSVersion' -Type Text -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $docLib -Name 'QMSAenderungsart' -CreateAction {
    $xml = "<Field Type='Choice' DisplayName='QMSAenderungsart' Name='QMSAenderungsart' Required='FALSE'>" +
           "<CHOICES>" +
           "<CHOICE>Erstausgabe</CHOICE>" +
           "<CHOICE>Inhaltliche Änderung</CHOICE>" +
           "<CHOICE>Formale Korrektur</CHOICE>" +
           "<CHOICE>Archiviert</CHOICE>" +
           "</CHOICES></Field>"
    Add-PnPFieldFromXml -List $docLib -FieldXml $xml | Out-Null
}

Add-QMSFieldIfMissing -List $docLib -Name 'QMSAenderungsbeschreibung' -CreateAction {
    Add-PnPField -List $docLib -DisplayName 'QMSAenderungsbeschreibung' `
        -InternalName 'QMSAenderungsbeschreibung' -Type Note -Required:$false | Out-Null
}

Write-QMSLog "Änderungsfelder in QMS-Dokumente ergänzt." -Module 'Changelog'
