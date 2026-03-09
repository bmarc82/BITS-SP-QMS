#Requires -Modules Pester
<#
.SYNOPSIS
    Compliance-Test: Metadaten-Vollständigkeit (ISO 9001:2015 Kap. 7.5)
.DESCRIPTION
    Prüft alle freigegebenen Dokumente auf vollständige Pflichtmetadaten.
    Fehlende Metadaten bei freigegebenen Dokumenten verstoßen gegen
    ISO 9001:2015 Kap. 7.5.2 (Erstellen und Aktualisieren).

    Ausführen:
        $env:QMS_ENV = 'TEST'
        Invoke-Pester -Path ./MetadataCompleteness.Tests.ps1 -Output Detailed
#>

BeforeAll {
    if ($env:QMS_ENV -ne 'TEST' -and $env:QMS_ENV -ne 'PROD') {
        throw "Setzen Sie QMS_ENV=TEST (oder PROD für Produktions-Compliance-Check)"
    }
    $modulePath = "$PSScriptRoot/../../modules/QMS.Core/QMS.Core.psm1"
    Import-Module $modulePath -Force
    $Config = Get-QMSConfig
    Connect-PnPOnline -Url $Config.SiteUrl -ClientId $Config.AppId `
        -Thumbprint $Config.CertThumbprint -Tenant $Config.TenantId

    # Alle freigegebenen Dokumente laden
    $script:approvedDocs = Get-PnPListItem -List 'QMS-Dokumente' `
        -Query "<View><Query><Where><Eq><FieldRef Name='QMSStatus'/><Value Type='Choice'>Freigegeben</Value></Eq></Where></Query></View>" `
        -Fields 'ID','FileLeafRef','QMSVersion','QMSStatus','QMSVersionTyp','QMSProzessverantwortlicher',
                'QMSGueltigAb','QMSNaechstesPruefDatum','QMSISOKapitel','QMSAenderungsart',
                'QMSAenderungsbeschreibung','QMSProzessart','QMSBereich'
}

AfterAll {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}

Describe 'ISO 7.5.2 – Metadaten-Vollständigkeit freigegebener Dokumente' {

    It 'Es gibt mindestens ein freigegebenes Dokument' {
        $script:approvedDocs.Count | Should -BeGreaterThan 0
    }

    Context 'Pflichtfelder je freigegebenes Dokument' {

        foreach ($doc in $script:approvedDocs) {
            $name = $doc['FileLeafRef']

            It "[$name] QMSVersion ist gesetzt" {
                $doc['QMSVersion'] | Should -Not -BeNullOrEmpty
            }

            It "[$name] QMSVersion hat gültiges Format (x.y)" {
                $doc['QMSVersion'] | Should -Match '^\d+\.\d+$'
            }

            It "[$name] QMSVersionTyp ist gesetzt" {
                $doc['QMSVersionTyp'] | Should -Not -BeNullOrEmpty
            }

            It "[$name] Hauptversion endet auf .0 (ISO 7.5.2 – Versionierungsregel)" {
                if ($doc['QMSVersionTyp'] -eq 'Hauptversion') {
                    $doc['QMSVersion'] | Should -Match '^\d+\.0$'
                }
            }

            It "[$name] QMSProzessverantwortlicher ist gesetzt" {
                $doc['QMSProzessverantwortlicher'] | Should -Not -BeNullOrEmpty
            }

            It "[$name] QMSGueltigAb ist gesetzt" {
                $doc['QMSGueltigAb'] | Should -Not -BeNullOrEmpty
            }

            It "[$name] QMSNaechstesPruefDatum ist gesetzt (ISO 7.5.3 – Lenkung)" {
                $doc['QMSNaechstesPruefDatum'] | Should -Not -BeNullOrEmpty
            }

            It "[$name] QMSNaechstesPruefDatum liegt in der Zukunft oder weniger als 30 Tage überfällig" {
                $pruefDatum = [datetime]$doc['QMSNaechstesPruefDatum']
                $daysDiff   = ($pruefDatum - (Get-Date)).TotalDays
                $daysDiff   | Should -BeGreaterThan -30 `
                    -Because "Mehr als 30 Tage überfällig – Eskalation erforderlich"
            }

            It "[$name] QMSAenderungsart ist gesetzt" {
                $doc['QMSAenderungsart'] | Should -Not -BeNullOrEmpty
            }

            It "[$name] QMSAenderungsbeschreibung ist gesetzt und mindestens 10 Zeichen" {
                $desc = $doc['QMSAenderungsbeschreibung']
                $desc | Should -Not -BeNullOrEmpty
                $desc.Length | Should -BeGreaterOrEqual 10
            }
        }
    }
}

Describe 'ISO 7.5.3 – Aufbewahrungsfristen' {

    It 'QMS-Dokumente Bibliothek hat Versionsverlauf aktiviert' {
        $list = Get-PnPList -Identity 'QMS-Dokumente' -Includes EnableVersioning
        $list.EnableVersioning | Should -Be $true
    }

    It 'Mindestens 50 Hauptversionen werden aufbewahrt' {
        $list = Get-PnPList -Identity 'QMS-Dokumente' -Includes MajorVersionLimit
        $list.MajorVersionLimit | Should -BeGreaterOrEqual 50
    }

    It 'Entwürfe sind nur für Freigeber sichtbar (DraftVersionVisibility = 2)' {
        $list = Get-PnPList -Identity 'QMS-Dokumente' -Includes DraftVersionVisibility
        [int]$list.DraftVersionVisibility | Should -Be 2
    }

    It 'Content Approval (Moderation) ist aktiviert' {
        $list = Get-PnPList -Identity 'QMS-Dokumente' -Includes EnableModeration
        $list.EnableModeration | Should -Be $true
    }
}

Describe 'ISO 7.5 – Changelog-Vollständigkeit' {

    It 'Jedes freigegebene Dokument hat mindestens einen Changelog-Eintrag' {
        foreach ($doc in $script:approvedDocs) {
            $name = $doc['FileLeafRef']
            $entries = Get-PnPListItem -List 'QMS-Changelog' `
                -Query "<View><Query><Where><Eq><FieldRef Name='QMSDokumentId'/><Value Type='Number'>$($doc['ID'])</Value></Eq></Where></Query></View>"
            $entries.Count | Should -BeGreaterThan 0 `
                -Because "[$name] hat keinen Changelog-Eintrag – möglicherweise direkt freigegeben ohne Flow"
        }
    }

    It 'Kein Changelog-Eintrag ohne Freigeber bei Hauptversionen' {
        $entries = Get-PnPListItem -List 'QMS-Changelog' `
            -Query "<View><Query><Where><And><Contains><FieldRef Name='QMSVersion'/><Value Type='Text'>.0</Value></Contains><IsNull><FieldRef Name='QMSFreigeber'/></IsNull></And></Where></Query></View>"
        $entries.Count | Should -Be 0 `
            -Because 'Hauptversionen müssen einen Freigeber im Changelog haben'
    }
}
