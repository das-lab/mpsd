

























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


function Test-ApplicationSecurityGroupCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/applicationSecurityGroups";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vApplicationSecurityGroup = New-AzApplicationSecurityGroup -ResourceGroupName $rgname -Name $rname -Location $location;
        Assert-NotNull $vApplicationSecurityGroup;
        Assert-True { Check-CmdletReturnType "New-AzApplicationSecurityGroup" $vApplicationSecurityGroup };
        Assert-AreEqual $rname $vApplicationSecurityGroup.Name;

        
        $vApplicationSecurityGroup = Get-AzApplicationSecurityGroup -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vApplicationSecurityGroup;
        Assert-True { Check-CmdletReturnType "Get-AzApplicationSecurityGroup" $vApplicationSecurityGroup };
        Assert-AreEqual $rname $vApplicationSecurityGroup.Name;

        
        $listApplicationSecurityGroup = Get-AzApplicationSecurityGroup -ResourceGroupName $rgname;
        Assert-NotNull ($listApplicationSecurityGroup | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listApplicationSecurityGroup = Get-AzApplicationSecurityGroup;
        Assert-NotNull ($listApplicationSecurityGroup | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listApplicationSecurityGroup = Get-AzApplicationSecurityGroup -ResourceGroupName "*";
        Assert-NotNull ($listApplicationSecurityGroup | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listApplicationSecurityGroup = Get-AzApplicationSecurityGroup -Name "*";
        Assert-NotNull ($listApplicationSecurityGroup | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listApplicationSecurityGroup = Get-AzApplicationSecurityGroup -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listApplicationSecurityGroup | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzApplicationSecurityGroup -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeApplicationSecurityGroup = $job | Receive-Job;
        Assert-AreEqual $true $removeApplicationSecurityGroup;

        
        Assert-ThrowsContains { Get-AzApplicationSecurityGroup -ResourceGroupName $rgname -Name $rname } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-ApplicationSecurityGroupCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/applicationSecurityGroups";
    
    $Tag = @{tag1='test'};

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vApplicationSecurityGroup = New-AzApplicationSecurityGroup -ResourceGroupName $rgname -Name $rname -Location $location -Tag $Tag;
        Assert-NotNull $vApplicationSecurityGroup;
        Assert-True { Check-CmdletReturnType "New-AzApplicationSecurityGroup" $vApplicationSecurityGroup };
        Assert-AreEqual $rname $vApplicationSecurityGroup.Name;
        Assert-AreEqualObjectProperties $Tag $vApplicationSecurityGroup.Tag;

        
        $vApplicationSecurityGroup = Get-AzApplicationSecurityGroup -ResourceGroupName $rgname -Name $rname;
        Assert-NotNull $vApplicationSecurityGroup;
        Assert-True { Check-CmdletReturnType "Get-AzApplicationSecurityGroup" $vApplicationSecurityGroup };
        Assert-AreEqual $rname $vApplicationSecurityGroup.Name;
        Assert-AreEqualObjectProperties $Tag $vApplicationSecurityGroup.Tag;

        
        $listApplicationSecurityGroup = Get-AzApplicationSecurityGroup -ResourceGroupName $rgname;
        Assert-NotNull ($listApplicationSecurityGroup | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listApplicationSecurityGroup = Get-AzApplicationSecurityGroup;
        Assert-NotNull ($listApplicationSecurityGroup | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listApplicationSecurityGroup = Get-AzApplicationSecurityGroup -ResourceGroupName "*";
        Assert-NotNull ($listApplicationSecurityGroup | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listApplicationSecurityGroup = Get-AzApplicationSecurityGroup -Name "*";
        Assert-NotNull ($listApplicationSecurityGroup | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listApplicationSecurityGroup = Get-AzApplicationSecurityGroup -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listApplicationSecurityGroup | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzApplicationSecurityGroup -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removeApplicationSecurityGroup = $job | Receive-Job;
        Assert-AreEqual $true $removeApplicationSecurityGroup;

        
        Assert-ThrowsContains { Get-AzApplicationSecurityGroup -ResourceGroupName $rgname -Name $rname } "not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
