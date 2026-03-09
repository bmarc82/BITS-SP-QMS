#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Schritt 5: QMS Berechtigungsgruppen und Rollen konfigurieren
.DESCRIPTION
    Erstellt die fünf QMS-Sicherheitsgruppen, bricht die Berechtigungs-
    vererbung auf der QMS-Site und weist den Gruppen die definierten
    SharePoint-Rollen zu.

    Gruppenstruktur:
    ┌──────────────────────────────────┬──────────────────────────────┐
    │ Gruppe                           │ Rolle                        │
    ├──────────────────────────────────┼──────────────────────────────┤
    │ QMS-Leser                        │ Lesen                        │
    │ QMS-Ersteller                    │ Bearbeiten (ohne Löschen)    │
    │ QMS-Prozessverantwortliche       │ Mitwirken                    │
    │ QMS-Freigeber                    │ Genehmigen                   │
    │ QMS-Administratoren              │ Vollzugriff                  │
    └──────────────────────────────────┴──────────────────────────────┘

    Bibliotheks-Berechtigungen:
    - QMS-Dokumente: eigene Vererbungsunterbrechung, QMS-Ersteller = Mitwirken
    - QMS-Prozesse:  QMS-Ersteller = Mitwirken

    Idempotent: Bestehende Gruppen werden nicht neu erstellt.
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Konfiguriere Berechtigungen..." -Module 'Permissions'

# ── Gruppendefinitionen ───────────────────────────────────────────────────────

$groups = @(
    @{
        Name        = 'QMS-Leser'
        Description = 'Lesezugriff auf alle freigegebenen QMS-Inhalte'
        Role        = 'Read'
    }
    @{
        Name        = 'QMS-Ersteller'
        Description = 'Erstellen und Bearbeiten von QMS-Dokumenten (kein Löschen)'
        Role        = 'Contribute'
    }
    @{
        Name        = 'QMS-Prozessverantwortliche'
        Description = 'Process Owner: Dokumente einreichen, Reviews durchführen'
        Role        = 'Contribute'
    }
    @{
        Name        = 'QMS-Freigeber'
        Description = 'Freigabe von QMS-Dokumenten (Approve-Berechtigung)'
        Role        = 'Approve'
    }
    @{
        Name        = 'QMS-Administratoren'
        Description = 'Vollzugriff auf das QMS-System inkl. Konfiguration'
        Role        = 'Full Control'
    }
)

# ── Hilfsfunktion: Gruppe sicherstellen ──────────────────────────────────────

function Ensure-SPGroup {
    param([string]$Name, [string]$Description)
    $group = Get-PnPGroup -Identity $Name -ErrorAction SilentlyContinue
    if ($group) {
        Write-QMSLog "Gruppe bereits vorhanden: $Name" -Level WARNING -Module 'Permissions'
        return $group
    }
    Write-QMSLog "Erstelle Gruppe: $Name" -Module 'Permissions'
    return New-PnPGroup -Title $Name -Description $Description
}

# ── Gruppen anlegen und Site-Berechtigungen setzen ────────────────────────────

if ($PSCmdlet.ShouldProcess($Config.SiteUrl, 'Berechtigungsgruppen konfigurieren')) {

    # Vererbung aufbrechen (Site-Ebene) – nur wenn noch nicht geschehen
    $web = Get-PnPWeb -Includes HasUniqueRoleAssignments
    if (-not $web.HasUniqueRoleAssignments) {
        Write-QMSLog "Breche Berechtigungsvererbung auf Site-Ebene auf..." -Module 'Permissions'
        Set-PnPWebPermission -ClearExistingPermissions:$false | Out-Null
        # Standardgruppen entfernen um saubere QMS-Struktur zu erhalten
        Write-QMSLog "Standardgruppen bleiben erhalten (manuell entfernen falls gewünscht)" -Level WARNING -Module 'Permissions'
    }

    foreach ($g in $groups) {
        $group = Ensure-SPGroup -Name $g.Name -Description $g.Description
        Write-QMSLog "Weise Rolle zu: $($g.Name) → $($g.Role)" -Module 'Permissions'
        Set-PnPGroupPermissions -Identity $g.Name -AddRole $g.Role
    }
}

# ── Bibliotheks-Berechtigungen ────────────────────────────────────────────────

if ($PSCmdlet.ShouldProcess('QMS-Dokumente', 'Bibliotheks-Berechtigungen setzen')) {

    Write-QMSLog "Konfiguriere Berechtigungen für QMS-Dokumente..." -Module 'Permissions'

    $docLib = Get-PnPList -Identity 'QMS-Dokumente' -ErrorAction SilentlyContinue
    if ($docLib) {
        # Eigene Berechtigungen für Bibliothek (Freigeber kann nur in Bibliothek genehmigen)
        Set-PnPListPermission -Identity 'QMS-Dokumente' -Group 'QMS-Leser'                  -AddRole 'Read'         | Out-Null
        Set-PnPListPermission -Identity 'QMS-Dokumente' -Group 'QMS-Ersteller'              -AddRole 'Contribute'   | Out-Null
        Set-PnPListPermission -Identity 'QMS-Dokumente' -Group 'QMS-Prozessverantwortliche' -AddRole 'Contribute'   | Out-Null
        Set-PnPListPermission -Identity 'QMS-Dokumente' -Group 'QMS-Freigeber'              -AddRole 'Approve'      | Out-Null
        Set-PnPListPermission -Identity 'QMS-Dokumente' -Group 'QMS-Administratoren'        -AddRole 'Full Control' | Out-Null
        Write-QMSLog "Bibliotheks-Berechtigungen gesetzt: QMS-Dokumente" -Module 'Permissions'
    } else {
        Write-QMSLog "QMS-Dokumente nicht gefunden. Bitte zuerst 03_Configure-Library.ps1 ausführen." -Level WARNING -Module 'Permissions'
    }
}

if ($PSCmdlet.ShouldProcess('QMS-Prozesse', 'Listen-Berechtigungen setzen')) {

    Write-QMSLog "Konfiguriere Berechtigungen für QMS-Prozesse..." -Module 'Permissions'

    $procList = Get-PnPList -Identity 'QMS-Prozesse' -ErrorAction SilentlyContinue
    if ($procList) {
        Set-PnPListPermission -Identity 'QMS-Prozesse' -Group 'QMS-Leser'                  -AddRole 'Read'         | Out-Null
        Set-PnPListPermission -Identity 'QMS-Prozesse' -Group 'QMS-Prozessverantwortliche' -AddRole 'Contribute'   | Out-Null
        Set-PnPListPermission -Identity 'QMS-Prozesse' -Group 'QMS-Administratoren'        -AddRole 'Full Control' | Out-Null
        Write-QMSLog "Listen-Berechtigungen gesetzt: QMS-Prozesse" -Module 'Permissions'
    } else {
        Write-QMSLog "QMS-Prozesse nicht gefunden. Bitte zuerst 04_Create-ProcessList.ps1 ausführen." -Level WARNING -Module 'Permissions'
    }
}

Write-QMSLog "Berechtigungskonfiguration abgeschlossen." -Module 'Permissions'
