
function Get-CIisSecurityAuthentication
{
    
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Alias('Path')]
        [string]
        
        $VirtualPath = '',

        [Parameter(Mandatory=$true,ParameterSetName='anonymousAuthentication')]        
        [Switch]
        
        $Anonymous,
        
        [Parameter(Mandatory=$true,ParameterSetName='basicAuthentication')]        
        [Switch]
        
        $Basic,
        
        [Parameter(Mandatory=$true,ParameterSetName='digestAuthentication')]        
        [Switch]
        
        $Digest,
        
        [Parameter(Mandatory=$true,ParameterSetName='windowsAuthentication')]        
        [Switch]
        
        $Windows
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sectionPath = 'system.webServer/security/authentication/{0}' -f $pscmdlet.ParameterSetName
    Get-CIisConfigurationSection -SiteName $SiteName -VirtualPath $VirtualPath -SectionPath $sectionPath
}

