














function Get-Location
{
	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne `
        [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
	{
		$namespace = "Microsoft.DevTestLab"
		$type = "sites"
		$location = Get-AzResourceProvider -ProviderNamespace $namespace `
        | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}

		if ($location -eq $null)
		{
			return "West US"
		} else
		{
			return $location.Locations[0]
		}
	}

	return "WestUS"
}


function Invoke-For-Both
{
    Param($param1,
        $param2,
        [scriptblock]$functionToCall)

    $functionToCall.Invoke($param1);
    $functionToCall.Invoke($param2);
}


function Setup-Test-ResourceGroup
{
    Param($_resourceGroupName,
        $_labName)
    $global:rgname = $_resourceGroupName;
    $global:labName = $_labName;

    $location = Get-Location

    
    New-AzResourceGroup -Name $rgname -Location $location
    New-AzResourceGroupDeployment -Name $labName -ResourceGroupName $rgname `
    -TemplateParameterObject @{ newLabName = "$labName" } `
    -TemplateFile https://raw.githubusercontent.com/Azure/azure-devtestlab/master/Samples/101-dtl-create-lab/azuredeploy.json
}


function Setup-Test-Vars
{
    Param($_resourceGroupName,
        $_labName)
    $global:rgname = $_resourceGroupName;
    $global:labName = $_labName;
}


function Destroy-Test-ResourceGroup
{
    Param($_resourceGroupName)

    Remove-AzResourceGroup -Name $_resourceGroupName -Force
}
