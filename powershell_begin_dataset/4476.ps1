




configuration PSRepository_AddRepositoryConfig
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
            Name                  = $RepositoryName
            SourceLocation        = 'https://www.poshtestgallery.com/api/v2/'
            PublishLocation       = 'https://www.poshtestgallery.com/api/v2/package/'
            ScriptSourceLocation  = 'https://www.poshtestgallery.com/api/v2/items/psscript/'
            ScriptPublishLocation = 'https://www.poshtestgallery.com/api/v2/package/'
            InstallationPolicy    = 'Trusted'
        }
    }
}
