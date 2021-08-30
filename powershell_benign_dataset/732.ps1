


function New-RsDataSource
{
    

    [cmdletbinding()]
    param
    (
        [Alias('Destination', 'ItemPath', 'Path')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,
        
        [Parameter(Mandatory = $True)]
        [string]
        $Name,

        [string]
        $Description,
        
        [Parameter(Mandatory = $True)]
        [string]
        $Extension,

        [string]
        $ConnectionString,
        
        [Parameter(Mandatory = $True)]
        [ValidateSet("None", "Prompt", "Integrated", "Store")]
        [string]
        $CredentialRetrieval,

        [System.Management.Automation.PSCredential]
        $DatasourceCredentials,

        [string]
        $Prompt,

        [switch]
        $ImpersonateUser,

        [switch]
        $WindowsCredentials,

        [switch]
        $Disabled,

        [Switch]
        $Overwrite,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

    if (($CredentialRetrieval -eq 'STORE') -and ($DatasourceCredentials.UserName -eq $null))
    {
        throw "Username and password (-DatasourceCredentials) must be specified when CredentialRetrieval is Store!"
    }

    
    Write-Verbose "Retrieving data extensions..."
    if ($Proxy.ListExtensions("Data").Name -notcontains $Extension)
    {
        throw "Extension specified is not supported by the report server!"
    }

    $namespace = $proxy.GetType().Namespace
    $datasourceDataType = "$namespace.DataSourceDefinition"
    $propertyDataType = "$namespace.Property"
    $credentialRetrievalEnumType = "$namespace.CredentialRetrievalEnum"

    $datasource = New-Object $datasourceDataType
    $datasource.ConnectString = $ConnectionString
    $datasource.Enabled = $true    
    $datasource.Extension = $Extension
    $datasource.WindowsCredentials = $WindowsCredentials
    $datasource.Prompt = $Prompt
    
    if ($Disabled)
    {
        $datasource.Enabled = $false
    }

    if ($CredentialRetrieval -eq 'STORE')
    {
        $datasource.UserName = $DatasourceCredentials.UserName
        $datasource.Password = $DatasourceCredentials.GetNetworkCredential().Password
        $datasource.ImpersonateUser = $ImpersonateUser
    }

    try
    {
        $datasource.CredentialRetrieval = [Enum]::Parse($credentialRetrievalEnumType, $CredentialRetrieval)
    }
    catch
    {
        throw (New-Object System.Exception("Exception occurred while converting credential retrieval to enum! $($_.Exception.Message)", $_.Exception))
    }

    $additionalProperties = New-Object System.Collections.Generic.List[$propertyDataType]
    if ($Description)
    {
        $descriptionProperty = New-Object $propertyDataType
        $descriptionProperty.Name = 'Description'
        $descriptionProperty.Value = $Description
        $additionalProperties.Add($descriptionProperty)
    }

    try
    {
        Write-Verbose "Creating data source..."
        $Proxy.CreateDataSource($Name, $RsFolder, $Overwrite, $datasource, $additionalProperties)
        Write-Verbose "Data source created successfully!"
    }
    catch
    {
       throw (New-Object System.Exception("Exception occurred while creating data source! $($_.Exception.Message)", $_.Exception))
    }
}
