













$newAccountName='account-powershell-test'
$existingResourceGroup='PowerShellTest'
$location = "West Central US"






function CleanupExistingTestAccount
{
	$check = Get-AzAutomationAccount -ResourceGroupName $existingResourceGroup -Name $newAccountName -ErrorAction SilentlyContinue
	if ($null -ne $check)
	{
		Remove-AzAutomationAccount -ResourceGroupName $existingResourceGroup -Name $newAccountName -Force
	}
}

function CreateResourceGroup
{
	$check = Get-AzResourceGroup -Name $existingResourceGroup -Location $location -ErrorAction SilentlyContinue
	if ($null -eq $check)
	{
		New-AzResourceGroup -Name $existingResourceGroup -Location $location -Force
	}
}

function CreateTestAccount
{
	return New-AzAutomationAccount -ResourceGroupName $existingResourceGroup -Name $newAccountName -Location $location
}


function Test-GetAutomationAccounts
{
	
	CreateResourceGroup
	CleanupExistingTestAccount

	
    $automationAccounts = Get-AzAutomationAccount
    Assert-NotNull $automationAccounts "Get All automation accounts return null."

	$existingAccountCount = $automationAccounts.Count
    
    $newAutomationAccount = CreateTestAccount
    Assert-NotNull $newAutomationAccount "Create Account Failed."

    
    $automationAccounts = Get-AzAutomationAccount
    
	$newAccountCount = $automationAccounts.Count
	Assert-AreEqual ($existingAccountCount+1) $newAccountCount "There should have only 1 more account"

	CleanupExistingTestAccount
}


function Test-AutomationAccountTags
{
    
	CreateResourceGroup
	CleanupExistingTestAccount
	$newAutomationAccount = CreateTestAccount
	Assert-AreEqual $newAutomationAccount.Tags.Count 0 "Unexpected Tag Counts"

	
	$newAutomationAccount = New-AzAutomationAccount -ResourceGroupName $existingResourceGroup -Name $newAccountName -Location $location -Tags @{"abc"="def"; "gg"="hh"}
	Assert-AreEqual $newAutomationAccount.Tags.Count 2 "Unexpected Tag Counts from new"
	Assert-AreEqual $newAutomationAccount.Tags["gg"] "hh" "Unexpected Tag Content from new"

	
	$newAutomationAccount = Set-AzAutomationAccount -ResourceGroupName $existingResourceGroup -Name $newAccountName -Tags @{"lm"="jk"}
	Assert-AreEqual $newAutomationAccount.Tags.Count 1 "Unexpected Tag Counts from set"
	Assert-AreEqual $newAutomationAccount.Tags["lm"] "jk" "Unexpected Tag Content from set"

	
	$newAutomationAccount = Get-AzAutomationAccount | Where-Object {$_.AutomationAccountName -eq $newAccountName }
	Assert-AreEqual $newAutomationAccount.Tags.Count 1 "Unexpected Tag Counts from get all"
	Assert-AreEqual $newAutomationAccount.Tags["lm"] "jk" "Unexpected Tag Content from get all"

	CleanupExistingTestAccount
}