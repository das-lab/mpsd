


function New-RsFolder
{
    

    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $True)]
        [Alias('ItemPath','Path')]
        [string]
        $RsFolder,

        [Parameter(Mandatory = $True)]
        [Alias('Name')]
        [string]
        $FolderName,

        [string]
        $Description,

        [switch]
        $Hidden,

        [string]
        $ReportServerUri,

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy
    )

    $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

    $namespace = $proxy.GetType().Namespace
    $propertyDataType = "$namespace.Property"
    $additionalProperties = New-Object System.Collections.Generic.List[$propertyDataType]
    if ($Description)
    {
        $descriptionProperty = New-Object $propertyDataType
        $descriptionProperty.Name = 'Description'
        $descriptionProperty.Value = $Description
        $additionalProperties.Add($descriptionProperty)
    }

    if ($Hidden)
    {
        $hiddenProperty = New-Object $propertyDataType
        $hiddenProperty.Name = 'Hidden'
        $hiddenProperty.Value = $Hidden
        $additionalProperties.Add($hiddenProperty)
    }

    try
    {
        Write-Verbose "Creating folder $($FolderName)..."
        $Proxy.CreateFolder($FolderName, $RsFolder, $additionalProperties) | Out-Null
        Write-Verbose "Folder $($FolderName) created successfully!"
    }
    catch
    {
        throw (New-Object System.Exception("Exception occurred while creating folder! $($_.Exception.Message)", $_.Exception))
    }
}