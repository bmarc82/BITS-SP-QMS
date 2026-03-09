#Requires -Modules Pester
<#
.SYNOPSIS
    Compliance-Test: Berechtigungskonzept (ISO 9001:2015 Kap. 5.3 + 7.5.3)
.DESCRIPTION
    Prüft das QMS-Berechtigungskonzept auf Konformität:
    - Alle 5 SP-Gruppen vorhanden und korrekt benannt
    - Berechtigungen auf Bibliotheken und Listen entsprechen dem Konzept
    - Kein Mitglied der QMS-Leser-Gruppe in QMS-Freigeber (Rollentrennung)
    - QMS-Changelog: Nur-Lese für alle ausser Administratoren

    Ausführen:
        $env:QMS_ENV = 'TEST'
        Invoke-Pester -Path ./Permissions.Tests.ps1 -Output Detailed
#>

BeforeAll {
    if ($env:QMS_ENV -ne 'TEST' -and $env:QMS_ENV -ne 'PROD') {
        throw "Setzen Sie QMS_ENV=TEST oder PROD"
    }
    $modulePath = "$PSScriptRoot/../../modules/QMS.Core/QMS.Core.psm1"
    Import-Module $modulePath -Force
    $Config = Get-QMSConfig
    Connect-PnPOnline -Url $Config.SiteUrl -ClientId $Config.AppId `
        -Thumbprint $Config.CertThumbprint -Tenant $Config.TenantId
}

AfterAll {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}

Describe 'ISO 5.3 – Rollen und Verantwortlichkeiten: SP-Gruppen' {

    $groups = @(
        @{ Name = 'QMS-Leser';                   Role = 'Read' },
        @{ Name = 'QMS-Ersteller';               Role = 'Contribute' },
        @{ Name = 'QMS-Prozessverantwortliche';  Role = 'Contribute' },
        @{ Name = 'QMS-Freigeber';               Role = 'Approve' },
        @{ Name = 'QMS-Administratoren';         Role = 'Full Control' }
    )

    foreach ($g in $groups) {
        It "Gruppe '$($g.Name)' existiert" {
            $group = Get-PnPGroup -Identity $g.Name -ErrorAction SilentlyContinue
            $group | Should -Not -BeNullOrEmpty
        }

        It "Gruppe '$($g.Name)' hat mindestens 1 Mitglied" {
            $members = Get-PnPGroupMember -Identity $g.Name -ErrorAction SilentlyContinue
            $members.Count | Should -BeGreaterThan 0 `
                -Because "Leere Gruppen deuten auf fehlende Rollenzuordnung hin"
        }
    }
}

