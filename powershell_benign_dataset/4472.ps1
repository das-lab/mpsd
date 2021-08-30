



$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName                  = 'localhost'
                CertificateFile           = $env:DscPublicCertificatePath

                Name                      = 'PSTestGallery'

                TestSourceLocation        = 'https://www.poshtestgallery.com/api/v2/'
                TestPublishLocation       = 'https://www.poshtestgallery.com/api/v2/package/'
                TestScriptSourceLocation  = 'https://www.poshtestgallery.com/api/v2/items/psscript/'
                TestScriptPublishLocation = 'https://www.poshtestgallery.com/api/v2/package/'

                
                SourceLocation            = 'https://www.nuget.org/api/v2'
                PublishLocation           = 'https://www.nuget.org/api/v2/package'
                ScriptSourceLocation      = 'https://www.nuget.org/api/v2/items/psscript/'
                ScriptPublishLocation     = 'https://www.nuget.org/api/v2/package'

                
                PackageManagementProvider = 'NuGet'

                TestModuleName            = 'ContosoServer'
            }
        )
    }
}


Configuration MSFT_PSRepository_AddRepository_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSRepository 'Integration_Test'
        {
            Name                  = $Node.Name
            SourceLocation        = $Node.TestSourceLocation
            PublishLocation       = $Node.TestPublishLocation
            ScriptSourceLocation  = $Node.TestScriptSourceLocation
            ScriptPublishLocation = $Node.TestScriptPublishLocation
            InstallationPolicy    = 'Trusted'
        }
    }
}


Configuration MSFT_PSRepository_InstallTestModule_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name       = $Node.TestModuleName
            Repository = $Node.Name
        }
    }
}


Configuration MSFT_PSRepository_ChangeRepository_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSRepository 'Integration_Test'
        {
            Name                      = $Node.Name
            SourceLocation            = $Node.SourceLocation
            PublishLocation           = $Node.PublishLocation
            ScriptSourceLocation      = $Node.ScriptSourceLocation
            ScriptPublishLocation     = $Node.ScriptPublishLocation
            PackageManagementProvider = $Node.PackageManagementProvider
            InstallationPolicy        = 'Untrusted'
        }
    }
}


Configuration MSFT_PSRepository_RemoveRepository_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSRepository 'Integration_Test'
        {
            Ensure = 'Absent'
            Name   = $Node.Name
        }
    }
}
