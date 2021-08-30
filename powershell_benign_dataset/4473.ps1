



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
                NodeName        = 'localhost'
                CertificateFile = $env:DscPublicCertificatePath

                Module1_Name     = 'PSLogging'
                Module2_Name     = 'SqlServer'

                Module2_RequiredVersion = '21.0.17279'
                Module2_MinimumVersion = '21.0.17199'
                Module2_MaximumVersion = '21.1.18068'
            }
        )
    }
}


Configuration MSFT_PSModule_SetPackageSourceAsNotTrusted_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSRepository 'Integration_Test'
        {
            Name               = 'PSGallery'
            InstallationPolicy = 'Untrusted'
        }
    }
}


Configuration MSFT_PSModule_InstallWithTrusted_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name               = $Node.Module1_Name
            InstallationPolicy = 'Trusted'
        }
    }
}


Configuration MSFT_PSModule_UninstallModule1_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Ensure = 'Absent'
            Name   = $Node.Module1_Name
        }
    }
}


Configuration MSFT_PSModule_SetPackageSourceAsTrusted_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSRepository 'Integration_Test'
        {
            Name               = 'PSGallery'
            InstallationPolicy = 'Trusted'
        }
    }
}


Configuration MSFT_PSModule_DefaultParameters_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name = $Node.Module1_Name
        }
    }
}


Configuration MSFT_PSModule_UsingAllowClobber_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name         = $Node.Module2_Name
            AllowClobber = $true
        }
    }
}


Configuration MSFT_PSModule_UninstallModule2_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Ensure = 'Absent'
            Name   = $Node.Module2_Name
        }
    }
}


Configuration MSFT_PSModule_RequiredVersion_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name            = $Node.Module2_Name
            RequiredVersion = $Node.Module2_RequiredVersion
            AllowClobber    = $true
        }
    }
}


Configuration MSFT_PSModule_RequiredVersion_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name            = $Node.Module2_Name
            RequiredVersion = $Node.Module2_RequiredVersion
            AllowClobber    = $true
        }
    }
}


Configuration MSFT_PSModule_VersionRange_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name           = $Node.Module2_Name
            MinimumVersion = $Node.Module2_MinimumVersion
            MaximumVersion = $Node.Module2_MaximumVersion
            AllowClobber   = $true
        }
    }
}
