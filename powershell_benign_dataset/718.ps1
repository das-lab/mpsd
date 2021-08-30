



function Set-RsDataSourceReference
{
    
    [CmdletBinding()]
    param (
        [Alias('ItemPath')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] 
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $DataSourceName,

        [Parameter(Mandatory = $true)]
        [string]
        $DataSourcePath,
        
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
        foreach ($item in $Path)
        {
            
            $dataSets = $null
            $dataSourceReference = $null
            
            try
            {
                $dataSets = $Proxy.GetItemReferences($item, "DataSource")
            }
            catch
            {
                throw (New-Object System.Exception("Failed to retrieve datasource item references for '$item': $($_.Exception.Message)", $_.Exception))
            }
            $dataSourceReference = $dataSets | Where-Object { $_.Name -eq $DataSourceName } | Select-Object -First 1
            
            if (-not $dataSourceReference)
            {
                throw "$item does not contain a dataSource reference with name $DataSourceName"
            }
            
            $proxyNamespace = $dataSourceReference.GetType().Namespace
            $dataSourceReference = New-Object "$($proxyNamespace).ItemReference"
            $dataSourceReference.Name = $DataSourceName
            $dataSourceReference.Reference = $DataSourcePath
            
            Write-Verbose "Set dataSource reference '$DataSourceName' of item $item to $DataSourcePath"
            try
            {
                $Proxy.SetItemReferences($item, @($dataSourceReference))
            }
            catch
            {
                throw (New-Object System.Exception("Failed to update datasource item references for '$item': $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}

New-Alias -Name "Set-RsSharedDataSource" -Value Set-RsDataSourceReference -Scope Global
