















$resourceGroupName = "PSCmdletTest-RG"
$automationAccountName = "PSCmdletTestAccount01"

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



function AutomationAccountExistsFn
{
	try
	{
		$account = Get-AzAutomationAccount -ResourceGroupName $resourceGroupName -Name $automationAccountName
    
		return ($account -ne $null)
	}
	catch
	{
		return $false
	}
}




function Test-CreateRunbookGraph
{
   param(
        [string] $Name
    )

	Assert-True {AutomationAccountExistsFn} "Automation Account does not exist."

    $runbook = New-AzAutomationRunbook `
                        -Name $Name `
                        -ResourceGroupName $resourceGroupName `
                        -AutomationAccountName $automationAccountName `
                        -Description "Test Graph runbook" `
                        -Type Graph `
                        -LogProgress $true `
                        -LogVerbose $true

    Assert-NotNull $runbook "New-AzAutomationRunbook failed to create Graph runbook $Name."

    Write-Output "Create Graph runbook - success."

    
    Assert-Throws {New-AzAutomationRunbook `
                        -Name $Name `
                        -ResourceGroupName $resourceGroupName `
                        -AutomationAccountName $automationAccountName `
                        -Description "Test Graph runbook" `
                        -Type Graph `
                        -LogProgress $true `
                        -LogVerbose $true
                   }

    
    Remove-AzAutomationRunbook -Name $Name -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Force

    Write-Output "Remove created runbook."

    
    Assert-Throws {Get-AzAutomationRunbook `
                        -Name $Name `
                        -ResourceGroupName $resourceGroupName `
                        -AutomationAccountName $automationAccountName
                  }

    Write-Output "Remove runbook - success."
}



function Test-ImportRunbookPowerShell
{
   param(
        [string] $Name, 
        [string] $RunbookPath
    )

	Assert-True {AutomationAccountExistsFn} "Automation Account does not exist."

    $desc = 'PowerShell Tutorial runbook'
    $tags = @{'TagKey1'='TagValue1'}

    $runbook = Import-AzAutomationRunbook `
                        -Path $RunbookPath `
                        -Description $desc `
                        -Name $Name `
                        -Type PowerShell `
                        -ResourceGroup $resourceGroupName `
                        -Tags $tags `
                        -LogProgress $true `
                        -LogVerbose $true `
                        -AutomationAccountName $automationAccountName `
                        -Published 

    Assert-NotNull $runbook "Import-AzAutomationRunbook failed to import PowerShell script runbook $Name."

	Write-Output "Runbook Name: $($runbook.Name)"
	Write-Output "Runbook State: $($runbook.State)"
    Assert-True { $runbook.Name -ieq $Name } "Import-AzAutomationRunbook did not import runbook of type PowerShell successfully."
    Assert-True { $runbook.State -ieq 'Published' } "Import-AzAutomationRunbook did not Publish the PowerShell runbook, as requested."

    Write-Output "Import Graphical runbook - success."

    
    Remove-AzAutomationRunbook -Name $Name -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Force

    Write-Output "Remove created runbook."

    
    Assert-Throws {Get-AzAutomationRunbook `
                        -Name $Name `
                        -ResourceGroupName $resourceGroupName `
                        -AutomationAccountName $automationAccountName
                  }

    Write-Output "Remove runbook - success."
}


function Test-ImportAndDeleteRunbookGraphical
{
   param(
        [string] $Name, 
        [string] $RunbookPath
    )

    Assert-True {AutomationAccountExistsFn} "Automation Account does not exist."

	$desc = 'Graphical Tutorial runbook'
    $tags = @{'TagKey1'='TagValue1'}

    $runbook = Import-AzAutomationRunbook `
                        -Path $RunbookPath `
                        -Description $desc `
                        -Name $Name `
                        -Type Graph `
                        -ResourceGroup $resourceGroupName `
                        -Tags $tags `
                        -LogProgress $true `
                        -LogVerbose $true `
                        -AutomationAccountName $automationAccountName `
                        -Published 

    Assert-NotNull $runbook "Import-AzAutomationRunbook failed to import Graphical runbook $Name."
    Assert-True { $runbook.Name -ieq $Name } "Import-AzAutomationRunbook did not import runbook of type Graph successfully."
    Assert-True { $runbook.State -ieq 'Published' } "Import-AzAutomationRunbook did not Publish the Graph runbook, as requested."

    Write-Output "Import Graphical runbook - success."

    
    Remove-AzAutomationRunbook -Name $Name -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Force

    Write-Output "Remove created runbook."

    
    Assert-Throws {Get-AzAutomationRunbook `
                        -Name $Name `
                        -ResourceGroupName $resourceGroupName `
                        -AutomationAccountName $automationAccountName
                  }

    Write-Output "Remove runbook - success."
}


function Test-CreateJobAndGetOutputPowerShellScript
{
   param(
        [string] $Name, 
        [string] $RunbookPath
    )

	Assert-True {AutomationAccountExistsFn} "Automation Account does not exist."

    $desc = 'PowerShell Script runbook'
    $tags = @{'TagKey1'='TagValue1'}

    $runbook = Import-AzAutomationRunbook `
                        -Path $RunbookPath `
                        -Description $desc `
                        -Name $Name `
                        -Type PowerShell `
                        -ResourceGroup $resourceGroupName `
                        -Tags $tags `
                        -LogProgress $false `
                        -LogVerbose $false `
                        -AutomationAccountName $automationAccountName `
                        -Published 

    Assert-NotNull $runbook "Import-AzAutomationRunbook failed to import PowerShell Script runbook $Name."

	
	
	$jobId = 'f6f1bda7-9352-47e9-9ca3-4f6c0af62966'

	
	$job = Get-AzAutomationJob -Id $jobId -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName

	Assert-True { $job.Status -ieq 'Failed' } "Failed to find the expected (failed) job!"
	 
    
    $allOutput = Get-AzAutomationJobOutput -Id $jobId -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Stream Any
    Assert-True { $allOutput.Count -gt 0 } "Get-AzAutomationJobOutput failed to get automation Job Output!" 

    Write-Output "Get $($allOutput.Count) output records - success."

    
    $errOutput = Get-AzAutomationJobOutput -Id $jobId -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Stream Error
	$streamId = $errOutput[0].StreamRecordId
    Assert-True { $errOutput.Type -eq 'Error' } "Get-AzAutomationJobOutput failed to get automation Job Error record!"

    Write-Output "Get error output of the job - success."

    
    $errRecord = Get-AzAutomationJobOutputRecord -JobId $jobId -Id $streamId -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName
    Assert-True { $errRecord -ne $null } "Get-AzAutomationJobOutputRecord failed to get automation Job Error record Output!"

    Write-Output "Get single error record of the job - success."

    
    Remove-AzAutomationRunbook -Name $Name -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Force

    Write-Output "Remove created runbook."

    
    Assert-Throws {Get-AzAutomationRunbook `
                        -Name $Name `
                        -ResourceGroupName $resourceGroupName `
                        -AutomationAccountName $automationAccountName
                  }

    Write-Output "Remove runbook - success."
}
