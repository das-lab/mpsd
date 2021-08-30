



function Set-RsDataSource
{
    
    
    [cmdletbinding()]
    param
    (
        [Alias('DataSourcePath','ItemPath', 'Path')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsItem,
        
        [Parameter(Mandatory = $True)]
        $DataSourceDefinition,

        [string]
        $Description,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    if ($PSCmdlet.ShouldProcess($RsItem, "Applying new definition"))
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
        
        if ($DataSourceDefinition.GetType().Name -ne 'DataSourceDefinition')
        {
            throw 'Invalid object specified for DataSourceDefinition!'
        }
        
        if ($DataSourceDefinition.CredentialRetrieval -like 'STORE')
        {
            if (-not ($DataSourceDefinition.UserName))
            {
                throw "Username and password must be specified when CredentialRetrieval is set to Store!"
            }
        }
        else
        {
            if ($DataSourceDefinition.UserName -or $DataSourceDefinition.Password)
            {
                throw "Username and/or password can be specified only when CredentialRetrieval is Store!"
            }
            
            if ($DataSourceDefinition.ImpersonateUser)
            {
                throw "ImpersonateUser can be set to true only when CredentialRetrieval is Store!"
            }
        }
        
        
        
        Write-Verbose "Retrieving data extensions..."
        try
        {
            Write-Verbose "Validating data extension..."
            if ($Proxy.ListExtensions("Data").Name -notcontains $DataSourceDefinition.Extension)
            {
                throw "Extension specified is not supported by the report server!"
            }
        }
        catch
        {
            throw (New-Object System.Exception("Failed to retrieve list of supported extensions from Report Server: $($_.Exception.Message)", $_.Exception))
        }
        
        
        try
        {
            if ($Description)
            {
                Write-Verbose "Retrieving existing data source description..."
                $properties = $Proxy.GetProperties($RsItem, $null)
                $descriptionProperty = $properties | Where { $_.Name -eq 'Description' }
                if (!$descriptionProperty)
                {
                    $namespace = $proxy.GetType().Namespace
                    $propertyDataType = "$namespace.Property"
                    $descriptionProperty = New-Object $propertyDataType
                    $descriptionProperty.Name = 'Description'
                    $descriptionProperty.Value = $Description
                    $properties.Add($descriptionProperty)
                }
                else
                {
                    $descriptionProperty.Value = $Description
                }

                Write-Verbose "Updating data source description..."
                $Proxy.SetProperties($RsItem, $descriptionProperty)
            }
            
            Write-Verbose "Updating data source contents..."
            $Proxy.SetDataSourceContents($RsItem, $DataSourceDefinition)
            Write-Verbose "Data source updated successfully!"
        }
        catch
        {
            throw (New-Object System.Exception("Exception occurred while updating data source! $($_.Exception.Message)", $_.Exception))
        }
    }
}
