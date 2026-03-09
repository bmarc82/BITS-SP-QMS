#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Schritt 4c: QMS-KVP Liste erstellen (Kontinuierlicher Verbesserungsprozess)
.DESCRIPTION
    Implementiert den KVP nach ISO 9001:2015 Kapitel 10.3 als SharePoint-Liste.

    PDCA-Zyklus im Status-Feld:
    ┌─────────────────────────────────────────────────────────┐
    │  P (Plan)  → Offen / Massnahme definiert               │
    │  D (Do)    → In Bearbeitung                            │
    │  C (Check) → Wirksamkeitsprüfung                       │
    │  A (Act)   → Abgeschlossen / Standard aktualisiert     │
    │              Abgelehnt (für nicht weiterzuverfolgende) │
    └─────────────────────────────────────────────────────────┘

    Spaltenstruktur:
    ┌─────────────────────────────┬───────────┬──────────────────────────────────┐
    │ Spalte                      │ Typ       │ ISO 9001:2015 Bezug              │
    ├─────────────────────────────┼───────────┼──────────────────────────────────┤
    │ Title                       │ Text      │ Kurztitel der Verbesserung       │
    │ QMSKVPTyp                   │ Choice    │ 10.1 / 10.2 / 10.3              │
    │ QMSQuelle                   │ Choice    │ 9.1.2 / 9.2 / 9.3              │
    │ QMSPrioritaet               │ Choice    │ –                               │
    │ QMSBereich                  │ Taxonomy  │ –                               │
    │ QMSProzess                  │ Taxonomy  │ 4.4 Prozesse                   │
    │ QMSISOKapitel               │ Text      │ –                               │
    │ QMSBeschreibung             │ Note      │ Ist-Zustand / Problem           │
    │ QMSZielzustand              │ Note      │ Soll-Zustand                   │
    │ QMSUrsache                  │ Note      │ Ursachenanalyse (5-Why / Ishikawa)│
    │ QMSMassnahme                │ Note      │ Geplante Massnahme              │
    │ QMSVerantwortlicher         │ User      │ –                               │
    │ QMSErfasser                 │ User      │ –                               │
    │ QMSZieldatum                │ DateTime  │ –                               │
    │ QMSStatus                   │ Choice    │ PDCA                           │
    │ QMSFortschritt              │ Number    │ 0–100 %                        │
    │ QMSWirksamkeitsbeschreibung │ Note      │ C (Check) – Nachweisführung     │
    │ QMSWirksamkeitsdatum        │ DateTime  │ –                               │
    │ QMSWirksamkeitsstatus       │ Choice    │ –                               │
    │ QMSWirksamkeitsprueferIn    │ User      │ –                               │
    │ QMSAbgeschlossenAm          │ DateTime  │ –                               │
    │ QMSVerknuepfteDokumente     │ Note      │ Links zu geänderten Prozessen   │
    └─────────────────────────────┴───────────┴──────────────────────────────────┘
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Erstelle KVP-Liste (ISO 9001:2015 Kap. 10.3)..." -Module 'KVP'

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
        Write-QMSLog "Spalte bereits vorhanden: $Name" -Level WARNING -Module 'KVP'
        return
    }
    Write-QMSLog "Füge Spalte hinzu: $Name" -Module 'KVP'
    & $CreateAction
    Write-QMSLog "Spalte hinzugefügt: $Name" -Module 'KVP'
}

# ── Liste sicherstellen ───────────────────────────────────────────────────────

$listName = 'QMS-KVP'
$list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if (-not $list) {
    if ($PSCmdlet.ShouldProcess($listName, 'KVP-Liste erstellen')) {
        New-PnPList -Title $listName -Template GenericList -EnableVersioning
        Write-QMSLog "Liste erstellt: $listName" -Module 'KVP'
    }
}

# ── Klassifizierung ───────────────────────────────────────────────────────────

