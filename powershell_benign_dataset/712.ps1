


function Get-RsRestItemDataSource
{
    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [Alias('ItemPath','Path')]
        [string]
        $RsItem,

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
        $catalogItemsUri = $ReportPortalUri + "api/$RestApiVersion/CatalogItems(Path='{0}')"
        $dataSourcesUri = $ReportPortalUri + "api/$RestApiVersion/{0}(Path='{1}')?`$expand=DataSources"
    }
    Process
    {
        try
        {
            Write-Verbose "Fetching metadata for $RsItem..."
            $catalogItemsUri = [String]::Format($catalogItemsUri, $RsItem)
            if ($Credential -ne $null)
            {
                $response = Invoke-WebRequest -Uri $catalogItemsUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-WebRequest -Uri $catalogItemsUri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }

            $item = ConvertFrom-Json $response.Content
            $itemType = $item.Type

            Write-Verbose "Fetching data sources for $RsItem..."
            $dataSourcesUri = [String]::Format($dataSourcesUri, $itemType + "s", $RsItem)

            if ($Credential -ne $null)
            {
                $response = Invoke-WebRequest -Uri $dataSourcesUri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
            }
            else
            {
                $response = Invoke-WebRequest -Uri $dataSourcesUri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
            }

            $itemWithDataSources = ConvertFrom-Json $response.Content
            return $itemWithDataSources.DataSources
        }
        catch
        {
            throw (New-Object System.Exception("Failed to get data sources for '$RsItem': $($_.Exception.Message)", $_.Exception))
        }
    }
}