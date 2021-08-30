



function DoSomeThingTo-RSCatalogItem
{
    
    
    [CmdletBinding()]
    param (
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
        
    }
    
    End
    {
        
    }
}