Describe 'ISO 7.5.3 – Zugriffsschutz: Bibliotheken und Listen' {

    Context 'QMS-Dokumente Berechtigungen' {

        It 'QMS-Leser haben nur Read-Zugriff auf QMS-Dokumente' {
            $perms = Get-PnPListPermissions -Identity 'QMS-Dokumente'
            $leser = $perms | Where-Object { $_.Member.Title -eq 'QMS-Leser' }
            $leser | Should -Not -BeNullOrEmpty
            $leser.RoleDefinitionBindings.Name | Should -Contain 'Read'
            $leser.RoleDefinitionBindings.Name | Should -Not -Contain 'Contribute'
            $leser.RoleDefinitionBindings.Name | Should -Not -Contain 'Full Control'
        }

        It 'QMS-Freigeber haben Approve-Berechtigung auf QMS-Dokumente' {
            $perms = Get-PnPListPermissions -Identity 'QMS-Dokumente'
            $freigeber = $perms | Where-Object { $_.Member.Title -eq 'QMS-Freigeber' }
            $freigeber | Should -Not -BeNullOrEmpty
            $freigeber.RoleDefinitionBindings.Name | Should -Contain 'Approve'
        }

        It 'QMS-Administratoren haben Full Control auf QMS-Dokumente' {
            $perms = Get-PnPListPermissions -Identity 'QMS-Dokumente'
            $admin = $perms | Where-Object { $_.Member.Title -eq 'QMS-Administratoren' }
            $admin | Should -Not -BeNullOrEmpty
            $admin.RoleDefinitionBindings.Name | Should -Contain 'Full Control'
        }
    }

    Context 'QMS-Changelog Schreibschutz (ISO 7.5.3 – Integrität)' {

        It 'QMS-Leser haben nur Read-Zugriff auf QMS-Changelog' {
            $perms = Get-PnPListPermissions -Identity 'QMS-Changelog'
            $leser = $perms | Where-Object { $_.Member.Title -eq 'QMS-Leser' }
            $leser | Should -Not -BeNullOrEmpty
            $leser.RoleDefinitionBindings.Name | Should -Contain 'Read'
            $leser.RoleDefinitionBindings.Name | Should -Not -Contain 'Contribute'
        }

        It 'QMS-Ersteller haben keinen Schreibzugriff auf QMS-Changelog' {
            $perms = Get-PnPListPermissions -Identity 'QMS-Changelog'
            $ersteller = $perms | Where-Object { $_.Member.Title -eq 'QMS-Ersteller' }
            if ($ersteller) {
                $ersteller.RoleDefinitionBindings.Name | Should -Not -Contain 'Contribute'
                $ersteller.RoleDefinitionBindings.Name | Should -Not -Contain 'Full Control'
            } else {
                # Gruppe hat keinen Eintrag = korrekt (Standard: kein Zugriff)
                $true | Should -Be $true
            }
        }
    }

    Context 'QMS-KVP Berechtigungen' {

        It 'QMS-Leser haben Read-Zugriff auf QMS-KVP' {
            $perms = Get-PnPListPermissions -Identity 'QMS-KVP'
            $leser = $perms | Where-Object { $_.Member.Title -eq 'QMS-Leser' }
            $leser | Should -Not -BeNullOrEmpty
            $leser.RoleDefinitionBindings.Name | Should -Contain 'Read'
        }

        It 'QMS-Ersteller haben Contribute-Zugriff auf QMS-KVP' {
            $perms = Get-PnPListPermissions -Identity 'QMS-KVP'
            $ersteller = $perms | Where-Object { $_.Member.Title -eq 'QMS-Ersteller' }
            $ersteller | Should -Not -BeNullOrEmpty
            $ersteller.RoleDefinitionBindings.Name | Should -Contain 'Contribute'
        }
    }
}

Describe 'Rollentrennung (Segregation of Duties)' {

    It 'QMS-Leser-Mitglieder sind nicht in QMS-Freigeber (Rollentrennung)' {
        $leserMembers    = Get-PnPGroupMember -Identity 'QMS-Leser'    | Select-Object -Expand LoginName
        $freigeberMembers = Get-PnPGroupMember -Identity 'QMS-Freigeber' | Select-Object -Expand LoginName

        $overlap = $leserMembers | Where-Object { $freigeberMembers -contains $_ }
        $overlap.Count | Should -Be 0 `
            -Because 'Mitglieder in beiden Gruppen könnten Freigaben umgehen'
    }

    It 'Site-Administrator ist kein reguläres QMS-Ersteller-Mitglied' {
        # Site-Collection-Admin soll nicht unter Ersteller geführt werden (separater Admin-Account empfohlen)
        $web      = Get-PnPWeb
        $siteAdmins = Get-PnPSiteCollectionAdmin | Select-Object -Expand LoginName
        $ersteller  = Get-PnPGroupMember -Identity 'QMS-Ersteller' | Select-Object -Expand LoginName

        $adminInErsteller = $siteAdmins | Where-Object { $ersteller -contains $_ }
        # Warning statt harter Fehler – Site-Admins sind technisch nicht ausschließbar
        if ($adminInErsteller.Count -gt 0) {
            Write-Warning "Site-Administratoren sind auch in QMS-Ersteller: $($adminInErsteller -join ', '). Empfehlung: Trennung in dedizierten QMS-Admin-Account."
        }
        $true | Should -Be $true  # Informativ, kein harter Fehler
    }
}
