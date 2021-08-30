


function Write-RsRestCatalogItem
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,

        [Alias('DestinationFolder')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [string]
        $Description,

        [Alias('Override')]
        [switch]
        $Overwrite,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v1.0", "v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
        $catalogItemsUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems"
        if ($RestApiVersion -eq "v1.0")
        {
            $catalogItemsByPathApi = $ReportPortalUri + "api/$RestApiVersion/CatalogItemByPath(path=@path)?@path=%27{0}%27"
        }
        else
        {
            $catalogItemsByPathApi = $ReportPortalUri + "api/$RestApiVersion/CatalogItems(Path='{0}')"
        }
        $catalogItemsUpdateUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems({0})"
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

            if ($itemType -eq "Resource" -or $itemType -eq "ExcelWorkbook")
            {
                
                $itemName = $item.Name
            }
            else
            {
                $itemName = $item.BaseName
            }

            $itemPath = ""
            if ($RsFolder -eq "/")
            {
                $itemPath = "/$itemName"
            }
            else
            {
                $itemPath = "$RsFolder/$itemName"
            }

            Write-Verbose "Reading file $item content..."
            if ($itemType -eq 'DataSource')
            {
                [xml] $dataSourceXml = Get-Content -Path $EntirePath
                if ($item.Extension -eq '.rsds')
                {
                    if ($dataSourceXml -eq $null -or
                        $dataSourceXml.DataSourceDefinition -eq $null -or
                        $dataSourceXml.DataSourceDefinition.Extension -eq $null -or
                        $dataSourceXml.DataSourceDefinition.ConnectString -eq $null)
                    {
                        throw 'Invalid data source file!'
                    }

                    $connectionString = $dataSourceXml.DataSourceDefinition.ConnectString
                    $dataSourceType = $dataSourceXml.DataSourceDefinition.Extension
                    $credentialRetrieval = "none"
                    $enabled = "true" -like $content.DataSourceDefinition.Enabled
                }
                elseif ($item.Extension -eq '.rds')
                {
                    if ($dataSourceXml -eq $null -or
                        $dataSourceXml.RptDataSource -eq $null -or
                        $dataSourceXml.RptDataSource.Name -eq $null -or
                        $dataSourceXml.RptDataSource.ConnectionProperties -eq $null -or
                        $dataSourceXml.RptDataSource.ConnectionProperties.ConnectString -eq $null -or
                        $dataSourceXml.RptDataSource.ConnectionProperties.Extension -eq $null)
                    {
                        throw 'Invalid data source file!'
                    }

                    $itemName = $dataSourceXml.RptDataSource.Name
                    $itemPath = $itemPath.Substring(0, $itemPath.LastIndexOf('/') + 1) + $itemName
                    $enabled = $true
                    $connectionProperties = $dataSourceXml.RptDataSource.ConnectionProperties
                    $connectionString = $connectionProperties.ConnectString
                    $dataSourceType = $connectionProperties.Extension
                    $credentialRetrieval = "none"
                    if ($connectionProperties.Prompt -ne $null)
                    {
                        $credentialRetrieval = "prompt"
                        $prompt = $connectionProperties.Prompt
                    }
                    elseif ($connectionProperties.IntegratedSecurity -eq $true)
                    {
                        $credentialRetrieval = "integrated"
                    }
                }

                $payload = @{
                    "@odata.type" = "
                    "Path" = $itemPath;
                    "Name" = $itemName;
                    "Description" = "";
                    "DataSourceType" = $dataSourceType;
                    "ConnectionString" = $connectionString;
                    "CredentialRetrieval" = $credentialRetrieval;
                    "CredentialsByUser" = $null;
                    "CredentialsInServer" = $null;
                    "Hidden" = $false;
                    "IsConnectionStringOverridden" = $true;
                    "IsEnabled" = $enabled;
                }

                if ($credentialRetrieval -eq "Prompt")
                {
                    $payload["CredentialsByUser"] = @{
                        "DisplayText" = $prompt;
                        "UseAsWindowsCredentials" = $true;
                    }
                }
            }
            elseif ($itemType -eq "Kpi")
            {
                $content = [System.IO.File]::ReadAllText($EntirePath)
                $payload = ConvertFrom-Json $content
                $payload.Path = $itemPath
            }
            else
            {
                $bytes = [System.IO.File]::ReadAllBytes($EntirePath)
                $payload = @{
                    "@odata.type" = "
                    "Content" = [System.Convert]::ToBase64String($bytes);
                    "ContentType"="";
                    "Name" = $itemName;
                    "Description" = $Description
                    "Path" = $itemPath;
                }
            }

            try
            {
                Write-Verbose "Uploading $EntirePath to $RsFolder..."

                $payloadJson = ConvertTo-Json $payload

                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $catalogItemsUri -Method Post -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -Credential $Credential -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $catalogItemsUri -Method Post -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -UseDefaultCredentials -Verbose:$false | Out-Null
                }

                Write-Verbose "$EntirePath was uploaded to $RsFolder successfully!"
            }
            catch
            {
                if ($_.Exception.Response -ne $null -and $_.Exception.Response.StatusCode -eq 409 -and $Overwrite)
                {
                    try
                    {
                        Write-Verbose "$itemName already exists at $RsFolder. Retrieving id in order to overwrite it..."
                        $uri = [String]::Format($catalogItemsByPathApi, $itemPath)
                        if ($Credential -ne $null)
                        {
                            $response = Invoke-WebRequest -Uri $uri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
                        }
                        else
                        {
                            $response = Invoke-WebRequest -Uri $uri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
                        }

                        
                        $itemInfo = ConvertFrom-Json $response.Content
                        $itemId = $itemInfo.Id

                        Write-Verbose "Overwriting $itemName at $itemPath..."
                        $uri = [String]::Format($catalogItemsUpdateUri, $itemId)
                        if ($Credential -ne $null)
                        {
                            Invoke-WebRequest -Uri $uri -Method Put -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -Credential $Credential -Verbose:$false | Out-Null
                        }
                        else
                        {
                            Invoke-WebRequest -Uri $uri -Method Put -WebSession $WebSession -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -UseDefaultCredentials -Verbose:$false | Out-Null
                        }
                        Write-Verbose "$EntirePath was uploaded to $RsFolder successfully!"
                    }
                    catch
                    {
                        Write-Error (New-Object System.Exception("Failed to create catalog item: $($_.Exception.Message)", $_.Exception))
                    }
                }
                else
                {
                    Write-Error (New-Object System.Exception("Failed to create catalog item: $($_.Exception.Message)", $_.Exception))
                }
            }
        }
    }
}
