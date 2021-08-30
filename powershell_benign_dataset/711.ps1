


function Write-RsRestFolderContent
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $Path,

        [switch]
        $Recurse,

        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

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
        $folderUri = $ReportPortalUri + "api/$RestApiVersion/Folders(Path='{0}')"
    }
    Process
    {
        if (!(Test-Path -Path $Path -PathType Container))
        {
            throw "No folder found at $Path!"
        }
        $sourceFolder = Get-Item $Path

        if ($Recurse)
        {
            $items = Get-ChildItem -Path $Path -Recurse
        }
        else
        {
            $items = Get-ChildItem -Path $Path
        }

        foreach ($item in $items)
        {
            if (($item.PSIsContainer) -and $Recurse)
            {
                $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
                $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
                $relativePath = $relativePath.replace("\", "/")

                $folderUriPath = $null
                $folderExists = $null
                $folderInfo = $null
                if ($RsFolder -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                    $folderUriPath = "$RsFolder/$($item.name)"
                }
                else
                {
                    $parentFolder = $RsFolder + $relativePath
                    if ($RsFolder -eq "/")
                    {
                        $folderUriPath = $RsFolder + $($item.name)
                    }
                    else
                    {
                        $folderUriPath = "$RsFolder/$($item.name)"
                    }
                }

                $uri = [String]::Format($folderUri, $folderUriPath)

                try
                {
                    
                    if ($Credential -ne $null)
                    {
                        $response = Invoke-WebRequest -Uri $uri -Method Get -WebSession $WebSession -Credential $Credential -Verbose:$false
                    }
                    else
                    {
                        $response = Invoke-WebRequest -Uri $uri -Method Get -WebSession $WebSession -UseDefaultCredentials -Verbose:$false
                    }

                    
                    $folderInfo = ConvertFrom-Json $response.Content
                    if ($folderInfo.Name -eq $item.Name)
                    {
                        $folderExists = $true
                    }
                }
                catch
                {
                    
                    if ($_.Exception.Response -ne $null -and $_.Exception.Response.StatusCode -eq 404)
                    {
                        $folderExists = $false
                    }
                }

                if ($folderExists)
                {
                    Write-Verbose "Folder $($item.Name) already exits. Skipping."
                }
                else
                {
                    New-RsRestFolder -WebSession $WebSession -RestApiVersion $RestApiVersion -FolderName $item.Name -RsFolder $parentFolder | Out-Null
                }
            }

            if ($item.Extension -ne "")
            {
                $relativePath = Clear-Substring -string $item.FullName -substring $sourceFolder.FullName.TrimEnd("\") -position front
                $relativePath = Clear-Substring -string $relativePath -substring ("\" + $item.Name) -position back
                $relativePath = $relativePath.replace("\", "/")

                if ($RsFolder -eq "/" -and $relativePath -ne "")
                {
                    $parentFolder = $relativePath
                }
                else
                {
                    $parentFolder = $RsFolder + $relativePath
                }

                try
                {
                    Write-RsRestCatalogItem -WebSession $WebSession -RestApiVersion $RestApiVersion -Path $item.FullName -RsFolder $parentFolder -Overwrite:$Overwrite -Credential $Credential
                }
                catch
                {
                    Write-Error "Failed to create catalog item from '$($item.FullName)' in '$parentFolder': If the catalog item already exists (error: (409) Conflict), you can specify the -Overwrite parameter. $($_.Exception)"
                }
            }
        }
    }

}
