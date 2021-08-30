














function GetResourceGroupName
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

  $oldErrorActionPreferenceValue = $ErrorActionPreference;
  $ErrorActionPreference = "SilentlyContinue";
    
  try
  {
    $assetName = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::GetAssetName($testName, "pstestrg");
  }
  catch
  {
    if (($Error.Count -gt 0) -and ($Error[0].Exception.Message -like '*Unable to find type*'))
    {
      $assetName = Get-RandomItemName;
    }
    else
    {
      throw;
    }
  }
  finally
  {
    $ErrorActionPreference = $oldErrorActionPreferenceValue;
  }
  return $assetName
}


function CreateResourceGroup([string]$rgname, [string]$location) 
{
	$resourceGroup = New-AzResourceGroup -Name $rgname -Location $location -Force
	return $resourceGroup
}


function RemoveResourceGroup([string]$rgname) 
{
	Remove-AzResourceGroup -Name $rgname -Force
}


function CreateStorageAccount([string]$rgname, [string]$name, [string]$location)
{
	New-AzStorageAccount -ResourceGroupName $rgname -Name $name -Location $location -Type "Standard_GRS"
	$storageAccount = Get-AzStorageAccount -ResourceGroupName $rgname -Name $name
	return $storageAccount
}


function RemoveStorageAccount([string]$rgname, [string]$name) 
{
	Remove-AzStorageAccount -ResourceGroupName $rgname -Name $name
}


function GetStorageAccount
{

  [CmdletBinding()]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] $ResourceGroupName,
    [string] [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)] [alias("StorageAccountName")] $Name)
  BEGIN { 
    $context = Get-Context
	  $client = Get-StorageClient $context
  }
  PROCESS {
    $getTask = $client.StorageAccounts.GetPropertiesAsync($ResourceGroupName, $Name, [System.Threading.CancellationToken]::None)
    
	  Write-Output $getTask.Result.StorageAccount
  }
  END {}
}



function Assert-Tags($tags1, $tags2)
{
  if($tags1.count -ne $tags2.count)
  {
    throw "Tag size not equal. Tag1: $tags1.count Tag2: $tags2.count"
  }

  foreach($key in $tags1.Keys)
  {
    if($tags1[$key] -ne $tags2[$key])
    {
      throw "Tag content not equal. Key:$key Tags1:" +  $tags1[$key] + "Tags2:" + $tags2[$key]
    }
  }
}


function Get-AvailableLocation($preferedLocation)
{
  if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
  {
    $namespace = "Microsoft.Media"
    $provider = Get-AzResourceProvider -ProviderNamespace Microsoft.Media | where {$_.Locations.length -ne 0}
    $locations = $provider.Locations
    if($locations -contains $preferedLocation)
    {
      return $preferedLocation
    }
    return $locations[0]
  }

  return $preferedLocation
}
