#Requires -Version 7.0
#Requires -Modules PnP.PowerShell, QMS.Core
<#
.SYNOPSIS
    Schritt 3: QMS-Dokumentenbibliothek konfigurieren
.VERSION
    1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Config = Get-QMSConfig
if (-not (Test-QMSConnection -Config $Config)) { exit 1 }

Write-QMSLog "Konfiguriere Dokumentenbibliothek..."

$listName = 'QMS-Dokumente'
$existing = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue

if (-not $existing) {
    if ($PSCmdlet.ShouldProcess($listName, 'Bibliothek erstellen')) {
        New-PnPList -Title $listName -Template DocumentLibrary -EnableVersioning -MajorVersions 10
        Write-QMSLog "Bibliothek erstellt: $listName"
    }
}

# Spalten hinzufügen
$fields = @(
    @{ Name = 'QMSStatus';               Type = 'Choice'; Choices = @('Entwurf','In Prüfung','Freigegeben','Archiviert') },
    @{ Name = 'QMSProzessverantwortlicher'; Type = 'User' },
    @{ Name = 'QMSGueltigAb';            Type = 'DateTime' },
    @{ Name = 'QMSNaechstesPruefDatum';  Type = 'DateTime' },
    @{ Name = 'QMSISOKapitel';           Type = 'Text' },
    @{ Name = 'QMSProzessart';           Type = 'Choice'; Choices = @('Führungsprozess','Kernprozess','Supportprozess') }
)

foreach ($field in $fields) {
    $existing = Get-PnPField -List $listName -Identity $field.Name -ErrorAction SilentlyContinue
    if ($existing) {
        Write-QMSLog "Spalte bereits vorhanden: $($field.Name)" -Level WARNING
        continue
    }

    Write-QMSLog "Füge Spalte hinzu: $($field.Name)"

    switch ($field.Type) {
        'Choice' {
            $choicesXml = ($field.Choices | ForEach-Object { "<CHOICE>$_</CHOICE>" }) -join ''
            $schema = "<Field Type='Choice' DisplayName='$($field.Name)' Name='$($field.Name)' Required='FALSE'><CHOICES>$choicesXml</CHOICES></Field>"
            Add-PnPFieldFromXml -List $listName -FieldXml $schema | Out-Null
        }
        'User' {
            Add-PnPField -List $listName -DisplayName $field.Name -InternalName $field.Name -Type User -Required:$false | Out-Null
        }
        'DateTime' {
            Add-PnPField -List $listName -DisplayName $field.Name -InternalName $field.Name -Type DateTime -Required:$false | Out-Null
        }
        'Text' {
            Add-PnPField -List $listName -DisplayName $field.Name -InternalName $field.Name -Type Text -Required:$false | Out-Null
        }
    }

    Write-QMSLog "Spalte hinzugefügt: $($field.Name)"
}
