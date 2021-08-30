













function Check-CmdletReturnType
{
    param($cmdletName, $cmdletReturn)

    $cmdletData = Get-Command $cmdletName;
    Assert-NotNull $cmdletData;
    [array]$cmdletReturnTypes = $cmdletData.OutputType.Name | Foreach-Object { return ($_ -replace "Microsoft.Azure.Commands.Network.Models.","") };
    [array]$cmdletReturnTypes = $cmdletReturnTypes | Foreach-Object { return ($_ -replace "System.","") };
    $realReturnType = $cmdletReturn.GetType().Name -replace "Microsoft.Azure.Commands.Network.Models.","";
    return $cmdletReturnTypes -contains $realReturnType;
}


function Test-AvailablePrivateEndpointTypeCRUD
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $location = Get-ProviderLocation "Microsoft.Network/availablePrivateEndpointTypes" "westus";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        $vAvailablePrivateEndpointType = Get-AzAvailablePrivateEndpointType -Location $location;
        Assert-True { Check-CmdletReturnType "Get-AzAvailablePrivateEndpointType" $vAvailablePrivateEndpointType };
        Assert-NotNull $vAvailablePrivateEndpointType;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}