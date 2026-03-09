#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Schritt 2b: QMS Term Store Struktur anlegen
.DESCRIPTION
    Erstellt die Managed Metadata Termgruppe "QMS" mit vordefinierten
    Term Sets für Prozessart, Bereich und dem dynamischen Term Set Prozesse.

    Reihenfolge: Nach 02_Deploy-ContentTypes.ps1, vor 03_Configure-Library.ps1

    Term-Struktur:
    QMS (Gruppe)
    ├── Prozessart      [vordefiniert, statisch]
    │   ├── Führungsprozess
    │   ├── Kernprozess
    │   └── Supportprozess
    ├── Bereich         [vordefiniert, erweiterbar]
    │   ├── Management
    │   ├── Qualität
    │   ├── Produktion
    │   ├── Einkauf
    │   ├── Vertrieb
    │   ├── HR / Personal
    │   ├── IT
    │   ├── Finanzen
    │   └── Logistik
    └── Prozesse        [dynamisch – wird durch Power Automate befüllt]

.OUTPUTS
    Hashtable mit Term Set IDs (wird in 03_Configure-Library.ps1 verwendet)
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TermGroupName = 'QMS',
    [int]$Lcid = 1031  # Deutsch
)

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Erstelle Term Store Struktur..." -Module 'TermStore'

# ── Vordefinierte Terms ────────────────────────────────────────────────────────

$predefinedTerms = @{
    'Prozessart' = @(
        'Führungsprozess'
        'Kernprozess'
        'Supportprozess'
    )
    'Bereich' = @(
        'Management'
        'Qualität'
        'Produktion'
        'Einkauf'
        'Vertrieb'
        'HR / Personal'
        'IT'
        'Finanzen'
        'Logistik'
    )
    'Prozesse' = @()  # Wird dynamisch durch Power Automate befüllt
}

# ── Hilfsfunktion: Term Set sicherstellen ─────────────────────────────────────

function Ensure-QMSTermSet {
    param(
        [string]$GroupName,
        [string]$TermSetName,
        [string[]]$Terms,
        [int]$Lcid
    )

    $termSet = Get-PnPTermSet -Identity $TermSetName -TermGroup $GroupName -ErrorAction SilentlyContinue
    if (-not $termSet) {
        Write-QMSLog "Erstelle Term Set: $TermSetName" -Module 'TermStore'
        $termSet = New-PnPTermSet -Name $TermSetName -TermGroup $GroupName -Lcid $Lcid
    } else {
        Write-QMSLog "Term Set bereits vorhanden: $TermSetName" -Level WARNING -Module 'TermStore'
    }

    foreach ($termName in $Terms) {
        $existing = Get-PnPTerm -Identity $termName -TermSet $TermSetName -TermGroup $GroupName -ErrorAction SilentlyContinue
        if (-not $existing) {
            Write-QMSLog "  Erstelle Term: $termName" -Module 'TermStore'
            New-PnPTerm -Name $termName -TermSet $TermSetName -TermGroup $GroupName -Lcid $Lcid | Out-Null
        } else {
            Write-QMSLog "  Term bereits vorhanden: $termName" -Level WARNING -Module 'TermStore'
        }
    }

    return $termSet
}

# ── Term Gruppe sicherstellen ─────────────────────────────────────────────────

if ($PSCmdlet.ShouldProcess($TermGroupName, 'Term Gruppe erstellen')) {

    $termGroup = Get-PnPTermGroup -Identity $TermGroupName -ErrorAction SilentlyContinue
    if (-not $termGroup) {
        Write-QMSLog "Erstelle Term Gruppe: $TermGroupName" -Module 'TermStore'
        New-PnPTermGroup -Name $TermGroupName | Out-Null
    } else {
        Write-QMSLog "Term Gruppe bereits vorhanden: $TermGroupName" -Level WARNING -Module 'TermStore'
    }

    # ── Term Sets anlegen ─────────────────────────────────────────────────────

    $termSetIds = @{}

    foreach ($setName in $predefinedTerms.Keys) {
        $termSet = Ensure-QMSTermSet `
            -GroupName  $TermGroupName `
            -TermSetName $setName `
            -Terms      $predefinedTerms[$setName] `
            -Lcid       $Lcid

        $termSetIds[$setName] = $termSet.Id.ToString()
        Write-QMSLog "Term Set bereit: $setName (ID: $($termSet.Id))" -Module 'TermStore'
    }

    # ── Term Set IDs in Konfigurationsdatei speichern ─────────────────────────
    # Wird von 03_Configure-Library.ps1 und 04_Create-ProcessList.ps1 gelesen

    $idsPath = "$PSScriptRoot/../config/termstore-ids.json"
    $termSetIds | ConvertTo-Json | Set-Content -Path $idsPath -Encoding UTF8
    Write-QMSLog "Term Set IDs gespeichert: $idsPath" -Module 'TermStore'
}

Write-QMSLog "Term Store Struktur vollständig angelegt." -Module 'TermStore'
