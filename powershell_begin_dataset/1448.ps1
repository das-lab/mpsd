
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

