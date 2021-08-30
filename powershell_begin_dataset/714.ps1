


function Set-RsRestItemDataSource
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $True)]
        [Alias('ItemPath','Path')]
        [string]
        $RsItem,

        [Parameter(Mandatory = $True)]
        [ValidateSet("PowerBIReport", "Report")]
        [string]
        $RsItemType,

        [Parameter(Mandatory = $True)]
        $DataSources,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v2.0")]
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
        $dataSourcesUri = $ReportPortalUri + "api/$RestApiVersion/{0}(Path='{1}')/DataSources"
    }
    Process
    {
        try
        {
            
            foreach ($ds in $DataSources)
            {
                if ($ds.DataSourceSubType -eq 'DataModel')
                {
                    
                    if ($ds.DataModelDataSource.AuthType -eq $null)
                    {
                        throw "DataModelDataSource.AuthType must be specified: $ds!"
                    }
                    elseif (($ds.DataModelDataSource.AuthType -LIKE 'Windows' -or
                            $ds.DataModelDataSource.AuthType -LIKE 'UsernamePassword' -or
                            $ds.DataModelDataSource.AuthType -LIKE 'Impersonate') -and
                            ($ds.DataModelDataSource.Username -eq $null -or
                            $ds.DataModelDataSource.Secret -eq $null))
                    {
                        
                        throw "Username and Secret must be specified for this AuthType: $ds!"
                    }
                    elseif ($ds.DataModelDataSource.AuthType -LIKE 'Key' -and
                            $ds.DataModelDataSource.Secret -eq $null)
                    {
                        
                        throw "Secret must be specified for this AuthType: $ds!"
                    }
                }
                elseif ($ds.DataSourceSubType -eq $null)
                {
                    
                    if ($ds.DataSourceType -eq $null -or
                        $ds.ConnectionString -eq $null -or
                        $ds.CredentialRetrieval -eq $null -or
                        !($ds.CredentialRetrieval -LIKE 'Integrated' -or
                        $ds.CredentialRetrieval -LIKE 'Store' -or
                        $ds.CredentialRetrieval -LIKE 'Prompt' -or
                        $ds.CredentialRetrieval -LIKE 'None'))
                    {
                        throw "Invalid data source specified: $ds!"
                    }
                    elseif ($ds.DataModelDataSource -ne $null)
                    {
                        
                        
                        throw "You cannot specify DataModelDataSource for this datasource: $ds!"
                    }

                    if ($ds.CredentialRetrieval -LIKE 'Store' -and $ds.CredentialsInServer -eq $null)
                    {
                        
                        throw "CredentialsInServer must be specified when CredentialRetrieval is set to Store: $ds!"
                    }
                    elseif ($ds.CredentialRetrieval -LIKE 'Prompt' -and $ds.CredentialsByUser -eq $null)
                    {
                        
                        throw "CredentialsByUser must be specified when CredentialRetrieval is set to Prompt: $ds!"
                    }
                }
                else
                {
                    throw "Unexpected data source subtype!"
                }
            }
            

            $dataSourcesUri = [String]::Format($dataSourcesUri, $RsItemType + "s", $RsItem)

            
            
            
            $dataSourcesArray = @($DataSources)

            
            
            $payloadJson = ConvertTo-Json -InputObject $dataSourcesArray -Depth 3

            if ($RsItemType -eq "DataSet" -or $RsItemType -eq "Report")
            {
                $method = "PUT"
            }
            elseif ($RsItemType -eq "PowerBIReport")
            {
                $method = "PATCH"
            }
            else
            {
                throw "Invalid item type!"
            }

            if ($PSCmdlet.ShouldProcess($RsItem, "Update data sources"))
            {
                Write-Verbose "Updating data sources for $($RsItem)..."
                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $dataSourcesUri -Method $method -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -WebSession $WebSession -Credential $Credential -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $dataSourcesUri -Method $method -Body ([System.Text.Encoding]::UTF8.GetBytes($payloadJson)) -ContentType "application/json" -WebSession $WebSession -UseDefaultCredentials -Verbose:$false | Out-Null
                }
                Write-Verbose "Data sources were updated successfully!"
            }
        }
        catch
        {
            throw (New-Object System.Exception("Failed to update data sources for '$RsItem': $($_.Exception.Message)", $_.Exception))
        }
    }
}