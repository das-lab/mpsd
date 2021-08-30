














function Test-NewSubscription
{
    
    $accounts = @(@{ ObjectId = "cdf813b6-bdc2-4df5-b150-00ccfd7580e2" })
    
    
    Assert-True { $accounts.Count -gt 0 }

    $myNewSubName = GetAssetName

    $newSub = New-AzSubscription -EnrollmentAccountObjectId $accounts[0].ObjectId -Name $myNewSubName -OfferType MS-AZR-0017P

    Assert-AreEqual $myNewSubName $newSub.Name
	Assert-NotNull $newSub.SubscriptionId
}
