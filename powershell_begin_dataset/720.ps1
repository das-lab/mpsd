


function Get-RsItemDataSource
{
    

    [cmdletbinding()]
    param
    (
        [Alias('ItemPath', 'DataSourcePath', 'Path')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string]
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
        try
        {
            Write-Verbose "Retrieving data sources associated to $RsItem..."
            $Proxy.GetItemDataSources($RsItem)
            Write-Verbose "Data source retrieved successfully!"
        }
        catch
        {
            throw (New-Object System.Exception("Exception while retrieving datasource! $($_.Exception.Message)", $_.Exception))
        }
    }
}