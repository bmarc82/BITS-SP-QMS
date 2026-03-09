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

    It 'QMSVersionTyp Feld vorhanden' {
        $f = Get-PnPField -List 'QMS-Dokumente' -Identity 'QMSVersionTyp' -ErrorAction SilentlyContinue
        $f | Should -Not -BeNullOrEmpty
    }

    It 'QMSVersionTyp hat Werte Hauptversion und Nebenversion' {
        $f = Get-PnPField -List 'QMS-Dokumente' -Identity 'QMSVersionTyp' -Includes Choices
        $f.Choices | Should -Contain 'Hauptversion'
        $f.Choices | Should -Contain 'Nebenversion'
    }
}

Describe '03b – Versioning und Content Approval' {

    It 'Haupt- und Nebenversionen aktiviert' {
        $list = Get-PnPList -Identity 'QMS-Dokumente' -Includes EnableVersioning, EnableMinorVersions
        $list.EnableVersioning    | Should -Be $true
        $list.EnableMinorVersions | Should -Be $true
    }

    It 'Content Approval (Moderation) aktiviert' {
        $list = Get-PnPList -Identity 'QMS-Dokumente' -Includes EnableModeration
        $list.EnableModeration | Should -Be $true
    }

    It 'Entwürfe nur sichtbar für Freigeber (DraftVersionVisibility = 2)' {
        $list = Get-PnPList -Identity 'QMS-Dokumente' -Includes DraftVersionVisibility
        [int]$list.DraftVersionVisibility | Should -Be 2
    }

    It 'Kein Auschecken erforderlich' {
        $list = Get-PnPList -Identity 'QMS-Dokumente' -Includes ForceCheckout
        $list.ForceCheckout | Should -Be $false
    }

    It 'Hauptversionen aufbewahrt (MajorVersionLimit >= 10)' {
        $list = Get-PnPList -Identity 'QMS-Dokumente' -Includes MajorVersionLimit
        $list.MajorVersionLimit | Should -BeGreaterOrEqual 10
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

# ── Changelog ─────────────────────────────────────────────────────────────────

Describe '04b – Changelog' {

    It 'Liste "QMS-Changelog" existiert' {
        $list = Get-PnPList -Identity 'QMS-Changelog' -ErrorAction SilentlyContinue
        $list | Should -Not -BeNullOrEmpty
    }

    $expectedFields = @(
        'QMSVersion'
        'QMSAenderungsart'
        'QMSAenderungsbeschreibung'
        'QMSDokumentId'
        'QMSDokumentUrl'
        'QMSErsteller'
        'QMSFreigeber'
        'QMSFreigegebenAm'
        'QMSFreigabeKommentar'
        'QMSProzess'
        'QMSBereich'
    )

    foreach ($field in $expectedFields) {
        It "Spalte vorhanden in QMS-Changelog: $field" {
            $f = Get-PnPField -List 'QMS-Changelog' -Identity $field -ErrorAction SilentlyContinue
            $f | Should -Not -BeNullOrEmpty
        }
    }

    It 'QMSAenderungsart enthält "Inhaltliche Änderung"' {
        $f = Get-PnPField -List 'QMS-Changelog' -Identity 'QMSAenderungsart' -Includes Choices
        $f.Choices | Should -Contain 'Inhaltliche Änderung'
    }

    It 'QMS-Changelog nur lesbar für QMS-Leser (kein Schreibzugriff)' {
        $perms = Get-PnPListPermissions -Identity 'QMS-Changelog'
        $leserPerm = $perms | Where-Object { $_.Member.Title -eq 'QMS-Leser' }
        $leserPerm | Should -Not -BeNullOrEmpty
        $leserPerm.RoleDefinitionBindings.Name | Should -Contain 'Read'
        $leserPerm.RoleDefinitionBindings.Name | Should -Not -Contain 'Full Control'
    }

    It 'QMS-Dokumente hat Änderungsfeld QMSVersion' {
        $f = Get-PnPField -List 'QMS-Dokumente' -Identity 'QMSVersion' -ErrorAction SilentlyContinue
        $f | Should -Not -BeNullOrEmpty
    }

    It 'QMS-Dokumente hat Änderungsfeld QMSAenderungsbeschreibung' {
        $f = Get-PnPField -List 'QMS-Dokumente' -Identity 'QMSAenderungsbeschreibung' -ErrorAction SilentlyContinue
        $f | Should -Not -BeNullOrEmpty
    }
}

# ── KVP (Kontinuierlicher Verbesserungsprozess) ────────────────────────────────

Describe '04c – KVP-Liste (ISO 9001:2015 Kap. 10.3)' {

    It 'Liste "QMS-KVP" existiert' {
        $list = Get-PnPList -Identity 'QMS-KVP' -ErrorAction SilentlyContinue
        $list | Should -Not -BeNullOrEmpty
    }

    It 'Versionierung ist aktiviert' {
        $list = Get-PnPList -Identity 'QMS-KVP'
        $list.EnableVersioning | Should -Be $true
    }

    # Klassifizierung
    $classificationFields = @('QMSKVPTyp', 'QMSQuelle', 'QMSPrioritaet')
    foreach ($field in $classificationFields) {
        It "Klassifizierungsspalte vorhanden: $field" {
            $f = Get-PnPField -List 'QMS-KVP' -Identity $field -ErrorAction SilentlyContinue
            $f | Should -Not -BeNullOrEmpty
        }
    }

    It 'QMSKVPTyp enthält "Verbesserungsidee"' {
        $f = Get-PnPField -List 'QMS-KVP' -Identity 'QMSKVPTyp' -Includes Choices
        $f.Choices | Should -Contain 'Verbesserungsidee'
    }

    It 'QMSKVPTyp enthält "Korrekturmaßnahme"' {
        $f = Get-PnPField -List 'QMS-KVP' -Identity 'QMSKVPTyp' -Includes Choices
        $f.Choices | Should -Contain 'Korrekturmaßnahme'
    }

    It 'QMSKVPTyp enthält "Auditfeststellung"' {
        $f = Get-PnPField -List 'QMS-KVP' -Identity 'QMSKVPTyp' -Includes Choices
        $f.Choices | Should -Contain 'Auditfeststellung'
    }

    It 'QMSQuelle enthält ISO-Referenzen' {
        $f = Get-PnPField -List 'QMS-KVP' -Identity 'QMSQuelle' -Includes Choices
        $f.Choices | Should -Contain 'Internes Audit (ISO 9.2)'
        $f.Choices | Should -Contain 'Managementbewertung (ISO 9.3)'
        $f.Choices | Should -Contain 'Kundenfeedback (ISO 9.1.2)'
    }

    # Managed Metadata Felder
    It 'QMSBereich ist ein Managed Metadata Feld' {
        $f = Get-PnPField -List 'QMS-KVP' -Identity 'QMSBereich' -ErrorAction SilentlyContinue
        $f | Should -Not -BeNullOrEmpty
        $f.TypeAsString | Should -Be 'TaxonomyFieldType'
    }

    It 'QMSProzess ist ein Managed Metadata Feld (MultiValue)' {
        $f = Get-PnPField -List 'QMS-KVP' -Identity 'QMSProzess' -ErrorAction SilentlyContinue
        $f | Should -Not -BeNullOrEmpty
        $f.TypeAsString | Should -Be 'TaxonomyFieldTypeMulti'
    }

    # PDCA-Status-Feld
    It 'QMSStatus (PDCA) vorhanden und enthält alle Zykluswerte' {
        $f = Get-PnPField -List 'QMS-KVP' -Identity 'QMSStatus' -Includes Choices
        $f | Should -Not -BeNullOrEmpty
        $f.Choices | Should -Contain 'Offen'
        $f.Choices | Should -Contain 'Massnahme definiert'
        $f.Choices | Should -Contain 'In Bearbeitung'
        $f.Choices | Should -Contain 'Wirksamkeitsprüfung'
        $f.Choices | Should -Contain 'Abgeschlossen'
        $f.Choices | Should -Contain 'Abgelehnt'
    }

    It 'QMSStatus hat Standardwert "Offen"' {
        $f = Get-PnPField -List 'QMS-KVP' -Identity 'QMSStatus' -Includes DefaultValue
        $f.DefaultValue | Should -Be 'Offen'
    }

    # Fortschritt-Feld
    It 'QMSFortschritt ist ein Number-Feld (0–100)' {
        $f = Get-PnPField -List 'QMS-KVP' -Identity 'QMSFortschritt' -ErrorAction SilentlyContinue
        $f | Should -Not -BeNullOrEmpty
        $f.TypeAsString | Should -Be 'Number'
    }

    # PDCA-Felder komplett
    $pdcaFields = @(
        'QMSBeschreibung', 'QMSZielzustand', 'QMSUrsache', 'QMSMassnahme',
        'QMSVerantwortlicher', 'QMSErfasser', 'QMSZieldatum',
        'QMSWirksamkeitsbeschreibung', 'QMSWirksamkeitsdatum',
        'QMSWirksamkeitsstatus', 'QMSWirksamkeitsprueferIn',
        'QMSAbgeschlossenAm', 'QMSVerknuepfteDokumente', 'QMSISOKapitel'
    )
    foreach ($field in $pdcaFields) {
        It "PDCA-Spalte vorhanden: $field" {
            $f = Get-PnPField -List 'QMS-KVP' -Identity $field -ErrorAction SilentlyContinue
            $f | Should -Not -BeNullOrEmpty
        }
    }

    # Wirksamkeitsstatus
    It 'QMSWirksamkeitsstatus enthält alle Beurteilungswerte' {
        $f = Get-PnPField -List 'QMS-KVP' -Identity 'QMSWirksamkeitsstatus' -Includes Choices
        $f.Choices | Should -Contain 'Ausstehend'
        $f.Choices | Should -Contain 'Wirksam'
        $f.Choices | Should -Contain 'Nicht wirksam – neue Massnahme erforderlich'
    }

    # Ansichten
    It 'Ansicht "Offene KVP" existiert' {
        $view = Get-PnPView -List 'QMS-KVP' -Identity 'Offene KVP' -ErrorAction SilentlyContinue
        $view | Should -Not -BeNullOrEmpty
    }

    It 'Ansicht "Wirksamkeitsprüfung" existiert' {
        $view = Get-PnPView -List 'QMS-KVP' -Identity 'Wirksamkeitsprüfung' -ErrorAction SilentlyContinue
        $view | Should -Not -BeNullOrEmpty
    }

    It 'Ansicht "Nach Bereich" existiert' {
        $view = Get-PnPView -List 'QMS-KVP' -Identity 'Nach Bereich' -ErrorAction SilentlyContinue
        $view | Should -Not -BeNullOrEmpty
    }

    # Berechtigungen
    It 'QMS-Leser haben Lesezugriff auf QMS-KVP' {
        $perms = Get-PnPListPermissions -Identity 'QMS-KVP'
        $leserPerm = $perms | Where-Object { $_.Member.Title -eq 'QMS-Leser' }
        $leserPerm | Should -Not -BeNullOrEmpty
        $leserPerm.RoleDefinitionBindings.Name | Should -Contain 'Read'
    }

    It 'QMS-Ersteller haben Contribute-Zugriff auf QMS-KVP' {
        $perms = Get-PnPListPermissions -Identity 'QMS-KVP'
        $erstellerPerm = $perms | Where-Object { $_.Member.Title -eq 'QMS-Ersteller' }
        $erstellerPerm | Should -Not -BeNullOrEmpty
        $erstellerPerm.RoleDefinitionBindings.Name | Should -Contain 'Contribute'
    }

    It 'QMS-Administratoren haben Vollzugriff auf QMS-KVP' {
        $perms = Get-PnPListPermissions -Identity 'QMS-KVP'
        $adminPerm = $perms | Where-Object { $_.Member.Title -eq 'QMS-Administratoren' }
        $adminPerm | Should -Not -BeNullOrEmpty
        $adminPerm.RoleDefinitionBindings.Name | Should -Contain 'Full Control'
    }
}
