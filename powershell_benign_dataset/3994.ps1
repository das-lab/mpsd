














$resourceGroupName = "frangom-test"
$automationAccountName = "frangom-sdkCmdlet-tests"
$hybridWorkerGroupName = "test"

function Test-E2EHybridWorkerGroup
{
    $expectedHybridWorkerGroup = @{
        ResourceGroupName = $resourceGroupName
        AutomationAccountName = $automationAccountName
        Name = $hybridWorkerGroupName
        GroupType = "User"
    }

    $group = Get-AzAutomationHybridWorkerGroup -ResourceGroupName $resourceGroupName `
                                                     -AutomationAccountName $automationAccountName  `
                                                     -Name $hybridWorkerGroupName 

    
    $propertiesToValidate = @("ResourceGroupName", "AutomationAccountName", "Name", "GroupType")

    foreach ($property in $propertiesToValidate)
    {
        Assert-AreEqual $group.$property $expectedHybridWorkerGroup.$property `
            "'$property' of hybrid worker group does not match. Expected:$($expectedHybridWorkerGroup.$property) Actual: $($group.$property)"
    }

	
	Remove-AzAutomationHybridWorkerGroup -ResourceGroupName $resourceGroupName `
                                              -AutomationAccountName $automationAccountName  `
                                              -Name $hybridWorkerGroupName
	
	
	$group = Get-AzAutomationHybridWorkerGroup -ResourceGroupName $resourceGroupName `
                                              -AutomationAccountName $automationAccountName  `
                                              -Name $hybridWorkerGroupName `
                                              -ErrorAction SilentlyContinue

    Assert-True {$group -eq $null} "Fail to remove HybridWorkerGroup '$hybridWorkerGroupName'"
}

