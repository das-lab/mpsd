














function Test-AzureRmSignalR {
    
    $resourceGroupName = Get-RandomResourceGroupName
    $signalrName = Get-RandomSignalRName
    $freeSignalRName = Get-RandomSignalRName "signalr-free-test-"
    $location = Get-ProviderLocation "Microsoft.SignalRService/SignalR"

    try {
        New-AzResourceGroup -Name $resourceGroupName -Location $location

        
        $signalr = New-AzSignalR -ResourceGroupName $resourceGroupName -Name $signalrName -Sku "Standard_S1"
        Verify-SignalR $signalr $signalrName $location "Standard_S1" 1

        
        $signalrs = Get-AzSignalR -ResourceGroupName $resourceGroupName
        Assert-NotNull $signalrs
        Assert-AreEqual "PSSignalRResource" $signalrs.GetType().Name
        Verify-SignalR $signalrs $signalrName $location "Standard_S1" 1

        
        $retrievedSignalR = Get-AzSignalR -ResourceGroupName $resourceGroupName -Name $signalrName
        Verify-SignalR $retrievedSignalR $signalrName $location "Standard_S1" 1

        
        $freeSignalR = New-AzSignalR -ResourceGroupName $resourceGroupName -Name $freeSignalRName -Sku "Free_F1"
        Verify-SignalR $freeSignalR $freeSignalRName $location "Free_F1" 1

        
        $signalrs = Get-AzSignalR -ResourceGroupName $resourceGroupName
        Assert-NotNull $signalrs
        Assert-AreEqual "Object[]" $signalrs.GetType().Name
        Assert-AreEqual 2 $signalrs.Length
        $freeSignalR = $signalrs | Where-Object -FilterScript {$_.Sku.Name -eq "Free_F1"}
        $standardSignalR = $signalrs | Where-Object -FilterScript {$_.Sku.Name -eq "Standard_S1"}
        Assert-NotNull $freeSignalR
        Assert-NotNull $standardSignalR
        Verify-SignalR $freeSignalR $freeSignalRName $location "Free_F1" 1

        
        $keys = Get-AzSignalRKey -ResourceGroupName $resourceGroupName -Name $signalrName
        Assert-NotNull $keys
        Assert-NotNull $keys.PrimaryKey
        Assert-NotNull $keys.PrimaryConnectionString
        Assert-NotNull $keys.SecondaryKey
        Assert-NotNull $keys.SecondaryConnectionString

        
        $ret = New-AzSignalRKey -ResourceGroupName $resourceGroupName -Name $signalrName -KeyType Primary -PassThru
        Assert-True { $ret }
        $newKeys1 = Get-AzSignalRKey -ResourceGroupName $resourceGroupName -Name $signalrName
        Assert-NotNull $newKeys1
        Assert-AreNotEqual $keys.PrimaryKey $newKeys1.PrimaryKey
        Assert-AreNotEqual $keys.PrimaryConnectionString $newKeys1.PrimaryConnectionString
        Assert-AreEqual $keys.SecondaryKey $newKeys1.SecondaryKey
        Assert-AreEqual $keys.SecondaryConnectionString $newKeys1.SecondaryConnectionString

        
        $ret = New-AzSignalRKey -ResourceGroupName $resourceGroupName -Name $signalrName -KeyType Secondary
        Assert-Null $ret
        $newKeys2 = Get-AzSignalRKey -ResourceGroupName $resourceGroupName -Name $signalrName
        Assert-NotNull $newKeys2
        Assert-AreEqual $newKeys1.PrimaryKey $newKeys2.PrimaryKey
        Assert-AreEqual $newKeys1.PrimaryConnectionString $newKeys2.PrimaryConnectionString
        Assert-AreNotEqual $newKeys1.SecondaryKey $newKeys2.SecondaryKey
        Assert-AreNotEqual $newKeys1.SecondaryConnectionString $newKeys2.SecondaryConnectionString

        Remove-AzSignalR -ResourceGroupName $resourceGroupName -Name $signalrName

        Get-AzSignalR -ResourceGroupName $resourceGroupName | Remove-AzSignalR
    }
    finally {
        Remove-AzResourceGroup -Name $resourceGroupName -Force
    }
}


