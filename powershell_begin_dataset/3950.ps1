














function Get-ResourceGroupName
{
    param([string] $prefix = [string]::Empty)

	return getAssetName $prefix
}


function Get-ResourceName
{
    param([string] $prefix = [string]::Empty)

    return getAssetName $prefix
}


function Get-NetworkTestMode {
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


function Get-ProviderLocation($provider, $preferredLocation = "West Central US", $useCanonical = $null)
{
    
    if($env:AZURE_NRP_TEST_LOCATION -and $env:AZURE_NRP_TEST_LOCATION -match "^[a-z0-9\s]+$")
    {
        return $env:AZURE_NRP_TEST_LOCATION;
    }
    if($null -eq $useCanonical)
    {
        $useCanonical = -not $preferredLocation.Contains(" ");
    }
    if($useCanonical)
    {
        $preferredLocation = Normalize-Location $preferredLocation;
    }
    if($provider.Contains("/"))
    {
        $providerNamespace, $resourceType = $provider.Split("/");
        return Get-Location $providerNamespace $resourceType $preferredLocation -UseCanonical:$($useCanonical);
    }
    return $preferredLocation;
}


function Clean-ResourceGroup($rgname)
{
    if ((Get-NetworkTestMode) -ne 'Playback') {
        Remove-AzResourceGroup -Name $rgname -Force
    }
}


function Start-TestSleep($milliseconds)
{
    if ((Get-NetworkTestMode) -ne 'Playback')
    {
        Start-Sleep -Milliseconds $milliseconds
    }
}
