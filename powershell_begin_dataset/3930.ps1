













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


function Test-ExpressRoutePortCRUD
{
    
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $rname = Get-ResourceName
	$resourceTypeParent = "Microsoft.Network/expressRoutePorts"
    $location = Get-ProviderLocation $resourceTypeParent
	$peeringLocation = "Cheyenne-ERDirect"
	$encapsulation = "QinQ"
	$bandwidthInGbps = 100.0

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation

        
        $vExpressRoutePort = New-AzExpressRoutePort -ResourceGroupName $rgname -Name $rname -Location $location -PeeringLocation $peeringLocation -Encapsulation $encapsulation -BandwidthInGbps $bandwidthInGbps
        Assert-NotNull $vExpressRoutePort
        Assert-True { Check-CmdletReturnType "New-AzExpressRoutePort" $vExpressRoutePort }
        Assert-NotNull $vExpressRoutePort.Links
        Assert-True { $vExpressRoutePort.Links.Count -eq 2 }
        Assert-AreEqual $rname $vExpressRoutePort.Name

        
        $vExpressRoutePort = Get-AzExpressRoutePort -ResourceGroupName $rgname -Name $rname
        Assert-NotNull $vExpressRoutePort
        Assert-True { Check-CmdletReturnType "Get-AzExpressRoutePort" $vExpressRoutePort }
        Assert-AreEqual $rname $vExpressRoutePort.Name

        $vExpressRoutePort = Get-AzExpressRoutePort -ResourceGroupName "*"
        Assert-NotNull $vExpressRoutePort
        Assert-True {$vExpressRoutePort.Count -ge 0}

        $vExpressRoutePort = Get-AzExpressRoutePort -Name "*"
        Assert-NotNull $vExpressRoutePort
        Assert-True {$vExpressRoutePort.Count -ge 0}

        $vExpressRoutePort = Get-AzExpressRoutePort -ResourceGroupName "*" -Name "*"
        Assert-NotNull $vExpressRoutePort
        Assert-True {$vExpressRoutePort.Count -ge 0}

        
        $vExpressRoutePort = Get-AzureRmExpressRoutePort -ResourceId $vExpressRoutePort.Id
        Assert-NotNull $vExpressRoutePort
        Assert-True { Check-CmdletReturnType "Get-AzureRmExpressRoutePort" $vExpressRoutePort }
        Assert-AreEqual $rname $vExpressRoutePort.Name

        $vExpressRoutePorts = Get-AzureRmExpressRoutePort -ResourceGroupName $rgname
        Assert-NotNull $vExpressRoutePorts

        $vExpressRoutePortsAll = Get-AzureRmExpressRoutePort
        Assert-NotNull $vExpressRoutePortsAll

		
		$vExpressRoutePort.Links[0].AdminState = "Enabled"
		Set-AzExpressRoutePort -ExpressRoutePort $vExpressRoutePort

		
		$vExpressRouteLink = $vExpressRoutePort | Get-AzExpressRoutePortLinkConfig -Name "Link1"
		Assert-NotNull $vExpressRouteLink;
		Assert-AreEqual $vExpressRouteLink.AdminState "Enabled"

		
		$vExpressRouteLinksList = $vExpressRoutePort | Get-AzExpressRoutePortLinkConfig
		Assert-True { $vExpressRouteLinksList.Count -eq 2 }

        
        $removeExpressRoutePort = Remove-AzExpressRoutePort -ResourceGroupName $rgname -Name $rname -PassThru -Force
        Assert-AreEqual $true $removeExpressRoutePort
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-ExpressRoutePortIdentityCRUD
{
    
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    $rname = Get-ResourceName
    $identityName = Get-ResourceName
    $resourceTypeParent = "Microsoft.Network/expressRoutePorts"
    $location = Get-ProviderLocation $resourceTypeParent
    $peeringLocation = "Cheyenne-ERDirect"
    $encapsulation = "QinQ"
    $bandwidthInGbps = 100.0

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation

        
        $identity = New-AzUserAssignedIdentity -Name $identityName -Location $rglocation -ResourceGroup $rgname
        
        
        $expressRoutePortIdentity = New-AzExpressRoutePortIdentity -UserAssignedIdentity $identity.Id
		
        
        $vExpressRoutePort = New-AzExpressRoutePort -Identity $expressRoutePortIdentity -ResourceGroupName $rgname -Name $rname -Location $location -PeeringLocation $peeringLocation -Encapsulation $encapsulation -BandwidthInGbps $bandwidthInGbps
        Assert-NotNull $vExpressRoutePort
        Assert-NotNull $(Get-AzExpressRoutePortIdentity -ExpressRoutePort $vExpressRoutePort)
        Assert-True { Check-CmdletReturnType "New-AzExpressRoutePort" $vExpressRoutePort }
        Assert-NotNull $vExpressRoutePort.Links
        Assert-True { $vExpressRoutePort.Links.Count -eq 2 }
        Assert-AreEqual $rname $vExpressRoutePort.Name

        
        $vExpressRoutePort = Get-AzExpressRoutePort -ResourceGroupName $rgname -Name $rname
        Assert-NotNull $vExpressRoutePort
        Assert-True { Check-CmdletReturnType "Get-AzExpressRoutePort" $vExpressRoutePort }
        Assert-AreEqual $rname $vExpressRoutePort.Name

        $vExpressRoutePort = Get-AzExpressRoutePort -ResourceGroupName "*"
        Assert-NotNull $vExpressRoutePort
        Assert-True {$vExpressRoutePort.Count -ge 0}

        $vExpressRoutePort = Get-AzExpressRoutePort -Name "*"
        Assert-NotNull $vExpressRoutePort
        Assert-True {$vExpressRoutePort.Count -ge 0}

        $vExpressRoutePort = Get-AzExpressRoutePort -ResourceGroupName "*" -Name "*"
        Assert-NotNull $vExpressRoutePort
        Assert-True {$vExpressRoutePort.Count -ge 0}

        
        $vExpressRoutePort = Get-AzureRmExpressRoutePort -ResourceId $vExpressRoutePort.Id
        Assert-NotNull $vExpressRoutePort
        Assert-True { Check-CmdletReturnType "Get-AzureRmExpressRoutePort" $vExpressRoutePort }
        Assert-AreEqual $rname $vExpressRoutePort.Name

        $vExpressRoutePorts = Get-AzureRmExpressRoutePort -ResourceGroupName $rgname
        Assert-NotNull $vExpressRoutePorts

        $vExpressRoutePortsAll = Get-AzureRmExpressRoutePort
        Assert-NotNull $vExpressRoutePortsAll

        
        Remove-AzExpressRoutePortIdentity -ExpressRoutePort $vExpressRoutePort
        Assert-Null $(Get-AzExpressRoutePortIdentity -ExpressRoutePort $vExpressRoutePort)
		
        
        $removeExpressRoutePort = Remove-AzExpressRoutePort -ResourceGroupName $rgname -Name $rname -PassThru -Force
        Assert-AreEqual $true $removeExpressRoutePort
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


