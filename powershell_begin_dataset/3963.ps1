














function Check-CmdletReturnType
{
    param($cmdletName, $cmdletReturn)

    $cmdletData = Get-Command $cmdletName
    Assert-NotNull $cmdletData
    [array]$cmdletReturnTypes = $cmdletData.OutputType.Name | Foreach-Object { return ($_ -replace "Microsoft.Azure.Commands.Network.Models.","") }
    [array]$cmdletReturnTypes = $cmdletReturnTypes | Foreach-Object { return ($_ -replace "System.","") }
    $realReturnType = $cmdletReturn.GetType().Name -replace "Microsoft.Azure.Commands.Network.Models.",""
    return $cmdletReturnTypes -contains $realReturnType
}


function Test-IpGroupsCRUD
{
    
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement "westus"
    $location = Get-ProviderLocation ResourceManagement "westus"
	$IpGroupsName = Get-ResourceName

    try
    {
      
      New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 

      
	  $actualIpGroup = New-AzIpGroup -ResourceGroupName $rgname -location $location -Name $IpGroupsName -IpAddress 10.0.0.0/24,11.9.0.0/24
      $expectedIpGroup = Get-AzIpGroup -ResourceGroupName $rgname -Name $IpGroupsName
	  Assert-AreEqual $expectedIpGroup.ResourceGroupName $actualIpGroup.ResourceGroupName	
      Assert-AreEqual $expectedIpGroup.Name $actualIpGroup.Name

	  
	  $deleteIpGroup = Remove-AzIpGroup -ResourceGroupName $rgname -Name $IpGroupsName -PassThru -Force
      Assert-AreEqual true $deleteIpGroup

    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}
