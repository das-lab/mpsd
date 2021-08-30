


function Remove-RsCatalogItem
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Alias('ItemPath', 'Path', 'RsFolder')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [ System.Object[] ]
        $RsItem,

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
        foreach ($item in $RsItem)
        {
            if ($PSCmdlet.ShouldProcess($item, "Delete the catalog item"))
            {
                try
                {
                    Write-Verbose "Deleting catalog item $item..."
                    if( $item -is [string] )
                    {
                        $Proxy.DeleteItem($item)
                    } 
                    else
                    {
                        $Proxy.DeleteItem($item.path)
                    }
                    Write-Verbose "Catalog item deleted successfully!"
                    
                }
                catch
                {
                    throw (New-Object System.Exception("Exception occurred while deleting catalog item '$item'! $($_.Exception.Message)", $_.Exception))
                }
            }
        }
    }
}
