


function Get-RsDataSource
{
    

    [cmdletbinding()]
    param
    (
        [Alias('ItemPath', 'DataSourcePath')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        
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
        foreach ($Item in $Path)
        {
            try
            {
                Write-Verbose "Retrieving data source contents..."
                $Proxy.GetDataSourceContents($Item)
                Write-Verbose "Data source retrieved successfully!"
            }
            catch
            {
                throw (New-Object System.Exception("Exception while retrieving datasource! $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}
