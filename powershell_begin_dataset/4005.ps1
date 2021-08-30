














function Test-E2EJobSchedules
{
    $resourceGroupName = "to-delete-01"
    $automationAccountName = "fbs-aa-01"
    $output = Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -ErrorAction SilentlyContinue
    $StartTime = Get-Date "13:00:00"
    $StartTime = $StartTime.AddDays(1)
    $EndTime = $StartTime.AddYears(1)
    $ScheduleName = "ScheduleForRunbookAssociation"
    $runbookName =  "RunbookForScheduleAssociation"

    Register-AzAutomationScheduledRunbook -ResourceGroupName $resourceGroupName `
                                               -AutomationAccountName $automationAccountName `
                                               -RunbookName $runbookName `
                                               -ScheduleName $ScheduleName

    $jobSchedule = Get-AzAutomationScheduledRunbook -ResourceGroupName $resourceGroupName `
                                                         -AutomationAccountName $automationAccountName `
                                                         -RunbookName $runbookName `
                                                         -ScheduleName $ScheduleName


    Assert-AreEqual $ScheduleName  $jobSchedule.ScheduleName 
    Assert-AreEqual $runbookName $jobSchedule.RunbookName

    Unregister-AzAutomationScheduledRunbook -ResourceGroupName $resourceGroupName `
                                                 -AutomationAccountName $automationAccountName `
                                                 -RunbookName $runbookName `
                                                 -ScheduleName $ScheduleName -Force

    $jobSchedule = Get-AzAutomationScheduledRunbook -ResourceGroupName $resourceGroupName `
                                                         -AutomationAccountName $automationAccountName `
                                                         -RunbookName $runbookName `
                                                         -ScheduleName $ScheduleName -ErrorAction SilentlyContinue

    Assert-True {$jobSchedule -eq $null}
 }