function Test-AzureRmSignalRWithDefaultArgs {
    $resourceGroupName = Get-RandomResourceGroupName
    $signalrName = Get-RandomSignalRName
    $freeSignalRName = Get-RandomSignalRName "signalr-free-test-"
    $location = Get-ProviderLocation "Microsoft.SignalRService/SignalR"

    try {
		New-AzResourceGroup -Name $resourceGroupName -Location $location

        
        $signalr = New-AzSignalR -Name $resourceGroupName
        Verify-SignalR $signalr $resourceGroupName $location "Standard_S1" 1

        $signalrs = Get-AzSignalR -ResourceGroupName $resourceGroupName
        Assert-NotNull $signalrs
        Assert-AreEqual "PSSignalRResource" $signalrs.GetType().Name
        Verify-SignalR $signalrs $resourceGroupName $location "Standard_S1" 1

        
        Set-AzDefault -ResourceGroupName $resourceGroupName
        $signalr = New-AzSignalR -Name $signalrName -Sku "Free_F1"

        
        $signalrs = Get-AzSignalR -ResourceGroupName $resourceGroupName
        Assert-NotNull $signalrs
        Assert-AreEqual "Object[]" $signalrs.GetType().Name
        Assert-AreEqual 2 $signalrs.Length
        $freeSignalR = $signalrs | Where-Object -FilterScript {$_.Sku.Name -eq "Free_F1"}
        $standardSignalR = $signalrs | Where-Object -FilterScript {$_.Sku.Name -eq "Standard_S1"}
        Assert-NotNull $freeSignalR
        Assert-NotNull $standardSignalR
        Verify-SignalR $freeSignalR $signalrName $location "Free_F1" 1

        
        $keys = Get-AzSignalRKey -Name $signalrName
        Assert-NotNull $keys
        Assert-NotNull $keys.PrimaryKey
        Assert-NotNull $keys.PrimaryConnectionString
        Assert-NotNull $keys.SecondaryKey
        Assert-NotNull $keys.SecondaryConnectionString

        
        $ret = New-AzSignalRKey -Name $signalrName -KeyType Primary -PassThru
        Assert-True { $ret }
        $newKeys1 = Get-AzSignalRKey -Name $signalrName
        Assert-NotNull $newKeys1
        Assert-AreNotEqual $keys.PrimaryKey $newKeys1.PrimaryKey
        Assert-AreNotEqual $keys.PrimaryConnectionString $newKeys1.PrimaryConnectionString
        Assert-AreEqual $keys.SecondaryKey $newKeys1.SecondaryKey
        Assert-AreEqual $keys.SecondaryConnectionString $newKeys1.SecondaryConnectionString

        
        Remove-AzSignalR -Name $signalrName

        
        Get-AzSignalR -Name $resourceGroupName | Remove-AzSignalR
    }
    finally {
        Remove-AzResourceGroup -Name $resourceGroupName -Force
    }
}


function Verify-SignalR {
    param(
        [Microsoft.Azure.Commands.SignalR.Models.PSSignalRResource] $signalr,
        [string] $signalrName,
        [string] $location,
        [string] $sku,
        [int] $unitCount
    )
    Assert-NotNull $signalr
    Assert-NotNull $signalr.Id
    Assert-NotNull $signalr.Type
    Assert-AreEqual $signalrName $signalr.Name
    Assert-LocationEqual $location $signalr.Location

    Assert-NotNull $signalr.Sku
    Assert-AreEqual ([Microsoft.Azure.Commands.SignalR.Models.PSResourceSku]) $signalr.Sku.GetType()
    Assert-AreEqual $sku $signalr.Sku.Name
    Assert-AreEqual $unitCount $signalr.Sku.Capacity
    Assert-AreEqual "Succeeded" $signalr.ProvisioningState
    Assert-AreEqual "$signalrName.service.signalr.net" $signalr.HostName
    Assert-NotNull $signalr.ExternalIP
    Assert-NotNull $signalr.PublicPort
    Assert-NotNull $signalr.ServerPort
    Assert-NotNull $signalr.Version
}