Add-QMSFieldIfMissing -List $listName -Name 'QMSKVPTyp' -CreateAction {
    $xml = "<Field Type='Choice' DisplayName='QMSKVPTyp' Name='QMSKVPTyp' Required='TRUE'>" +
           "<CHOICES>" +
           "<CHOICE>Verbesserungsidee</CHOICE>" +         # proaktiv, ISO 10.3
           "<CHOICE>Korrekturmaßnahme</CHOICE>" +         # reaktiv nach Nichtkonf., ISO 10.2
           "<CHOICE>Vorbeugemaßnahme</CHOICE>" +          # präventiv
           "<CHOICE>Kundenreklamation</CHOICE>" +         # ISO 9.1.2 Kundenzufriedenheit
           "<CHOICE>Auditfeststellung</CHOICE>" +         # ISO 9.2 Internes Audit
           "</CHOICES></Field>"
    Add-PnPFieldFromXml -List $listName -FieldXml $xml | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSQuelle' -CreateAction {
    $xml = "<Field Type='Choice' DisplayName='QMSQuelle' Name='QMSQuelle' Required='TRUE'>" +
           "<CHOICES>" +
           "<CHOICE>Internes Audit (ISO 9.2)</CHOICE>" +
           "<CHOICE>Managementbewertung (ISO 9.3)</CHOICE>" +
           "<CHOICE>Kundenfeedback (ISO 9.1.2)</CHOICE>" +
           "<CHOICE>Mitarbeitervorschlag</CHOICE>" +
           "<CHOICE>Nichtkonformität (ISO 10.2)</CHOICE>" +
           "<CHOICE>KPI-Auswertung (ISO 9.1.3)</CHOICE>" +
           "<CHOICE>Externes Audit / Zertifizierung</CHOICE>" +
           "<CHOICE>Sonstige</CHOICE>" +
           "</CHOICES></Field>"
    Add-PnPFieldFromXml -List $listName -FieldXml $xml | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSPrioritaet' -CreateAction {
    $xml = "<Field Type='Choice' DisplayName='QMSPrioritaet' Name='QMSPrioritaet' Required='TRUE'>" +
           "<Default>Mittel</Default><CHOICES>" +
           "<CHOICE>Hoch</CHOICE><CHOICE>Mittel</CHOICE><CHOICE>Niedrig</CHOICE>" +
           "</CHOICES></Field>"
    Add-PnPFieldFromXml -List $listName -FieldXml $xml | Out-Null
}

# ── Zuordnung ─────────────────────────────────────────────────────────────────

Add-QMSFieldIfMissing -List $listName -Name 'QMSBereich' -CreateAction {
    Add-PnPTaxonomyField -List $listName `
        -DisplayName    'QMSBereich' `
        -InternalName   'QMSBereich' `
        -TaxonomyItemId $termSetIds.Bereich `
        -MultiValue:    $false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSProzess' -CreateAction {
    Add-PnPTaxonomyField -List $listName `
        -DisplayName    'QMSProzess' `
        -InternalName   'QMSProzess' `
        -TaxonomyItemId $termSetIds.Prozesse `
        -MultiValue:    $true | Out-Null  # KVP kann mehrere Prozesse betreffen
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSISOKapitel' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSISOKapitel' `
        -InternalName 'QMSISOKapitel' -Type Text -Required:$false | Out-Null
}

# ── PDCA: Plan ────────────────────────────────────────────────────────────────

Add-QMSFieldIfMissing -List $listName -Name 'QMSBeschreibung' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSBeschreibung' `
        -InternalName 'QMSBeschreibung' -Type Note -Required:$true | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSZielzustand' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSZielzustand' `
        -InternalName 'QMSZielzustand' -Type Note -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSUrsache' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSUrsache' `
        -InternalName 'QMSUrsache' -Type Note -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSMassnahme' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSMassnahme' `
        -InternalName 'QMSMassnahme' -Type Note -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSVerantwortlicher' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSVerantwortlicher' `
        -InternalName 'QMSVerantwortlicher' -Type User -Required:$true | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSErfasser' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSErfasser' `
        -InternalName 'QMSErfasser' -Type User -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSZieldatum' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSZieldatum' `
        -InternalName 'QMSZieldatum' -Type DateTime -Required:$false | Out-Null
}

# ── PDCA: Do + Check ──────────────────────────────────────────────────────────

Add-QMSFieldIfMissing -List $listName -Name 'QMSStatus' -CreateAction {
    $xml = "<Field Type='Choice' DisplayName='QMSStatus' Name='QMSStatus' Required='FALSE'>" +
           "<Default>Offen</Default><CHOICES>" +
           "<CHOICE>Offen</CHOICE>" +                     # P: Erfasst, noch keine Massnahme
           "<CHOICE>Massnahme definiert</CHOICE>" +       # P: Massnahme geplant
           "<CHOICE>In Bearbeitung</CHOICE>" +            # D: Umsetzung läuft
           "<CHOICE>Wirksamkeitsprüfung</CHOICE>" +       # C: Massnahme umgesetzt, Prüfung
           "<CHOICE>Abgeschlossen</CHOICE>" +             # A: Wirksam, Standard aktualisiert
           "<CHOICE>Abgelehnt</CHOICE>" +                 # –: Nicht weiterzuverfolgen
           "</CHOICES></Field>"
    Add-PnPFieldFromXml -List $listName -FieldXml $xml | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSFortschritt' -CreateAction {
    $xml = "<Field Type='Number' DisplayName='QMSFortschritt' Name='QMSFortschritt' " +
           "Min='0' Max='100' Required='FALSE'><Default>0</Default></Field>"
    Add-PnPFieldFromXml -List $listName -FieldXml $xml | Out-Null
}

# ── PDCA: Check (Wirksamkeitsprüfung) ─────────────────────────────────────────

