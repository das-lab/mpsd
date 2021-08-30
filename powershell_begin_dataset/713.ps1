


function Out-RsRestFolderContent
{
    

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string]
        $RsFolder,

        [ValidateScript({ Test-Path $_ -PathType Container})]
        [Parameter(Mandatory = $True)]
        [string]
        $Destination,

        [Switch]
        $Recurse,

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
        $catalogItemsByPathApiV1 = $ReportPortalUri + "api/v1.0/CatalogItemByPath(path=@path)?@path=%27{0}%27"
        $folderCatalogItemsApiV1 = $ReportPortalUri + "api/v1.0/CatalogItems({0})/Model.Folder/CatalogItems"
        $folderCatalogItemsApiLatest = $ReportPortalUri + "api/$RestApiVersion/Folders(Path='{0}')/CatalogItems?`$expand=Properties"
    }
    Process
    {
        if ($RestApiVersion -eq 'v1.0')
        {
            try
            {
                Write-Verbose "Fetching $RsFolder info from server..."
                $url = [string]::Format($catalogItemsByPathApiV1, $RsFolder)
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
                throw (New-Object System.Exception("Error while trying to fetch $RsFolder info! Exception: $($_.Exception.Message)", $_.Exception))
            }

            $folder = ConvertFrom-Json $response.Content

            try
            {
                Write-Verbose "Fetching catalog items under $RsFolder from server..."
                $url = [string]::Format($folderCatalogItemsApiV1, $folder.Id)
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
                throw (New-Object System.Exception("Error while trying to fetch catalog items under $RsFolder! Exception: $($_.Exception.Message)", $_.Exception))
            }
        }
        else
        {
            try
            {
                Write-Verbose "Fetching catalog items under $RsFolder from server..."
                $url = [string]::Format($folderCatalogItemsApiLatest, $RsFolder)
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
                throw (New-Object System.Exception("Error while trying to fetch catalog items under $RsFolder! Exception: $($_.Exception.Message)", $_.Exception))
            }
        }

        $catalogItems = (ConvertFrom-Json $response.Content).value
        foreach ($catalogItem in $catalogItems)
        {
            if ($catalogItem.Type -eq "Folder")
            {
                if ($Recurse)
                {
                    
                    $subFolderPath = "$Destination\$($catalogItem.Name)"
                    Write-Verbose "Creating folder $($catalogItem.Name)..."
                    New-Item -Path $subFolderPath -ItemType Directory | Out-Null

                    
                    Out-RsRestFolderContent -RsFolder $catalogItem.Path -Destination $subFolderPath -ReportPortalUri $ReportPortalUri -RestApiVersion $RestApiVersion -Credential $Credential -WebSession $WebSession -Recurse
                }
            }
            else
            {
                Write-Verbose "Parsing metadata for $($catalogItem.Name)..."
                Out-RsRestCatalogItemId -RsItemInfo $catalogItem -Destination $Destination -ReportPortalUri $ReportPortalUri -RestApiVersion $RestApiVersion -Credential $Credential -WebSession $WebSession
            }
        }
    }
}
