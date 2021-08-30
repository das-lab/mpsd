














function Test-AzureRmAlias
{
	Disable-AzureRmAlias
	Assert-Throws { Get-AzureRmSubscription }
	Enable-AzureRmAlias
	Get-AzureRmSubscription

	Disable-AzureRmAlias -Scope "Process" -Module Az.Accounts
	Assert-Throws { Get-AzureRmSubscription }
	Enable-AzureRmAlias -Module Az.Compute, Az.Resources
	Assert-Throws { Get-AzureRmSubscription }
	Enable-AzureRmAlias -Scope "Process" -Module Az.Accounts
	Get-AzureRmSubscription

	$PROFILE = New-Object PSObject -Property @{
		CurrentUserAllHosts = Join-Path $PSScriptRoot "CurrentUserProfile.ps1"; 
		AllUsersAllHosts = Join-Path $PSScriptRoot "AllUsersProfile.ps1"
	}

	Disable-AzureRmAlias
	Assert-Throws { Get-AzureRmSubscription }
	Enable-AzureRmAlias -Scope "CurrentUser" -Module Az.Accounts
	Get-AzureRmSubscription
	$azureSession = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance
	$file = $azureSession.DataStore.ReadFileAsText($PROFILE.CurrentUserAllHosts)
	
	$expected = 
"*
"*if (`$importerror.Count -eq 0) { *    Enable-AzureRmAlias -Module Az.Accounts -ErrorAction SilentlyContinue; *}*
	
	if ($file -notlike $expected)
	{
		throw "Incorrect string written to file."
	}

	Enable-AzureRmAlias -Scope "LocalMachine" -Module Az.Accounts
	$file = $azureSession.DataStore.ReadFileAsText($PROFILE.AllUsersAllHosts)
	if ($file -notlike $expected)
	{
		throw "Incorrect string written to file."
	}
}
