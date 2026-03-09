#Requires -Version 7.0
<#
.SYNOPSIS
    Einzelnes QMS-Modul aktualisieren
#>
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$ModuleId)

Write-Host "Update Modul: $ModuleId"
# TODO: Modulspezifisches Update-Script aufrufen
throw "Nicht implementiert"
