



function Write-RsCatalogItem
{
    
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,

        [Alias('DestinationFolder')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [string]
        $Name,

        [string]
        $Description,

        [Alias('Override')]
        [switch]
        $Overwrite,

        [switch]
        $Hidden,

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
        $namespace = $proxy.GetType().Namespace
        $propertyDataType = "$namespace.Property"
    }

    Process
    {
        foreach ($item in $Path)
        {
            
            if (!(Test-Path $item))
            {
                throw "No item found at the specified path: $item!"
            }

            $EntirePath = Convert-Path $item
            $item = Get-Item $EntirePath
            $itemType = Get-ItemType $item.Extension
            if ([string]::IsNullOrEmpty($Name))
            {
                $itemName = $item.BaseName
            }
            else
            {
                $itemName = $Name
            }

            if (
                (
                    $itemType -ne "Report" -and
                    $itemType -ne "DataSource" -and
                    $itemType -ne "DataSet" -and
                    $itemType -ne "Resource"
                ) -or
                (
                    $itemType -eq "Resource" -and
                    $item.Extension -notin ('.png', '.jpg', '.jpeg')
                )
            )
            {
                throw "Invalid item specified! You can only upload Report, DataSource, DataSet and jpg/png files using this command!"
            }

            if ($RsFolder -eq "/")
            {
                Write-Verbose "Uploading $EntirePath to /$($itemName)"
            }
            else
            {
                Write-Verbose "Uploading $EntirePath to $RsFolder/$($itemName)"
            }
            

            if ($PSCmdlet.ShouldProcess("$itemName", "Upload from $EntirePath to Report Server at $RsFolder"))
            {
                
                if ($itemType -eq 'DataSource')
                {
                    try
                    {
                        [xml]$content = Get-Content -Path $EntirePath -ErrorAction Stop
                    }
                    catch
                    {
                        throw (New-Object System.Exception("Failed to access XML content of '$EntirePath': $($_.Exception.Message)", $_.Exception))
                    }

                    if ($item.Extension -eq '.rsds')
                    {
                        if ($content.DataSourceDefinition -eq $null)
                        {
                            throw "Data Source Definition not found in the specified file: $EntirePath!"
                        }
    
                        $NewRsDataSourceParam = @{
                            Proxy = $Proxy
                            RsFolder = $RsFolder
                            Name = $itemName
                            Extension = $content.DataSourceDefinition.Extension
                            ConnectionString = $content.DataSourceDefinition.ConnectString
                            Disabled = ("false" -like $content.DataSourceDefinition.Enabled)
                            CredentialRetrieval = 'None'
                            Overwrite = $Overwrite
                        }
                    }
                    elseif ($item.Extension -eq '.rds')
                    {
                        if ($content -eq $null -or 
                            $content.RptDataSource -eq $null -or
                            $content.RptDataSource.Name -eq $null -or
                            $content.RptDataSource.ConnectionProperties -eq $null -or
                            $content.RptDataSource.ConnectionProperties.ConnectString -eq $null -or
                            $content.RptDataSource.ConnectionProperties.Extension -eq $null)
                        {
                            throw 'Invalid data source file!'
                        }

                        $connectionProperties = $content.RptDataSource.ConnectionProperties
                        $credentialRetrieval = "None"
                        if ($connectionProperties.Prompt -ne $null)
                        {
                            $credentialRetrieval = "Prompt"
                            $prompt = $connectionProperties.Prompt
                        }
                        elseif ($connectionProperties.IntegratedSecurity -eq $true)
                        {
                            $credentialRetrieval = "Integrated"
                        }
                        $NewRsDataSourceParam = @{
                            Proxy = $Proxy
                            RsFolder = $RsFolder
                            Name = $content.RptDataSource.Name
                            Extension = $connectionProperties.Extension
                            ConnectionString = $connectionProperties.ConnectString
                            Disabled = $false
                            CredentialRetrieval = $credentialRetrieval
                            Overwrite = $Overwrite
                        }

                        if ($credentialRetrieval -eq "prompt")
                        {
                            $NewRsDataSourceParam.Add("Prompt", $prompt)
                            $NewRsDataSourceParam.Add("WindowsCredentials", $true)
                        }
                    }
                    else
                    {
                        throw 'Invalid data source file specified!'
                    }

                    New-RsDataSource @NewRsDataSourceParam
                }
                

                
                else
                {
                    $additionalProperties = New-Object System.Collections.Generic.List[$propertyDataType]
                    $property = New-Object $propertyDataType

                    if ($itemType -eq 'Resource')
                    {
                        
                        $itemName = $item.Name
                        $property.Name = 'MimeType'
                        if ($item.Extension -eq ".png")
                        {
                            $property.Value = 'image/png'
                        }
                        else
                        {
                            $property.Value = 'image/jpeg'
                        }
                        $errorMessageItemType = 'resource'
                    }
                    else
                    {
                        $property.Name = 'Description'
                        $property.Value = $Description
                        $errorMessageItemType = 'catalog'
                    }

                    $additionalProperties.Add($property)

                    if ($Hidden)
                    {
                        $hiddenProperty = New-Object $propertyDataType
                        $hiddenProperty.Name = 'Hidden'
                        $hiddenProperty.Value = $Hidden
                        $additionalProperties.Add($hiddenProperty)
                    }
                
                    $bytes = [System.IO.File]::ReadAllBytes($EntirePath)
                    $warnings = $null
                    try
                    {
                        $Proxy.CreateCatalogItem($itemType, $itemName, $RsFolder, $Overwrite, $bytes, $additionalProperties, [ref]$warnings) | Out-Null
                        if ($warnings)
                        {
                            foreach ($warn in $warnings)
                            {
                                Write-Warning $warn.Message
                            }
                        }
                    }
                    catch
                    {
                        throw (New-Object System.Exception("Failed to create $errorMessageItemType item $($item.FullName) : $($_.Exception.Message)", $_.Exception))
                    }
                }
                

                Write-Verbose "$EntirePath was uploaded to $RsFolder successfully!"
            }
        }
    }
}
