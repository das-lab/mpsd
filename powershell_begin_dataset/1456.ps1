
function Test-CWindowsFeature
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Switch]
        
        $Installed
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    Write-Warning -Message ('Test-CWindowsFeature is obsolete and will be removed in a future major version of Carbon.')

    if( -not (Get-Module -Name 'ServerManager') -and -not (Assert-WindowsFeatureFunctionsSupported) )
    {
        return
    }
    
    $feature = Get-CWindowsFeature -Name $Name 
    
    if( $feature )
    {
        if( $Installed )
        {
            return $feature.Installed
        }
        return $true
    }
    else
    {
        return $false
    }
}

