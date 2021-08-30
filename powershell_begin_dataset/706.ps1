


function Out-RsRestCatalogItem
{
    

    [CmdletBinding()]
    param (
        [Alias('RsFolder')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $RsItem,

        [ValidateScript({ Test-Path $_ -PathType Container})]
        [Parameter(Mandatory = $True)]
        [string]
        $Destination,

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
        if ($RestApiVersion -eq 'v1.0')
        {
            $catalogItemsByPathApi = $ReportPortalUri + "api/$RestApiVersion/CatalogItemByPath(path=@path)?@path=%27{0}%27"
        }
        else
        {
            $catalogItemsByPathApi = $ReportPortalUri + "api/$RestApiVersion/CatalogItems(Path='{0}')?`$expand=properties"
        }
    }
    Process
    {
        foreach ($item in $RsItem)
        {
            try
            {
                Write-Verbose "Fetching metadata for $item from server..."
                $url = [string]::Format($catalogItemsByPathApi, $item)
                if ($Credential -ne $null)
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -Credential $Credential -Verbose:$false
                }
                else
                {
                    $response = Invoke-WebRequest -Uri $url -Method Get -UseDefaultCredentials -Verbose:$false
                }
            }
            catch
            {
                throw (New-Object System.Exception("Error while trying to fetch metadata for $item! Exception: $($_.Exception.Message)", $_.Exception))
            }

            Write-Verbose "Parsing metadata for $item..."
            $itemInfo = ConvertFrom-Json $response.Content

            Out-RsRestCatalogItemId -RsItemInfo $itemInfo -Destination $Destination -RestApiVersion $RestApiVersion -ReportPortalUri $ReportPortalUri -Credential $Credential -WebSession $WebSession -Overwrite:$Overwrite
        }
    }
}