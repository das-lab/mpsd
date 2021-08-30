
function Test-CIisSecurityAuthentication
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Alias('Path')]
        [string]
        
        $VirtualPath = '',
        
        [Parameter(Mandatory=$true,ParameterSetName='Anonymous')]
        [Switch]
        
        $Anonymous,
        
        [Parameter(Mandatory=$true,ParameterSetName='Basic')]
        [Switch]
        
        $Basic,
        
        [Parameter(Mandatory=$true,ParameterSetName='Digest')]
        [Switch]
        
        $Digest,
        
        [Parameter(Mandatory=$true,ParameterSetName='Windows')]
        [Switch]
        
        $Windows
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $getConfigArgs = @{ $pscmdlet.ParameterSetName = $true }
    $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath @getConfigArgs
    return ($authSettings.GetAttributeValue('enabled') -eq 'true')
}

