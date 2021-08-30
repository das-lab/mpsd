
function Resolve-WindowsFeatureName
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        
        $Name
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    Write-Warning -Message ('Resolve-WindowsFeatureName is obsolete and will be removed in a future major version of Carbon.')

    Assert-WindowsFeatureFunctionsSupported -WarningAction SilentlyContinue | Out-Null

    $featureMap = @{
                        Iis = 'Web-WebServer';
                        IisHttpRedirection = 'Web-Http-Redirect';
                        Msmq = 'MSMQ-Server';
                        MsmqHttpSupport = 'MSMQ-HTTP-Support';
                        MsmqActiveDirectoryIntegration = 'MSMQ-Directory';
                   }

    if( $useOCSetup )
    {
        $featureMap = @{
                            Iis = 'IIS-WebServer';
                            IisHttpRedirection = 'IIS-HttpRedirect';
                            Msmq = 'MSMQ-Server';
                            MsmqHttpSupport = 'MSMQ-HTTP';
                            MsmqActiveDirectoryIntegration = 'MSMQ-ADIntegration';
                       }
    }
    
    $Name | 
        Where-Object { $featureMap.ContainsKey( $_ ) } |
        ForEach-Object { $featureMap[$_] }

}

