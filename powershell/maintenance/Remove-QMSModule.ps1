#Requires -Version 7.0
<#
.SYNOPSIS
    QMS-Modul sauber entfernen (ohne Datenverlust)
#>
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$ModuleId)

Write-Host "Entferne Modul: $ModuleId"
# TODO: Modulspezifisches Remove-Script aufrufen
throw "Nicht implementiert"
