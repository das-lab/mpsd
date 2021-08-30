


function Out-RsRestCatalogItemId
{
    

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        $RsItemInfo,

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
        $catalogItemContentApi = $ReportPortalUri + "api/$RestApiVersion/CatalogItems({0})/Content/`$value"
        $DestinationFullPath = Convert-Path $Destination

        
        if ($RsItemInfo.Id -eq $null -or
            $RsItemInfo.Name -eq $null -or
            $RsItemInfo.Type -eq $null)
        {
            throw "Invalid object specified for parameter: RsItemInfo!"
        }
    }

    Process
    {
        if ($RsItemInfo.Type -ne 'MobileReport')
        {
            $itemId = $RsItemInfo.Id
            $fileName = $RsItemInfo.Name + (Get-FileExtension -TypeName $RsItemInfo.Type)
        }
        else
        {
            $packageIdProperty = $RsItemInfo.Properties | Where-Object { $_.Name -eq 'PackageId' }
            if ($packageIdProperty -ne $null)
            {
                $itemId = $packageIdProperty.Value
            }
            else
            {
                throw "Unable to determine Id for $($RsItemInfo.Name)!"
            }

            $packageNameProperty = $RsItemInfo.Properties | Where-Object { $_.Name -eq 'PackageName' }
            if ($packageNameProperty -ne $null)
            {
                $fileName = $packageNameProperty.Value
            }
            else
            {
                $fileName = $RsItemInfo.Name + '.rsmobile'
            }
        }

        $destinationFilePath = Join-Path -Path $DestinationFullPath -ChildPath $fileName
        if ((Test-Path $destinationFilePath) -And !$Overwrite)
        {
            throw "An item with same name already exists at destination!"
        }

        if ($RsItemInfo.Type -eq 'Kpi')
        {
            $itemContent = $RsItemInfo | Select-Object -Property Data, Description, DrillthroughTarget, Hidden, IsFavorite, Name, "@odata.Type", Path, Type, ValueFormat, Values, Visualization
            Write-Verbose "Writing content to $destinationFilePath..."
            [System.IO.File]::WriteAllText($destinationFilePath, (ConvertTo-Json $itemContent))
            Write-Verbose "$($RsItemInfo.Path) was downloaded to $destinationFilePath successfully!"
            return
        }

        try
        {
            Write-Verbose "Downloading item content from server..."
            $url = [string]::Format($catalogItemContentApi, $itemId)
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
            throw (New-Object System.Exception("Error while downloading $($RsItemInfo.Name)! Exception: $($_.Exception.Message)", $_.Exception))
        }

        Write-Verbose "Writing content to $destinationFilePath..."
        [System.IO.File]::WriteAllBytes($destinationFilePath, $response.Content)
        Write-Verbose "$($RsItemInfo.Path) was downloaded to $destinationFilePath successfully!"
    }
}

