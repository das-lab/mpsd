











function Initialize-CLcm
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='Push')]
        [Switch]
        
        $Push,

        [Parameter(Mandatory=$true,ParameterSetName='PullWebDownloadManager')]
        [string]
        
        $ServerUrl,

        [Parameter(ParameterSetName='PullWebDownloadManager')]
        [Switch]
        
        $AllowUnsecureConnection,

        [Parameter(Mandatory=$true,ParameterSetName='PullFileDownloadManager')]
        [string]
        
        $SourcePath,

        [Parameter(Mandatory=$true,ParameterSetName='PullWebDownloadManager')]
        [Parameter(Mandatory=$true,ParameterSetName='PullFileDownloadManager')]
        [Guid]
        
        $ConfigurationID,

        [Parameter(Mandatory=$true,ParameterSetName='PullWebDownloadManager')]
        [Parameter(Mandatory=$true,ParameterSetName='PullFileDownloadManager')]
        [ValidateSet('ApplyOnly','ApplyAndMonitor','ApplyAndAutoCorrect')]
        [string]
        
        $ConfigurationMode,

        [Parameter(Mandatory=$true)]
        [string[]]
        
        $ComputerName,

        [PSCredential]
        
        $Credential,

        [Parameter(ParameterSetName='PullWebDownloadManager')]
        [Parameter(ParameterSetName='PullFileDownloadManager')]
        [Switch]
        
        $AllowModuleOverwrite,

        [Alias('Thumbprint')]
        [string]
        
        $CertificateID = $null,

        [string]
        
        $CertFile,

        [object]
        
        $CertPassword,

        [Alias('RebootNodeIfNeeded')]
        [Switch]
        
        $RebootIfNeeded,

        [Parameter(ParameterSetName='PullWebDownloadManager')]
        [Parameter(ParameterSetName='PullFileDownloadManager')]
        [ValidateRange(30,[Int32]::MaxValue)]
        [Alias('RefreshFrequencyMinutes')]
        [int]
        
        $RefreshIntervalMinutes = 30,

        [Parameter(ParameterSetName='PullWebDownloadManager')]
        [Parameter(ParameterSetName='PullFileDownloadManager')]
        [ValidateRange(1,([int]([Int32]::MaxValue)))]
        [int]
        
        $ConfigurationFrequency = 1,

        [Parameter(ParameterSetName='PullWebDownloadManager')]
        [Parameter(ParameterSetName='PullFileDownloadManager')]
        [PSCredential]
        
        $LcmCredential
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -match '^Pull(File|Web)DownloadManager' )
    {
        if( [Environment]::OSVersion.Version.Major -ge 10 )
        {
            Write-Error -Message ('Initialize-CLcm can''t configure the local configuration manager to use the file or web download manager on Windows Server 2016 or later.')
            return
        }
    }

    if( $CertPassword -and $CertPassword -isnot [securestring] )
    {
        Write-Warning -Message ('You passed a plain text password to `Initialize-CLcm`. A future version of Carbon will remove support for plain-text passwords. Please pass a `SecureString` instead.')
        $CertPassword = ConvertTo-SecureString -String $CertPassword -AsPlainText -Force
    }
    
    $thumbprint = $null
    if( $CertificateID )
    {
        $thumbprint = $CertificateID
    }

    $privateKey = $null
    if( $CertFile )
    {
        $CertFile = Resolve-CFullPath -Path $CertFile
        if( -not (Test-Path -Path $CertFile -PathType Leaf) )
        {
            Write-Error ('Certificate file ''{0}'' not found.' -f $CertFile)
            return
        }

        $privateKey = Get-CCertificate -Path $CertFile -Password $CertPassword
        if( -not $privateKey )
        {
            return
        }

        if( -not $privateKey.HasPrivateKey )
        {
            Write-Error ('Certificate file ''{0}'' does not have a private key.' -f $CertFile)
            return
        }
        $thumbprint = $privateKey.Thumbprint
    }
    
    $credentialParam = @{ }
    if( $Credential )
    {
        $credentialParam.Credential = $Credential
    }

    $ComputerName = $ComputerName | 
                        Where-Object { 
                            if( Test-Connection -ComputerName $_ -Quiet ) 
                            {
                                return $true
                            }
                            
                            Write-Error ('Computer ''{0}'' not found or is unreachable.' -f $_)
                            return $false
                        }
    if( -not $ComputerName )
    {
        return
    }

    
    if( $privateKey )
    {
        $session = New-PSSession -ComputerName $ComputerName @credentialParam
        if( -not $session )
        {
            return
        }

        try
        {
            Install-CCertificate -Session $session `
                                -Path $CertFile `
                                -Password $CertPassword `
                                -StoreLocation ([Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine) `
                                -StoreName ([Security.Cryptography.X509Certificates.StoreName]::My) | 
                Out-Null
        }
        finally
        {
            Remove-PSSession -Session $session -WhatIf:$false
        }
    }

    $sessions = New-CimSession -ComputerName $ComputerName @credentialParam

    try
    {
        $originalWhatIf = $WhatIfPreference
        $WhatIfPreference = $false
        configuration Lcm 
        {
            Set-StrictMode -Off

            $configID = $null
            if( $ConfigurationID )
            {
                $configID = $ConfigurationID.ToString()
            }

            node $AllNodes.NodeName
            {
                if( $Node.RefreshMode -eq 'Push' )
                {
                    LocalConfigurationManager
                    {
                        CertificateID = $thumbprint;
                        RebootNodeIfNeeded = $RebootIfNeeded;
                        RefreshMode = 'Push';
                    }
                }
                else
                {
                    if( $Node.RefreshMode -like '*FileDownloadManager' )
                    {
                        $downloadManagerName = 'DscFileDownloadManager'
                        $customData = @{ SourcePath = $SourcePath }
                    }
                    else
                    {
                        $downloadManagerName = 'WebDownloadManager'
                        $customData = @{
                                            ServerUrl = $ServerUrl;
                                            AllowUnsecureConnection = $AllowUnsecureConnection.ToString();
                                      }
                    }

                    LocalConfigurationManager
                    {
                        AllowModuleOverwrite = $AllowModuleOverwrite;
                        CertificateID = $thumbprint;
                        ConfigurationID = $configID;
                        ConfigurationMode = $ConfigurationMode;
                        ConfigurationModeFrequencyMins = $RefreshIntervalMinutes * $ConfigurationFrequency;
                        Credential = $LcmCredential;
                        DownloadManagerCustomData = $customData;
                        DownloadManagerName = $downloadManagerName;
                        RebootNodeIfNeeded = $RebootIfNeeded;
                        RefreshFrequencyMins = $RefreshIntervalMinutes;
                        RefreshMode = 'Pull'
                    }
                }
            }
        }

        $WhatIfPreference = $originalWhatIf

        $tempDir = New-CTempDirectory -Prefix 'Carbon+Initialize-CLcm+' -WhatIf:$false

        try
        {
            [object[]]$allNodes = $ComputerName | ForEach-Object { @{ NodeName = $_; PSDscAllowPlainTextPassword = $true; RefreshMode = $PSCmdlet.ParameterSetName } }
            $configData = @{
                AllNodes = $allNodes
            }

            $whatIfParam = @{ }
            if( (Get-Command -Name 'Lcm').Parameters.ContainsKey('WhatIf') )
            {
                $whatIfParam['WhatIf'] = $false
            }

            & Lcm -OutputPath $tempDir @whatIfParam -ConfigurationData $configData | Out-Null

            Set-DscLocalConfigurationManager -ComputerName $ComputerName -Path $tempDir @credentialParam

            Get-DscLocalConfigurationManager -CimSession $sessions
        }
        finally
        {
            Remove-Item -Path $tempDir -Recurse -WhatIf:$false
        }
    }
    finally
    {
        Remove-CimSession -CimSession $sessions -WhatIf:$false
    }
}