Add-QMSFieldIfMissing -List $listName -Name 'QMSWirksamkeitsbeschreibung' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSWirksamkeitsbeschreibung' `
        -InternalName 'QMSWirksamkeitsbeschreibung' -Type Note -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSWirksamkeitsdatum' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSWirksamkeitsdatum' `
        -InternalName 'QMSWirksamkeitsdatum' -Type DateTime -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSWirksamkeitsstatus' -CreateAction {
    $xml = "<Field Type='Choice' DisplayName='QMSWirksamkeitsstatus' Name='QMSWirksamkeitsstatus' Required='FALSE'>" +
           "<Default>Ausstehend</Default><CHOICES>" +
           "<CHOICE>Ausstehend</CHOICE>" +
           "<CHOICE>Wirksam</CHOICE>" +
           "<CHOICE>Nicht wirksam – neue Massnahme erforderlich</CHOICE>" +
           "</CHOICES></Field>"
    Add-PnPFieldFromXml -List $listName -FieldXml $xml | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSWirksamkeitsprueferIn' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSWirksamkeitsprueferIn' `
        -InternalName 'QMSWirksamkeitsprueferIn' -Type User -Required:$false | Out-Null
}

# ── PDCA: Act ────────────────────────────────────────────────────────────────

Add-QMSFieldIfMissing -List $listName -Name 'QMSAbgeschlossenAm' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSAbgeschlossenAm' `
        -InternalName 'QMSAbgeschlossenAm' -Type DateTime -Required:$false | Out-Null
}

Add-QMSFieldIfMissing -List $listName -Name 'QMSVerknuepfteDokumente' -CreateAction {
    Add-PnPField -List $listName -DisplayName 'QMSVerknuepfteDokumente' `
        -InternalName 'QMSVerknuepfteDokumente' -Type Note -Required:$false | Out-Null
}

# ── Ansichten konfigurieren ───────────────────────────────────────────────────

Write-QMSLog "Konfiguriere Ansichten..." -Module 'KVP'

# Standardansicht: Alle offenen KVP
$stdView = Get-PnPView -List $listName -Identity 'Alle Elemente' -ErrorAction SilentlyContinue
if ($stdView) {
    Set-PnPView -List $listName -Identity $stdView.Id -Fields @(
        'Title', 'QMSKVPTyp', 'QMSQuelle', 'QMSPrioritaet',
        'QMSBereich', 'QMSVerantwortlicher', 'QMSZieldatum', 'QMSStatus', 'QMSFortschritt'
    ) | Out-Null
}

# Ansicht: Offene KVP mit Fälligkeit
Add-PnPView -List $listName -Title 'Offene KVP' `
    -Fields @('Title','QMSKVPTyp','QMSPrioritaet','QMSBereich','QMSVerantwortlicher','QMSZieldatum','QMSStatus') `
    -Query '<Where><Or><Eq><FieldRef Name="QMSStatus"/><Value Type="Choice">Offen</Value></Eq><Eq><FieldRef Name="QMSStatus"/><Value Type="Choice">In Bearbeitung</Value></Eq></Or></Where><OrderBy><FieldRef Name="QMSZieldatum"/></OrderBy>' `
    -ErrorAction SilentlyContinue | Out-Null

# Ansicht: Wirksamkeitsprüfung fällig
Add-PnPView -List $listName -Title 'Wirksamkeitsprüfung' `
    -Fields @('Title','QMSKVPTyp','QMSVerantwortlicher','QMSWirksamkeitsdatum','QMSWirksamkeitsstatus','QMSWirksamkeitsprueferIn') `
    -Query '<Where><Eq><FieldRef Name="QMSStatus"/><Value Type="Choice">Wirksamkeitsprüfung</Value></Eq></Where>' `
    -ErrorAction SilentlyContinue | Out-Null

# Ansicht: Statistik-Übersicht (nach Bereich gruppiert)
Add-PnPView -List $listName -Title 'Nach Bereich' `
    -Fields @('Title','QMSKVPTyp','QMSPrioritaet','QMSStatus','QMSVerantwortlicher','QMSZieldatum') `
    -Query '<OrderBy><FieldRef Name="QMSBereich"/></OrderBy>' `
    -RowLimit 500 `
    -ErrorAction SilentlyContinue | Out-Null

# ── Berechtigungen ────────────────────────────────────────────────────────────

Set-PnPListPermission -Identity $listName -Group 'QMS-Leser'                  -AddRole 'Read'         | Out-Null
Set-PnPListPermission -Identity $listName -Group 'QMS-Ersteller'              -AddRole 'Contribute'   | Out-Null
Set-PnPListPermission -Identity $listName -Group 'QMS-Prozessverantwortliche' -AddRole 'Contribute'   | Out-Null
Set-PnPListPermission -Identity $listName -Group 'QMS-Freigeber'              -AddRole 'Contribute'   | Out-Null
Set-PnPListPermission -Identity $listName -Group 'QMS-Administratoren'        -AddRole 'Full Control' | Out-Null

Write-QMSLog "QMS-KVP Liste vollständig erstellt (ISO 9001:2015 Kap. 10.3)." -Module 'KVP'
