





















function Test-ListEnrollmentAccounts
{
    $enrollmentAccounts = Get-AzEnrollmentAccount

    Assert-True {$enrollmentAccounts.Count -ge 1}
	Assert-NotNull $enrollmentAccounts[0].ObjectId
	Assert-NotNull $enrollmentAccounts[0].PrincipalName
}


function Test-GetEnrollmentAccountWithName
{
    $enrollmentAccounts = @(Get-AzEnrollmentAccount)

	$enrollmentAccountObjectId = $enrollmentAccounts[0].ObjectId
    $enrollmentAccount = Get-AzEnrollmentAccount -ObjectId $enrollmentAccountObjectId

	Assert-AreEqual $enrollmentAccountObjectId $enrollmentAccount.ObjectId
	Assert-NotNull $enrollmentAccount.PrincipalName
}
