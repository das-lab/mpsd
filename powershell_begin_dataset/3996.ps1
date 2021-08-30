














function Test-E2EVariableAsset
{
    $resourceGroupName = "to-delete-01"
    $automationAccountName = "fbs-aa-01"
    $output = Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -ErrorAction SilentlyContinue
    $variableName = "CreateNewVariableWithValue"
    $variableValue = "StringValue"
    $variableValueUpdated = "StringValueChanged"

    $variableCreated = New-AzAutomationVariable -ResourceGroupName $resourceGroupName `
                                                     -AutomationAccountName $automationAccountName `
                                                     -name $variableName `
                                                     -value $variableValue `
                                                     -Encrypted:$false `
                                                     -Description "Hello"

    $getVariable = Get-AzAutomationVariable -ResourceGroupName $resourceGroupName `
                                                 -AutomationAccountName $automationAccountName `
                                                 -name $variableName

    Assert-AreEqual "Hello"  $getVariable.Description

    Set-AzAutomationVariable -ResourceGroupName $resourceGroupName `
                                  -AutomationAccountName $automationAccountName `
                                  -Name $variableName `
                                  -Encrypted:$false `
                                  -value $variableValueUpdated

    $getVariable = Get-AzAutomationVariable -ResourceGroupName $resourceGroupName `
                                                 -AutomationAccountName $automationAccountName `
                                                 -name $variableName

    Assert-AreEqual $variableValueUpdated  $getVariable.value

    Remove-AzAutomationVariable -ResourceGroupName $resourceGroupName `
                                     -AutomationAccountName $automationAccountName `
                                     -Name $variableName 

    $output = Get-AzAutomationVariable -ResourceGroupName $resourceGroupName `
                                            -AutomationAccountName $automationAccountName `
                                            -name $variableName -ErrorAction SilentlyContinue

    Assert-True {$output -eq $null}
 }