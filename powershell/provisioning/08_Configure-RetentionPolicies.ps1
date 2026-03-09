#Requires -Version 7.0
#Requires -Modules ExchangeOnlineManagement, QMS.Core
<#
.SYNOPSIS
    Schritt 8: Microsoft Purview Aufbewahrungsrichtlinien konfigurieren
.DESCRIPTION
    Implementiert Aufbewahrungsfristen gemäss ISO 9001:2015 Kap. 7.5.3
    (Lenkung dokumentierter Information) und gesetzlichen Anforderungen (CH/EU).

    Aufbewahrungsfristen:
    ┌─────────────────────────────────┬───────────┬─────────────────────────────────────┐
    │ Dokumenttyp                     │ Frist     │ Rechtsgrundlage                     │
    ├─────────────────────────────────┼───────────┼─────────────────────────────────────┤
    │ Freigegeben (aktuell)           │ Unbegrenzt│ ISO 9001:2015 7.5.3 (verfügbar)     │
    │ Archiviert (Vorgängerversionen) │ 10 Jahre  │ ISO 9001 + OR Art. 958f (CH)        │
    │ Nichtkonformitäten / KVP        │ 5 Jahre   │ ISO 9001:2015 10.2.2 (e)            │
    │ Audit-Berichte                  │ 5 Jahre   │ ISO 9001:2015 9.2 Nachweis          │
    │ Freigabe-Entscheidungen         │ 10 Jahre  │ Audit-Trail, OR Art. 958f           │
    └─────────────────────────────────┴───────────┴─────────────────────────────────────┘

    Hinweis:
    - Dokumente werden NIEMALS automatisch gelöscht – nur archiviert
    - Aufbewahrungsrichtlinien = Mindestaufbewahrung (Löschsperre)
    - Aktive Freigaben sind von der Archivierungsfrist ausgenommen

    Voraussetzungen:
    - Exchange Online Management Modul (für Purview-Cmdlets)
    - Microsoft Purview / Compliance Center Lizenz (E3+)
    - Global Admin oder Compliance Admin Rolle
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
Write-QMSLog "Konfiguriere Purview Aufbewahrungsrichtlinien (ISO 9001:2015 Kap. 7.5.3)..." -Module 'Retention'

# ── Verbindung zu Security & Compliance Center ────────────────────────────────

try {
    Connect-IPPSSession -UserPrincipalName $Config.AdminEmail -ErrorAction Stop
    Write-QMSLog "Verbunden mit Security & Compliance Center" -Module 'Retention'
} catch {
    Write-QMSLog "Verbindung zu S&CC fehlgeschlagen: $_" -Level ERROR -Module 'Retention'
    exit 1
}

# ── Hilfsfunktion ─────────────────────────────────────────────────────────────

