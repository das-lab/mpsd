




configuration PSRepository_RemoveRepositoryConfig
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryName
    )

    Import-DscResource -ModuleName 'PowerShellGet'

    Node $nodeName
    {
        PSRepository 'AddRepository'
        {
            Ensure = 'Absent'
            Name   = $RepositoryName
        }
    }
}
