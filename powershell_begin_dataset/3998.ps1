














function Test-E2ESchedules
{
    $resourceGroupName = "to-delete-01"
    $automationAccountName = "fbs-aa-01"
    $output = Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -ErrorAction SilentlyContinue
    $StartTime = Get-Date "13:00:00"
    $StartTime = $StartTime.AddDays(1)
    $EndTime = $StartTime.AddYears(1)
    $ScheduleName = "Schedule3"

    New-AzAutomationSchedule -ResourceGroupName $resourceGroupName `
                                  -AutomationAccountName $automationAccountName `
                                  -Name "Schedule3" `
                                  -StartTime $StartTime `
                                  -ExpiryTime $EndTime `
                                  -DayInterval 1 `
                                  -Description "Hello"
   
    New-AzAutomationSchedule -ResourceGroupName $resourceGroupName `
                                  -AutomationAccountName $automationAccountName `
                                  -Name $ScheduleName `
                                  -StartTime $StartTime `
                                  -ExpiryTime $EndTime `
                                  -WeekInterval 3 `
                                  -Description "Hello Again"

    $getSchedule = Get-AzAutomationSchedule -ResourceGroupName $resourceGroupName `
                                                 -AutomationAccountName $automationAccountName `
                                                 -Name $ScheduleName

    Assert-AreEqual "Hello Again"  $getSchedule.Description
    Assert-AreEqual 3 $getSchedule.Interval

    Set-AzAutomationSchedule -ResourceGroupName $resourceGroupName `
                                  -AutomationAccountName $automationAccountName `
                                  -Name $ScheduleName `
                                  -Description "Goodbye" `
                                  -IsEnabled $FALSE 

    $getSchedule = Get-AzAutomationSchedule -ResourceGroupName $resourceGroupName `
                                                 -AutomationAccountName $automationAccountName `
                                                 -Name $ScheduleName

    Assert-AreEqual "Goodbye"  $getSchedule.Description
    Assert-AreEqual $FALSE  $getSchedule.IsEnabled

    Remove-AzAutomationSchedule -ResourceGroupName $resourceGroupName `
                                     -AutomationAccountName $automationAccountName `
                                     -Name $ScheduleName `
                                     -Force

    $getSchedule = Get-AzAutomationSchedule -ResourceGroupName $resourceGroupName `
                                                 -AutomationAccountName $automationAccountName `
                                                 -Name $ScheduleName -ErrorAction SilentlyContinue

    Assert-True {$getSchedule -eq $null}
 }
