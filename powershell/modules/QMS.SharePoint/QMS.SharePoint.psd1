@{
    ModuleVersion     = '1.0.0'
    GUID              = 'b2c3d4e5-f6a7-8901-bcde-f23456789012'
    Author            = 'QMS Team'
    Description       = 'QMS SharePoint-Operationen'
    PowerShellVersion = '7.0'
    RootModule        = 'QMS.SharePoint.psm1'
    RequiredModules   = @('QMS.Core')
    FunctionsToExport = @('New-QMSSite', 'Set-QMSContentTypes', 'Set-QMSLibrary', 'Set-QMSPermissions')
}