function New-QMSRetentionLabelIfMissing {
    param(
        [string]$Name,
        [string]$Comment,
        [int]$RetentionDurationDays,
        [string]$RetentionAction = 'Keep'  # Keep = Mindestaufbewahrung (kein Auto-Delete)
    )
    $existing = Get-ComplianceTag -Identity $Name -ErrorAction SilentlyContinue
    if ($existing) {
        Write-QMSLog "Aufbewahrungslabel bereits vorhanden: $Name" -Level WARNING -Module 'Retention'
        return $existing
    }
    if ($PSCmdlet.ShouldProcess($Name, 'Compliance-Label erstellen')) {
        $label = New-ComplianceTag -Name $Name `
            -Comment $Comment `
            -RetentionEnabled $true `
            -RetentionDuration $RetentionDurationDays `
            -RetentionAction $RetentionAction `
            -IsRecordLabel $false
        Write-QMSLog "Aufbewahrungslabel erstellt: $Name ($RetentionDurationDays Tage)" -Module 'Retention'
        return $label
    }
}

# ── Aufbewahrungslabels erstellen ─────────────────────────────────────────────

Write-QMSLog "Erstelle Aufbewahrungslabels..." -Module 'Retention'

# QMS-Archiv (10 Jahre) – für archivierte Vorgängerversionen und Freigabe-Entscheidungen
New-QMSRetentionLabelIfMissing `
    -Name         'QMS-Archiv-10J' `
    -Comment      'ISO 9001:2015 7.5.3 + OR Art. 958f: Archivierte QMS-Dokumente, Freigabe-Entscheidungen. 10 Jahre Mindestaufbewahrung.' `
    -RetentionDurationDays (10 * 365)

# QMS-KVP-Nachweis (5 Jahre) – KVP-Einträge, Korrekturmassnahmen, Audit-Berichte
New-QMSRetentionLabelIfMissing `
    -Name         'QMS-KVP-Nachweis-5J' `
    -Comment      'ISO 9001:2015 10.2.2(e): Nichtkonformitäten, Korrekturmassnahmen, Audit-Berichte. 5 Jahre Mindestaufbewahrung.' `
    -RetentionDurationDays (5 * 365)

# QMS-Aktiv (kein Ablauf) – aktive freigegebene Dokumente
New-QMSRetentionLabelIfMissing `
    -Name         'QMS-Aktiv-Unbegrenzt' `
    -Comment      'ISO 9001:2015 7.5.3: Aktiv freigegebene QMS-Dokumente. Keine automatische Archivierung.' `
    -RetentionDurationDays 0 `  # 0 = kein Ablauf
    -RetentionAction 'Keep'

Write-QMSLog "Labels erstellt." -Module 'Retention'

# ── Aufbewahrungsrichtlinien (Policies) erstellen ─────────────────────────────

Write-QMSLog "Erstelle Aufbewahrungsrichtlinien..." -Module 'Retention'

# Policy: QMS-Dokumente Archiv
$archivPolicy = Get-RetentionCompliancePolicy -Identity 'QMS-Dokumente-Archiv-Policy' -ErrorAction SilentlyContinue
if (-not $archivPolicy) {
    if ($PSCmdlet.ShouldProcess('QMS-Dokumente-Archiv-Policy', 'Retention Policy erstellen')) {
        New-RetentionCompliancePolicy `
            -Name        'QMS-Dokumente-Archiv-Policy' `
            -Comment     'Archivierte QMS-Dokumente: 10 Jahre Mindestaufbewahrung (ISO 9001 + OR Art. 958f)' `
            -SharePointLocation $Config.SiteUrl `
            -Enabled     $true
        Write-QMSLog "Retention Policy erstellt: QMS-Dokumente-Archiv-Policy" -Module 'Retention'
    }
} else {
    Write-QMSLog "Policy bereits vorhanden: QMS-Dokumente-Archiv-Policy" -Level WARNING -Module 'Retention'
}

# Policy-Regel: Label-Zuweisung für archivierte Versionen
$archivRule = Get-RetentionCompliancePolicyRule -Policy 'QMS-Dokumente-Archiv-Policy' -ErrorAction SilentlyContinue
if (-not $archivRule) {
    if ($PSCmdlet.ShouldProcess('QMS-Archiv-Regel', 'Retention Rule erstellen')) {
        New-RetentionCompliancePolicyRule `
            -Policy             'QMS-Dokumente-Archiv-Policy' `
            -Name               'QMS-Archiv-10J-Regel' `
            -PublishComplianceTag 'QMS-Archiv-10J' `
            -Workload           SharePoint
        Write-QMSLog "Retention Rule erstellt: QMS-Archiv-10J-Regel" -Module 'Retention'
    }
}

# Policy: KVP und Compliance-Nachweise
$kvpPolicy = Get-RetentionCompliancePolicy -Identity 'QMS-KVP-Nachweis-Policy' -ErrorAction SilentlyContinue
if (-not $kvpPolicy) {
    if ($PSCmdlet.ShouldProcess('QMS-KVP-Nachweis-Policy', 'Retention Policy erstellen')) {
        New-RetentionCompliancePolicy `
            -Name        'QMS-KVP-Nachweis-Policy' `
            -Comment     'KVP, Nichtkonformitäten, Audit-Berichte: 5 Jahre Mindestaufbewahrung (ISO 9001:2015 10.2)' `
            -SharePointLocation $Config.SiteUrl `
            -Enabled     $true
        Write-QMSLog "Retention Policy erstellt: QMS-KVP-Nachweis-Policy" -Module 'Retention'
    }
}

# ── Zusammenfassung ───────────────────────────────────────────────────────────

Write-QMSLog @"
Aufbewahrungsrichtlinien konfiguriert:

  QMS-Aktiv-Unbegrenzt       → Aktive freigegebene Dokumente (kein Ablauf)
  QMS-Archiv-10J             → Archivierte Versionen, Freigabe-Audit-Trail
  QMS-KVP-Nachweis-5J        → KVP-Einträge, Audit-Berichte

Wichtig:
  - Labels manuell oder via SharePoint Auto-Apply-Policy zuweisen
  - Auto-Apply: https://compliance.microsoft.com → Information Governance → Auto-apply
  - Empfohlene Auto-Apply-Bedingung für QMS-Archiv-10J:
    SharePoint-Metadaten: QMSStatus = 'Archiviert'
  - Dokumente werden NIEMALS automatisch gelöscht (RetentionAction=Keep)
"@ -Module 'Retention'

Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
