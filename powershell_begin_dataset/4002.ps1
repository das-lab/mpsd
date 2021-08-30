














function Test-E2ECredentials
{
    $resourceGroupName = "to-delete-01"
    $automationAccountName = "fbs-aa-01"
    $output = Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -ErrorAction SilentlyContinue
    $User = "Contoso\Test"
    $Password = ConvertTo-SecureString �12345� -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password

    $credentialCreated = New-AzAutomationCredential -ResourceGroupName $resourceGroupName `
                                                         -AutomationAccountName $automationAccountName `
                                                         -Name "ContosoCredential2" `
                                                         -Value $Credential `
                                                         -Description "Hello"

    $getCredential = Get-AzAutomationCredential -ResourceGroupName $resourceGroupName `
                                                     -AutomationAccountName $automationAccountName `
                                                     -Name "ContosoCredential2"

    Assert-AreEqual ContosoCredential2  $getCredential.Name
    Assert-AreEqual $variableValue $getVariable.Value

    Set-AzAutomationCredential -ResourceGroupName $resourceGroupName `
                                    -AutomationAccountName $automationAccountName `
                                    -Name "ContosoCredential2" `
                                    -Description "Goodbye" `
                                    -Value $Credential

    $getCredential = Get-AzAutomationCredential -ResourceGroupName $resourceGroupName `
                                                     -AutomationAccountName $automationAccountName `
                                                     -Name "ContosoCredential2"

    Assert-AreEqual "Goodbye"  $getCredential.Description

    Remove-AzAutomationCredential -ResourceGroupName $resourceGroupName `
                                       -AutomationAccountName $automationAccountName `
                                       -Name "ContosoCredential2" 

    $output = Get-AzAutomationCredential -ResourceGroupName $resourceGroupName `
                                              -AutomationAccountName $automationAccountName `
                                              -Name "ContosoCredential2" -ErrorAction SilentlyContinue

    Assert-True {$output -eq $null}
}
