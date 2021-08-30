



function Out-RsCatalogItem
{
    
    [CmdletBinding()]
    param (
        [Alias('ItemPath', 'Path', 'RsFolder')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [string[]]
        $RsItem,
        
        [ValidateScript({ Test-Path $_ -PathType Container})]
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
    
    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
        $DestinationFullPath = Convert-Path $Destination
    }
    
    Process
    {
        
        foreach ($item in $RsItem)
        {
            
            try
            {
                $itemType = $Proxy.GetItemType($item)
            }
            catch
            {
                throw (New-Object System.Exception("Failed to retrieve item type of '$item' from proxy: $($_.Exception.Message)", $_.Exception))
            }
            
            switch ($itemType)
            {
                "Unknown"
                {
                    throw "Make sure item exists at $item and item is of type Report, DataSet, DataSource or Resource"
                }
                "Resource"
                {
                    $fileName = ($item.Split("/"))[-1]
                }
                default
                {
                    $fileName = "$(($item.Split("/"))[-1])$(Get-FileExtension -TypeName $itemType)"
                }
            }
            
            Write-Verbose "Downloading $item..."
            try
            {
                $bytes = $Proxy.GetItemDefinition($item)
            }
            catch
            {
                throw (New-Object System.Exception("Failed to retrieve item definition of '$item' from proxy: $($_.Exception.Message)", $_.Exception))
            }
            
            
            
            Write-Verbose "Writing $itemType content to $DestinationFullPath\$fileName..."
            try
            {
                if ($itemType -eq 'DataSource')
                {
                    $content = [System.Text.Encoding]::Unicode.GetString($bytes)
                    [System.IO.File]::WriteAllText("$DestinationFullPath\$fileName", $content)
                }
                else
                {
                    [System.IO.File]::WriteAllBytes("$DestinationFullPath\$fileName", $bytes)
                }
            }
            catch
            {
                throw (New-Object System.IO.IOException("Failed to write content to '$DestinationFullPath\$fileName' : $($_.Exception.Message)", $_.Exception))
            }
            
            Write-Verbose "$item was downloaded to $DestinationFullPath\$fileName successfully!"
            
        }
        
    }
    
    End
    {
        
    }
}
