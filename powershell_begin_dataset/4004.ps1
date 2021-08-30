














function Test-E2ECertificates
{
    $resourceGroupName = "to-delete-01"
    $automationAccountName = "fbs-aa-01"
    $thumprint = "3a7dfabed24f7443e79e815239c51826042737dc"
    $thumbprint2 = "38dae807ad6fb1f42bde1658b5abec85ace5615e"
    $Password = ConvertTo-SecureString -String "Password" -AsPlainText -Force

    New-AzAutomationCertificate -AutomationAccountName $automationAccountName `
                                     -Name "ContosoCertificate" `
                                     -Path "./ScenarioTests/sdkTestCert.cer" `
                                     -Password $Password `
                                     -ResourceGroupName $resourceGroupName `
                                     -Description "Hello"

    $getCertificate = Get-AzAutomationCertificate -ResourceGroupName $resourceGroupName `
                                   -AutomationAccountName $automationAccountName `
                                   -Name "ContosoCertificate"

    Assert-AreEqual $thumprint  $getCertificate.Thumbprint

    Set-AzAutomationCertificate -ResourceGroupName $resourceGroupName `
                                   -AutomationAccountName $automationAccountName `
                                   -Name "ContosoCertificate" `
                                   -Description "Goodbye" `
                                   -Path "./ScenarioTests/sdkTestCert2.cer"

    $getCertificate = Get-AzAutomationCertificate -ResourceGroupName $resourceGroupName `
                                   -AutomationAccountName $automationAccountName `
                                   -Name "ContosoCertificate"

    Assert-AreEqual "Goodbye"  $getCertificate.Description
    Assert-AreEqual $thumbprint2  $getCertificate.Thumbprint

    Remove-AzAutomationCertificate -ResourceGroupName $resourceGroupName `
                                        -AutomationAccountName $automationAccountName `
                                        -Name "ContosoCertificate"

    $output = Get-AzAutomationCertificate -ResourceGroupName $resourceGroupName `
                                               -AutomationAccountName $automationAccountName `
                                               -Name "ContosoCertificate" -ErrorAction SilentlyContinue 

    Assert-True {$output -eq $null}
 }