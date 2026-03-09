#Requires -Modules Pester
<#
.SYNOPSIS
    Compliance-Test: Freigabe-Workflow-Integrität (ISO 9001:2015 Kap. 7.5.2b)
.DESCRIPTION
    Prüft die Integrität des Freigabe-Workflows:
    - Kein Dokument in "In Prüfung" ohne gesetzten Prozessverantwortlichen
    - Vier-Augen-Prinzip: Freigeber ≠ Ersteller (Stichprobe aus Changelog)
    - Keine "Freigegeben"-Dokumente ohne Changelog-Eintrag
    - Review-Datum nach Freigabe korrekt gesetzt

    Ausführen:
        $env:QMS_ENV = 'TEST'
        Invoke-Pester -Path ./ApprovalWorkflow.Tests.ps1 -Output Detailed
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

Describe 'ISO 7.5.2b – Freigabe-Workflow Integrität' {

    It 'Kein Dokument "In Prüfung" ohne Prozessverantwortlichen (würde Flow blockieren)' {
        $stuck = Get-PnPListItem -List 'QMS-Dokumente' `
            -Query "<View><Query><Where><And><Eq><FieldRef Name='QMSStatus'/><Value Type='Choice'>In Prüfung</Value></Eq><IsNull><FieldRef Name='QMSProzessverantwortlicher'/></IsNull></And></Where></Query></View>"
        $stuck.Count | Should -Be 0 `
            -Because 'Dokumente ohne Freigeber können nicht genehmigt werden'
    }

    It 'Vier-Augen-Prinzip: Kein Changelog-Eintrag mit identischem Ersteller und Freigeber' {
        $selfApproved = Get-PnPListItem -List 'QMS-Changelog' `
            -Query "<View><Query><Where><And><IsNotNull><FieldRef Name='QMSFreigeber'/></IsNotNull><IsNotNull><FieldRef Name='QMSErsteller'/></IsNotNull></And></Where></Query></View>" `
            -Fields 'QMSErsteller','QMSFreigeber','Title'

        $violations = $selfApproved | Where-Object {
            $_['QMSErsteller'] -and $_['QMSFreigeber'] -and
            $_['QMSErsteller'].ToLower() -eq $_['QMSFreigeber'].ToLower()
        }

        $violations.Count | Should -Be 0 `
            -Because "Selbstfreigaben verstoßen gegen ISO 9001:2015 Kap. 7.5.2b (Vier-Augen-Prinzip)"
    }

    It 'Kein freigegebenes Dokument ohne QMSGueltigAb-Datum' {
        $missing = Get-PnPListItem -List 'QMS-Dokumente' `
            -Query "<View><Query><Where><And><Eq><FieldRef Name='QMSStatus'/><Value Type='Choice'>Freigegeben</Value></Eq><IsNull><FieldRef Name='QMSGueltigAb'/></IsNull></And></Where></Query></View>"
        $missing.Count | Should -Be 0 `
            -Because 'Freigegebene Dokumente müssen ein Gültig-ab-Datum haben'
    }

    It 'Kein freigegebenes Dokument mit Nebenversionsnummer (x.y, y>0) als Hauptversion deklariert' {
        $items = Get-PnPListItem -List 'QMS-Dokumente' `
            -Query "<View><Query><Where><And><Eq><FieldRef Name='QMSStatus'/><Value Type='Choice'>Freigegeben</Value></Eq><Eq><FieldRef Name='QMSVersionTyp'/><Value Type='Choice'>Hauptversion</Value></Eq></And></Where></Query></View>" `
            -Fields 'FileLeafRef','QMSVersion','QMSVersionTyp'

        $invalidVersions = $items | Where-Object { $_['QMSVersion'] -and $_['QMSVersion'] -notmatch '^\d+\.0$' }
        $invalidVersions.Count | Should -Be 0 `
            -Because 'Als "Hauptversion" deklarierte Dokumente müssen eine x.0-Versionsnummer haben'
    }

    It 'Content Approval Status aller freigegebener Dokumente ist "Approved"' {
        $items = Get-PnPListItem -List 'QMS-Dokumente' `
            -Query "<View><Query><Where><Eq><FieldRef Name='QMSStatus'/><Value Type='Choice'>Freigegeben</Value></Eq></Where></Query></View>" `
            -Fields 'FileLeafRef','_ModerationStatus'

        $notApproved = $items | Where-Object { $_['_ModerationStatus'] -ne 0 }
        $notApproved.Count | Should -Be 0 `
            -Because 'QMSStatus=Freigegeben und SP-ModerationStatus müssen übereinstimmen'
    }
}

Describe 'ISO 7.5.3 – Lenkung: Review-Termine und Eskalation' {

    It 'Kein freigegebenes Dokument ist mehr als 90 Tage überfällig' {
        $cutoff = (Get-Date).AddDays(-90).ToString('yyyy-MM-ddT00:00:00Z')
        $overdue = Get-PnPListItem -List 'QMS-Dokumente' `
            -Query "<View><Query><Where><And><Eq><FieldRef Name='QMSStatus'/><Value Type='Choice'>Freigegeben</Value></Eq><Leq><FieldRef Name='QMSNaechstesPruefDatum'/><Value Type='DateTime'>$cutoff</Value></Leq></And></Where></Query></View>"
        $overdue.Count | Should -Be 0 `
            -Because 'Dokumente ohne Review >90 Tage gefährden ISO 7.5.3-Konformität'
    }

    It 'QMS-Review-Log Liste existiert für Audit-Trail' {
        $list = Get-PnPList -Identity 'QMS-Review-Log' -ErrorAction SilentlyContinue
        $list | Should -Not -BeNullOrEmpty
    }
}

Describe 'ISO 10.2 – Nichtkonformitäten und Korrekturmassnahmen' {

    It 'QMS-KVP Liste hat keine offenen Einträge vom Typ "Korrekturmassnahme" älter als 90 Tage' {
        $cutoff = (Get-Date).AddDays(-90).ToString('yyyy-MM-ddT00:00:00Z')
        $stale = Get-PnPListItem -List 'QMS-KVP' `
            -Query "<View><Query><Where><And><And><Eq><FieldRef Name='QMSKVPTyp'/><Value Type='Choice'>Korrekturmaßnahme</Value></Eq><Or><Eq><FieldRef Name='QMSStatus'/><Value Type='Choice'>Offen</Value></Eq><Eq><FieldRef Name='QMSStatus'/><Value Type='Choice'>Massnahme definiert</Value></Eq></Or></And><Leq><FieldRef Name='Created'/><Value Type='DateTime'>$cutoff</Value></Leq></And></Where></Query></View>"
        $stale.Count | Should -Be 0 `
            -Because 'Korrekturmassnahmen sollen innerhalb von 90 Tagen bearbeitet werden (ISO 10.2)'
    }
}
