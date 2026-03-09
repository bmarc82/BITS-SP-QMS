#Requires -Modules Pester
<#
.SYNOPSIS
    Pester Unit Tests – QMS.Core Modul
.DESCRIPTION
    Testet Logging, Konfigurationsverwaltung und Retry-Logik ohne Tenant-Verbindung.
#>

BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/QMS.Core/QMS.Core.psm1"
    Import-Module $modulePath -Force
}

Describe 'Write-QMSLog' {

    It 'Schreibt INFO-Nachricht ohne Fehler' {
        { Write-QMSLog -Message 'Testmeldung' -Level INFO } | Should -Not -Throw
    }

    It 'Schreibt WARNING-Nachricht ohne Fehler' {
        { Write-QMSLog -Message 'Warnung' -Level WARNING } | Should -Not -Throw
    }

    It 'Schreibt ERROR-Nachricht ohne Fehler' {
        { Write-QMSLog -Message 'Fehler' -Level ERROR } | Should -Not -Throw
    }

    It 'Verwendet INFO als Standardlevel' {
        # Kein Fehler wenn Level weggelassen wird
        { Write-QMSLog -Message 'Ohne Level' } | Should -Not -Throw
    }
}

Describe 'Get-QMSConfig' {

    It 'Wirft Fehler wenn Konfigurationsdatei fehlt' {
        { Get-QMSConfig -ConfigPath 'C:\nicht-vorhanden\config.ps1' } | Should -Throw
    }

    It 'Lädt Konfiguration aus gültiger Datei' {
        $tempConfig = New-TemporaryFile
        Set-Content $tempConfig.FullName -Value '$QMSConfig = @{ TenantUrl = "https://test.sharepoint.com"; AppId = "abc"; CertThumbprint = "def"; SiteUrl = "https://test.sharepoint.com/sites/qms"; TenantId = "tid"; AdminEmail = "admin@test.com" }'

        $config = Get-QMSConfig -ConfigPath $tempConfig.FullName
        $config.TenantUrl | Should -Be 'https://test.sharepoint.com'
        $config.AppId     | Should -Be 'abc'

        Remove-Item $tempConfig.FullName
    }
}

Describe 'Invoke-QMSWithRetry' {

    It 'Gibt Ergebnis zurück wenn ScriptBlock erfolgreich' {
        $result = Invoke-QMSWithRetry -ScriptBlock { 42 } -MaxRetries 3
        $result | Should -Be 42
    }

    It 'Wirft nach MaxRetries Versuchen' {
        $attempt = 0
        {
            Invoke-QMSWithRetry -ScriptBlock {
                $script:attempt++
                throw 'Immer Fehler'
            } -MaxRetries 2 -DelaySeconds 0
        } | Should -Throw
        $attempt | Should -Be 2
    }

    It 'Gibt Ergebnis nach erneutem Versuch zurück' {
        $attempt = 0
        $result = Invoke-QMSWithRetry -ScriptBlock {
            $script:attempt++
            if ($script:attempt -lt 2) { throw 'Erster Versuch fehlgeschlagen' }
            'Erfolg'
        } -MaxRetries 3 -DelaySeconds 0
        $result   | Should -Be 'Erfolg'
        $attempt  | Should -Be 2
    }
}
