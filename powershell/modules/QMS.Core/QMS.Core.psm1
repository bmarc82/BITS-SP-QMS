#Requires -Version 7.0
<#
.SYNOPSIS
    QMS Kernmodul – Hilfsfunktionen, Logging, Konfigurationsverwaltung
.VERSION
    1.0.0
#>

function Write-QMSLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','WARNING','ERROR')][string]$Level = 'INFO',
        [string]$Module = 'QMS'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] [$Module] $Message"
    Write-Host $logEntry -ForegroundColor $(
        switch ($Level) {
            'WARNING' { 'Yellow' }
            'ERROR'   { 'Red' }
            default   { 'White' }
        }
    )
    Add-Content -Path "$PSScriptRoot/../../logs/qms.log" -Value $logEntry -ErrorAction SilentlyContinue
}

function Get-QMSConfig {
    [CmdletBinding()]
    param([string]$ConfigPath = "$PSScriptRoot/../../config/connection.config.ps1")
    if (-not (Test-Path $ConfigPath)) {
        throw "Konfigurationsdatei nicht gefunden: $ConfigPath"
    }
    . $ConfigPath
    return $QMSConfig
}

function Test-QMSConnection {
    [CmdletBinding()]
    param([hashtable]$Config)
    try {
        Connect-PnPOnline -Url $Config.SiteUrl -ClientId $Config.AppId -Thumbprint $Config.CertThumbprint -Tenant $Config.TenantId
        Write-QMSLog "Verbindung erfolgreich: $($Config.SiteUrl)"
        return $true
    }
    catch {
        Write-QMSLog "Verbindungsfehler: $_" -Level ERROR
        return $false
    }
}

function Invoke-QMSWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 5
    )
    $attempt = 0
    do {
        try {
            $attempt++
            return & $ScriptBlock
        }
        catch {
            if ($attempt -ge $MaxRetries) { throw }
            Write-QMSLog "Versuch $attempt fehlgeschlagen, warte ${DelaySeconds}s..." -Level WARNING
            Start-Sleep -Seconds $DelaySeconds
        }
    } while ($attempt -lt $MaxRetries)
}
