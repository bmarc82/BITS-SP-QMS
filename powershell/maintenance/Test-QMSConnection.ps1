#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Verbindung und Berechtigungen prüfen
#>
[CmdletBinding()]
param()

$Config = Get-QMSConfig
$result = Test-QMSConnection -Config $Config
if ($result) {
    Write-QMSLog "Verbindungstest erfolgreich"
} else {
    Write-QMSLog "Verbindungstest FEHLGESCHLAGEN" -Level ERROR
    exit 1
}
