




configuration PSModule_InstallModuleTrustedConfig
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ModuleName
    )

    Import-DscResource -ModuleName 'PowerShellGet'

    Node $nodeName
    {
        PSModule 'InstallModuleAsTrusted'
        {
            Name               = $ModuleName
            InstallationPolicy = 'Trusted'
        }
    }
}
