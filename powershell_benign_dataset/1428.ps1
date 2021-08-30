
function Install-CMsmq
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Switch]
        
        $HttpSupport,
        
        [Switch]
        
        $ActiveDirectoryIntegration,
        
        [Switch]
        
        $Dtc
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Warning -Message ('Install-CMsmq is obsolete and will be removed in a future major version of Carbon.')

    $optionalArgs = @{ }
    if( $HttpSupport )
    {
        $optionalArgs.MsmqHttpSupport = $true
    }
    
    if( $ActiveDirectoryIntegration )
    {
        $optionalArgs.MsmqActiveDirectoryIntegration = $true
    }
    
    Install-CWindowsFeature -Msmq @optionalArgs
    
    if( $Dtc )
    {
        Set-Service -Name MSDTC -StartupType Automatic
        Start-Service -Name MSDTC
        $svc = Get-Service -Name MSDTC
        $svc.WaitForStatus( [ServiceProcess.ServiceControllerStatus]::Running )
    }
}

