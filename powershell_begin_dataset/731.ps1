


function Set-RsItemDataSource
{
    

    [cmdletbinding()]
    param
    (
        [Alias('ItemPath', 'DataSourcePath', 'Path')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string]
        $RsItem,

        [Parameter(Mandatory = $True)]
        $DataSource,
        
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
        
        foreach ($ds in $DataSource)
        {
            if ($ds.Name -eq $null -or $ds.Item -eq $null)
            {
                throw "Invalid data source specified: $ds!"
            }
            elseif ($ds.Item.Reference -ne $null)
            {
                throw "Please use Set-RsDataSource to update shared data sources!"
            }
            elseif ($ds.Item.CredentialRetrieval -like 'STORE')
            {
                if (-not ($ds.Item.UserName))
                {
                    throw "Username and password must be specified when CredentialRetrieval is set to Store!"
                }
            }
            else
            {
                if ($ds.Item.UserName -or $ds.Item.Password)
                {
                    throw "Username and/or password can be specified only when CredentialRetrieval is Store!"
                }
                
                if ($ds.Item.ImpersonateUser)
                {
                    throw "ImpersonateUser can be set to true only when CredentialRetrieval is Store!"
                }
            }
        }

        try
        {
            Write-Verbose "Updating data sources associated to $RsItem..."
            $Proxy.SetItemDataSources($RsItem, $DataSource)
            Write-Verbose "Data source updated successfully!"
        }
        catch
        {
            throw (New-Object System.Exception("Exception while updating datasources! $($_.Exception.Message)", $_.Exception))
        }
    }
}
