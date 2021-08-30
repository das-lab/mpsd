



function Out-RsFolderContent
{
    
    [CmdletBinding()]
    param(
        [switch]
        $Recurse,
        
        [Alias('ItemPath', 'Path')]
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,
        
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [Parameter(Mandatory = $True)]
        [string]
        $Destination,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    
    $GetRsFolderContentParam = @{
        Proxy = $Proxy
        RsFolder = $RsFolder
        Recurse = $Recurse
        ErrorAction = 'Stop'
    }
    
    try
    {
        $items = Get-RsFolderContent @GetRsFolderContentParam
    }
    catch
    {
        throw (New-Object System.Exception("Failed to retrieve items in '$RsFolder': $($_.Exception.Message)", $_.Exception))
    }
    
    $Destination = Convert-Path $Destination

    foreach ($item in $items)
    {
        if (($item.TypeName -eq 'Folder') -and $Recurse)
        {
            $relativePath = $item.Path
            if($RsFolder -ne "/")
            {
                $relativePath = Clear-Substring -string $relativePath -substring $RsFolder -position front
            }
            $relativePath = $relativePath.Replace("/", "\")
            
            $newFolder = $Destination + $relativePath
            Write-Verbose "Creating folder $newFolder"
            New-Item $newFolder -ItemType Directory -Force | Out-Null
            Write-Verbose "Folder: $newFolder was created successfully."
        }
        
        if ($item.TypeName -eq "Resource" -or 
            $item.TypeName -eq "Report" -or 
            $item.TypeName -eq "DataSource" -or 
            $item.TypeName -eq "DataSet")
        {
            
            
            $relativePath = $item.Path
            if($RsFolder -ne "/")
            {
                $relativePath = Clear-Substring -string $relativePath -substring $RsFolder -position front
            }
            $relativePath = Clear-Substring -string $relativePath -substring ("/" + $item.Name) -position back
            $relativePath = $relativePath.replace("/", "\")

            $folder = $Destination + $relativePath
            Out-RsCatalogItem -proxy $proxy -RsFolder $item.Path -Destination $folder
        }
    }
}
