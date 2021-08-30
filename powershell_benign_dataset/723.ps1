


function Get-RsFolderContent
{
    
    
    [cmdletbinding()]
    param(
        [Alias('ItemPath', 'Path')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $RsFolder,
        
        [switch]
        $Recurse,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }
    
    Process
    {
        foreach ($item in $RsFolder)
        {
            try
            {
                $Proxy.ListChildren($Item, $Recurse)
            }
            catch
            {
                throw
            }
        }
    }
}
New-Alias -Name "Get-RsCatalogItems" -Value Get-RsFolderContent -Scope Global
New-Alias -Name "Get-RsChildItem" -Value Get-RsFolderContent -Scope Global
New-Alias -Name "rsdir" -Value Get-RsFolderContent -Scope Global
