#Requires -Modules Pester
<#
.SYNOPSIS
    Pester Integrationstests – QMS Provisioning Soll-Zustand
.DESCRIPTION
    Prüft nach Ausführung der Provisioning-Scripts, ob die SharePoint-Infrastruktur
    den erwarteten Zustand hat. Benötigt eine aktive Verbindung zum DEV-Tenant.

    Voraussetzung:
    - QMS_ENV=TEST gesetzt
    - Verbindung via Connect-PnPOnline bereits hergestellt
    - Alle Scripts 01–05 wurden ausgeführt

    Ausführen:
        $env:QMS_ENV = 'TEST'
        Invoke-Pester -Path ./Provisioning.Tests.ps1 -Output Detailed
#>

BeforeAll {
    if ($env:QMS_ENV -ne 'TEST') {
        throw "Diese Tests nur gegen TEST-Tenant ausführen. Setzen Sie: `$env:QMS_ENV = 'TEST'"
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

# ── Site ──────────────────────────────────────────────────────────────────────

Describe '01 – QMS Site' {

    It 'QMS Communication Site ist erreichbar' {
        $web = Get-PnPWeb
        $web | Should -Not -BeNullOrEmpty
    }

    It 'Site-Titel enthält "Qualität" oder "QMS"' {
        $web = Get-PnPWeb
        $web.Title | Should -Match '(Qualität|QMS)'
    }
}

# ── Inhaltstypen ──────────────────────────────────────────────────────────────

Describe '02 – Inhaltstypen' {

    $expectedCT = @(
        'QMS-Prozessbeschreibung'
        'QMS-Arbeitsanweisung'
        'QMS-Formular'
        'QMS-Nachweis'
    )

    foreach ($ct in $expectedCT) {
        It "Inhaltstyp vorhanden: $ct" {
            $result = Get-PnPContentType -Identity $ct -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

# ── Term Store ────────────────────────────────────────────────────────────────

Describe '02b – Term Store' {

    It 'Term Gruppe "QMS" existiert' {
        $group = Get-PnPTermGroup -Identity 'QMS' -ErrorAction SilentlyContinue
        $group | Should -Not -BeNullOrEmpty
    }

    $expectedTermSets = @('Prozessart', 'Bereich', 'Prozesse')
    foreach ($ts in $expectedTermSets) {
        It "Term Set vorhanden: $ts" {
            $termSet = Get-PnPTermSet -Identity $ts -TermGroup 'QMS' -ErrorAction SilentlyContinue
            $termSet | Should -Not -BeNullOrEmpty
        }
    }

    $expectedProzessart = @('Führungsprozess', 'Kernprozess', 'Supportprozess')
    foreach ($term in $expectedProzessart) {
        It "Term vorhanden in Prozessart: $term" {
            $t = Get-PnPTerm -Identity $term -TermSet 'Prozessart' -TermGroup 'QMS' -ErrorAction SilentlyContinue
            $t | Should -Not -BeNullOrEmpty
        }
    }

    It 'Term Set "Bereich" hat mindestens 5 vordefinierte Terms' {
        $terms = Get-PnPTerm -TermSet 'Bereich' -TermGroup 'QMS'
        $terms.Count | Should -BeGreaterOrEqual 5
    }
}

# ── Dokumentenbibliothek ──────────────────────────────────────────────────────

Describe '03 – Dokumentenbibliothek' {

    It 'Bibliothek "QMS-Dokumente" existiert' {
        $list = Get-PnPList -Identity 'QMS-Dokumente' -ErrorAction SilentlyContinue
        $list | Should -Not -BeNullOrEmpty
    }

    It 'Versionierung ist aktiviert' {
        $list = Get-PnPList -Identity 'QMS-Dokumente'
        $list.EnableVersioning | Should -Be $true
    }

    $expectedFields = @(
        'QMSStatus'
        'QMSProzessverantwortlicher'
        'QMSGueltigAb'
        'QMSNaechstesPruefDatum'
        'QMSISOKapitel'
        'QMSProzessart'
        'QMSBereich'
        'QMSProzess'
    )

    foreach ($field in $expectedFields) {
        It "Spalte vorhanden: $field" {
            $f = Get-PnPField -List 'QMS-Dokumente' -Identity $field -ErrorAction SilentlyContinue
            $f | Should -Not -BeNullOrEmpty
        }
    }

    It 'QMSProzessart ist ein Managed Metadata Feld' {
        $f = Get-PnPField -List 'QMS-Dokumente' -Identity 'QMSProzessart'
        $f.TypeAsString | Should -Be 'TaxonomyFieldType'
    }

    It 'QMSBereich ist ein Managed Metadata Feld' {
        $f = Get-PnPField -List 'QMS-Dokumente' -Identity 'QMSBereich'
        $f.TypeAsString | Should -Be 'TaxonomyFieldType'
    }

    It 'QMSStatus hat Auswahlwert "Freigegeben"' {
        $f = Get-PnPField -List 'QMS-Dokumente' -Identity 'QMSStatus' -Includes Choices
        $f.Choices | Should -Contain 'Freigegeben'
    }
}

# ── Prozesslandkarte ──────────────────────────────────────────────────────────

Describe '04 – Prozesslandkarte' {

    It 'Liste "QMS-Prozesse" existiert' {
        $list = Get-PnPList -Identity 'QMS-Prozesse' -ErrorAction SilentlyContinue
        $list | Should -Not -BeNullOrEmpty
    }

    $expectedFields = @(
        'QMSProzessverantwortlicher'
        'QMSProzessbeschreibung'
        'QMSISOKapitel'
        'QMSStatus'
        'QMSProzessart'
        'QMSBereich'
    )

    foreach ($field in $expectedFields) {
        It "Spalte vorhanden in QMS-Prozesse: $field" {
            $f = Get-PnPField -List 'QMS-Prozesse' -Identity $field -ErrorAction SilentlyContinue
            $f | Should -Not -BeNullOrEmpty
        }
    }
}

# ── Berechtigungen ────────────────────────────────────────────────────────────

Describe '05 – Berechtigungsgruppen' {

    $expectedGroups = @(
        'QMS-Leser'
        'QMS-Ersteller'
        'QMS-Prozessverantwortliche'
        'QMS-Freigeber'
        'QMS-Administratoren'
    )

    foreach ($group in $expectedGroups) {
        It "Gruppe vorhanden: $group" {
            $g = Get-PnPGroup -Identity $group -ErrorAction SilentlyContinue
            $g | Should -Not -BeNullOrEmpty
        }
    }
}
