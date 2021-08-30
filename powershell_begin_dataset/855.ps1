








param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory=$true)]
    [string]$ContainerName
)




$VerbosePreference = "Continue"

if((Get-Module -ListAvailable Az.Storage) -eq $null)
{
    throw "Azure Powershell not found! Please install from https://docs.microsoft.com/en-us/powershell/azure/install-Az-ps"
}


function Retry-OnRequest
{
    param(
        [Parameter(Mandatory=$true)]
        $Action)

    
    

    
    $clientTimeOut = New-TimeSpan -Minutes 15
    $retryPolicy = New-Object -TypeName Microsoft.Azure.Storage.RetryPolicies.ExponentialRetry -ArgumentList @($clientTimeOut, 10)
    $requestOption = @{}
    $requestOption.RetryPolicy = $retryPolicy

    
    $shouldRetryOnException = $false
    $maxRetryCountOnException = 3

    do
    {
        try
        {
            return $Action.Invoke($requestOption)
        }
        catch
        {
            if ($_.Exception.InnerException -ne $null -And $_.Exception.InnerException.GetType() -Eq [System.TimeoutException] -And $maxRetryCountOnException -gt 0)
            {
                $shouldRetryOnException = $true
                $maxRetryCountOnException--
            }
            else
            {
                $shouldRetryOnException = $false
                throw
            }
        }
    }
    while ($shouldRetryOnException)

}



function Get-BlobBytes
{
    param(
        [Parameter(Mandatory=$true)]
        $Blob,
        [Parameter(Mandatory=$false)]
        [bool]$IsPremiumAccount = $false)

    
    $blobSizeInBytes = 124 + $Blob.Name.Length * 2

    
    $metadataEnumerator=$Blob.ICloudBlob.Metadata.GetEnumerator()
    while($metadataEnumerator.MoveNext())
    {
        $blobSizeInBytes += 3 + $metadataEnumerator.Current.Key.Length + $metadataEnumerator.Current.Value.Length
    }

    if (!$IsPremiumAccount)
    {
        if($Blob.BlobType -eq [Microsoft.Azure.Storage.Blob.BlobType]::BlockBlob)
        {
            $blobSizeInBytes += 8
            
            $action = { param($requestOption) return $Blob.ICloudBlob.DownloadBlockList([Microsoft.Azure.Storage.Blob.BlockListingFilter]::All, $null, $requestOption) }

            $blocks=Retry-OnRequest $action

            if ($null -eq $blocks)
            {
                $blobSizeInBytes += $Blob.ICloudBlob.Properties.Length
            }
            else
            {
                $blocks | ForEach-Object { $blobSizeInBytes += $_.Length + $_.Name.Length }
            }
        }
        elseif($Blob.BlobType -eq [Microsoft.Azure.Storage.Blob.BlobType]::PageBlob)
        {
            
            
            
            $pageRangesSegSize = 148 * 1024 * 1024L
            $totalSize = $Blob.ICloudBlob.Properties.Length
            $pageRangeSegOffset = 0

            $pageRangesTemp = New-Object System.Collections.ArrayList

            while ($pageRangeSegOffset -lt $totalSize)
            {
                $action = {param($requestOption) return $Blob.ICloudBlob.GetPageRanges($pageRangeSegOffset, $pageRangesSegSize, $null, $requestOption) }

                Retry-OnRequest $action | ForEach-Object { $pageRangesTemp.Add($_) }  | Out-Null
                $pageRangeSegOffset += $pageRangesSegSize
            }

            $pageRanges = New-Object System.Collections.ArrayList

            foreach ($pageRange in $pageRangesTemp)
            {
                if($lastRange -eq $Null)
                {
                    $lastRange = New-Object PageRange
                    $lastRange.StartOffset = $pageRange.StartOffset
                    $lastRange.EndOffset =  $pageRange.EndOffset
                }
                else
                {
                    if (($lastRange.EndOffset + 1) -eq $pageRange.StartOffset)
                    {
                        $lastRange.EndOffset = $pageRange.EndOffset
                    }
                    else
                    {
                        $pageRanges.Add($lastRange)  | Out-Null
                        $lastRange = New-Object PageRange
                        $lastRange.StartOffset = $pageRange.StartOffset
                        $lastRange.EndOffset =  $pageRange.EndOffset
                    }
                }
            }

            $pageRanges.Add($lastRange) | Out-Null
            $pageRanges |  ForEach-Object {
                    $blobSizeInBytes += 12 + $_.EndOffset - $_.StartOffset
                }
        }
        else
        {
            $blobSizeInBytes += $Blob.ICloudBlob.Properties.Length
        }
        return $blobSizeInBytes
    }
    else
    {
        $blobSizeInBytes += $Blob.ICloudBlob.Properties.Length
    }
    return $blobSizeInBytes
}



