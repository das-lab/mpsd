
function Get-CIisHttpHeader
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,
        
        [Alias('Path')]
        [string]
        
        $VirtualPath = '',
        
        [string]
        
        $Name = '*'
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $httpProtocol = Get-CIisConfigurationSection -SiteName $SiteName `
                                                -VirtualPath $VirtualPath `
                                                -SectionPath 'system.webServer/httpProtocol'
    $httpProtocol.GetCollection('customHeaders') |
        Where-Object { $_['name'] -like $Name } |
        ForEach-Object { New-Object Carbon.Iis.HttpHeader $_['name'],$_['value'] }
}

