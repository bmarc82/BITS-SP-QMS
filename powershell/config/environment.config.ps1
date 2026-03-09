<#
.SYNOPSIS
    Umgebungsvariablen (DEV / TEST / PROD)
#>

$QMSEnvironment = switch ($env:QMS_ENV) {
    'PROD' { @{ LogLevel = 'WARNING'; ConfirmActions = $false } }
    'TEST' { @{ LogLevel = 'INFO';    ConfirmActions = $true  } }
    default { @{ LogLevel = 'INFO';   ConfirmActions = $true  } }  # DEV
}
