




configuration PSModule_InstallModuleAllowClobberConfig
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
        PSModule 'InstallModuleAndAllowClobber'
        {
            Name         = $ModuleName
            AllowClobber = $true
        }
    }
}
