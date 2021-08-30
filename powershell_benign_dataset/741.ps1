



function Write-RsFolderContent
{
    
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [switch]
        $Recurse,

        [Parameter(Mandatory = $True)]
        [string]
        $Path,

        [Alias('DestinationFolder')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [Alias('Override')]
        [switch]
        $Overwrite,

        [string]
        $ReportServerUri,

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy
    )

    if ($PSCmdlet.ShouldProcess($Path, "Upload all contents in folder $(if ($Recurse) { "and subfolders " })to $RsFolder"))
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

        if(-not (Test-Path $Path -PathType Container))
        {
            throw "$Path is not a folder"
        }
        $sourceFolder = Get-Item $Path

        if ($Recurse)
        {
            $items = Get-ChildItem $Path -Recurse
        }
        else
        {
            $items = Get-ChildItem $Path
        }
        foreach ($item in $items)
        {
            if (($item.PSIsContainer) -and $Recurse)
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
                
                $itemToUpload = ("$parentFolder/$($item.Name)") -replace "//", "/"
                try
                {
                    if ($Proxy.GetItemType($itemToUpload) -ne "Folder" )
                    {
                        Write-Verbose "Creating folder $itemToUpload"
                        $Proxy.CreateFolder($item.Name, $parentFolder, $null) | Out-Null
                    }
                    else
                    {
                        Write-Verbose "Folder already exists $parentFolder/$($item.Name)"
                    }
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to create folder '$($item.Name)' in '$parentFolder': $($_.Exception.Message)", $_.Exception))
                }
            }

            if ($item.Extension -eq ".rdl" -or
                $item.Extension -eq ".rsds" -or
                $item.Extension -eq ".rsd" -or
                $item.Extension -eq ".rds" -or
                $item.Extension -eq ".jpg" -or
                $item.Extension -eq ".jpeg" -or
                $item.Extension -eq ".png" )
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
                    Write-RsCatalogItem -proxy $Proxy -Path $item.FullName -RsFolder $parentFolder -Overwrite:$Overwrite -ErrorAction Stop
                }
                catch
                {
                    throw (New-Object System.Exception("Failed to create catalog item from '$($item.FullName)' in '$parentFolder': $($_.Exception)", $_.Exception))
                }
            }
        }
    }
}