function Get-ContainerBytes
{
    param(
        [Parameter(Mandatory=$true)]
        [Microsoft.Azure.Storage.Blob.CloudBlobContainer]$Container,
        [Parameter(Mandatory=$false)]
        [bool]$IsPremiumAccount = $false)

    
    $containerSizeInBytes = 48 + $Container.Name.Length*2

    
    $metadataEnumerator = $Container.Metadata.GetEnumerator()
    while($metadataEnumerator.MoveNext())
    {
        $containerSizeInBytes += 3 + $metadataEnumerator.Current.Key.Length + $metadataEnumerator.Current.Value.Length
    }

    
    $containerSizeInBytes += $Container.GetPermissions().SharedAccessPolicies.Count * 512

    
    $blobCount = 0
    $Token = $Null
    $MaxReturn = 5000

    do {
        $Blobs = Get-AzStorageBlob -Context $storageContext -Container $Container.Name -MaxCount $MaxReturn -ContinuationToken $Token
        if($Blobs -eq $Null) { break }

        
        if($Blobs.GetType().Name -eq "AzureStorageBlob")
        {
            $Token = $Null
        }
        else
        {
            $Token = $Blobs[$Blobs.Count - 1].ContinuationToken;
        }

        $Blobs | ForEach-Object {
                $blobSize = Get-BlobBytes $_ $IsPremiumAccount
                $containerSizeInBytes += $blobSize
                $blobCount++

                if(($blobCount % 1000) -eq 0)
                {
                    Write-Verbose("Counting {0} Sizing {1} " -f $blobCount, $containerSizeInBytes)
                }
            }
    }
    While ($Token -ne $Null)

    return @{ "containerSize" = $containerSizeInBytes; "blobCount" = $blobCount }
}



$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName -ErrorAction SilentlyContinue
if($storageAccount -eq $null)
{
    throw "The storage account specified does not exist in this subscription."
}

$storageContext = $storageAccount.Context

if (-not ([System.Management.Automation.PSTypeName]'PageRange').Type)
{
    $Source = "
        public class PageRange
        {
            public long StartOffset;
            public long EndOffset;
        }"
    Add-Type -TypeDefinition $Source
}

$containers = New-Object System.Collections.ArrayList
if($ContainerName.Length -ne 0)
{
    $container = Get-AzStorageContainer -Context $storageContext -Name $ContainerName -ErrorAction SilentlyContinue |
        ForEach-Object { $containers.Add($_) } | Out-Null
}
else
{
    Get-AzStorageContainer -Context $storageContext | ForEach-Object { $containers.Add($_) } | Out-Null
}

$sizeInBytes = 0
$IsPremiumAccount = ($storageAccount.Sku.Tier -eq "Premium")

if($containers.Count -gt 0)
{
    $containers | ForEach-Object {
        Write-Output("Calculating container {0} ..." -f $_.CloudBlobContainer.Name)
        $result = Get-ContainerBytes $_.CloudBlobContainer $IsPremiumAccount
        $sizeInBytes += $result.containerSize

        Write-Output("Container '{0}' with {1} blobs has a sizeof {2:F2} MB." -f $_.CloudBlobContainer.Name,$result.blobCount,($result.containerSize/1MB))
    }
}
else
{
    Write-Warning "No containers found to process in storage account '$StorageAccountName'."
}
