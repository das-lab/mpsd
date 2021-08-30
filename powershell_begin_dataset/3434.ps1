
	
	
	
	
	
	
	
	
	
	
	


Write-Output "JobId:$($PsPrivateMetaData.JobId.Guid)"
$VerbosePreference = 'Continue'
Login-AutomationConnection %LOGIN-PARAMS%

%TEST-LIST%
Run-Test $testList %LOGIN-PARAMS%

$azErrors = Resolve-AzError
$azErrors
Write-Verbose 'Resolve-AzError Information'
Write-Verbose '--------------------------------'
$azErrors | ConvertTo-Json | Write-Verbose