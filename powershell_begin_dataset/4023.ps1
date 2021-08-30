














function Test-GetAllADGroups
{
    
    $groups = Get-AzADGroup

    
    Assert-NotNull($groups)
    foreach($group in $groups) {
        Assert-NotNull($group.DisplayName)
        Assert-NotNull($group.Id)
    }
}


function Test-GetADGroupWithSearchString
{
    param([string]$displayName)

    
    
    $groups = Get-AzADGroup -SearchString $displayName

    
    Assert-AreEqual $groups.Count 1
    Assert-NotNull $groups[0].Id
    Assert-AreEqual $groups[0].DisplayName $displayName
}


function Test-GetADGroupWithBadSearchString
{
    
    
    $groups = Get-AzADGroup -SearchString "BadSearchString"

    
    Assert-Null($groups)
}


function Test-GetADGroupWithObjectId
{
    param([string]$objectId)

    
    $groups = Get-AzADGroup -ObjectId $objectId

    
    Assert-AreEqual $groups.Count 1
    Assert-AreEqual $groups[0].Id $objectId
    Assert-NotNull($groups[0].DisplayName)
}


function Test-GetADGroupSecurityEnabled
{
    param([string]$objectId, [string]$securityEnabled)

    
    $groups = Get-AzADGroup -ObjectId $objectId

    
    Assert-AreEqual $groups.Count 1
    Assert-AreEqual $groups[0].Id $objectId
    Assert-AreEqual $groups[0].SecurityEnabled $securityEnabled
    Assert-NotNull($groups[0].DisplayName)
}


function Test-GetADGroupWithBadObjectId
{
    
    $groups = Get-AzADGroup -ObjectId "baadc0de-baad-c0de-baad-c0debaadc0de"

    
    Assert-Null $groups
}


function Test-GetADGroupWithUserObjectId
{
    param([string]$objectId)

    
    $groups = Get-AzADGroup -ObjectId $objectId

    
    Assert-Null $groups
}


function Test-GetADGroupMemberWithGroupObjectId
{
    param([string]$groupObjectId, [string]$userObjectId, [string]$userName)

    
    $members = Get-AzADGroupMember -GroupObjectId $groupObjectId

    
    Assert-AreEqual $members.Count 1
    Assert-AreEqual $members[0].Id $userObjectId
    Assert-AreEqual $members[0].DisplayName $userName
}


function Test-GetADGroupMemberWithBadGroupObjectId
{
    
    Assert-Throws { Get-AzADGroupMember -GroupObjectId "baadc0de-baad-c0de-baad-c0debaadc0de" }
}


function Test-GetADGroupMemberWithUserObjectId
{
    param([string]$objectId)

    
    Assert-Throws { Get-AzADGroupMember -GroupObjectId $objectId }
}


function Test-GetADGroupMemberFromEmptyGroup
{
    param([string]$objectId)

    
    $members = Get-AzADGroupMember -GroupObjectId $objectId

    
    Assert-Null($members)
}


function Test-GetADServicePrincipalWithObjectId
{
    param([string]$objectId)

    
    $servicePrincipals = Get-AzADServicePrincipal -ObjectId $objectId

    
    Assert-AreEqual $servicePrincipals.Count 1
    Assert-AreEqual $servicePrincipals[0].Id $objectId
}


function Test-GetADServicePrincipalWithBadObjectId
{
    
    $servicePrincipals = Get-AzADServicePrincipal -ObjectId "baadc0de-baad-c0de-baad-c0debaadc0de"

    
    Assert-Null($servicePrincipals)
}


function Test-GetADServicePrincipalWithUserObjectId
{
    param([string]$objectId)

    
    $servicePrincipals = Get-AzADServicePrincipal -ObjectId $objectId

    
    Assert-Null($servicePrincipals)
}


function Test-GetADServicePrincipalWithSPN
{
    param([string]$SPN)

    
    $servicePrincipals = Get-AzADServicePrincipal -ServicePrincipalName $SPN

    
    Assert-AreEqual $servicePrincipals.Count 1
    Assert-NotNull $servicePrincipals[0].Id
    Assert-True { $servicePrincipals[0].ServicePrincipalNames.Contains($SPN) }
}


function Test-GetADServicePrincipalWithBadSPN
{
    
    $servicePrincipals = Get-AzADServicePrincipal -ServicePrincipalName "badspn"

    
    Assert-Null($servicePrincipals)
}


function Test-GetADServicePrincipalWithSearchString
{
    param([string]$displayName)

    
    $servicePrincipals = Get-AzADServicePrincipal -SearchString $displayName

    
    Assert-AreEqual $servicePrincipals.Count 1
    Assert-AreEqual $servicePrincipals[0].DisplayName $displayName
    Assert-NotNull($servicePrincipals[0].Id)
    Assert-NotNull($servicePrincipals[0].ServicePrincipalNames)
    Assert-AreEqual $servicePrincipals[0].ServicePrincipalNames.Count 2
}


function Test-GetADServicePrincipalWithBadSearchString
{
    
    $servicePrincipals = Get-AzADServicePrincipal -SearchString "badsearchstring"

    
    Assert-Null($servicePrincipals)
}


function Test-GetAllADUser
{
    
    $users = Get-AzADUser

    
    Assert-NotNull($users)
    foreach($user in $users) {
        Assert-NotNull($user.DisplayName)
        Assert-NotNull($user.Id)
    }
}


function Test-GetADUserWithObjectId
{
    param([string]$objectId)

    
    $users = Get-AzADUser -ObjectId $objectId

    
    Assert-AreEqual $users.Count 1
    Assert-AreEqual $users[0].Id $objectId
    Assert-NotNull($users[0].DisplayName)
    Assert-NotNull($users[0].UserPrincipalName)
}



function Test-GetADUserWithMail
{
    param([string]$mail)

    
    $users = Get-AzADUser -Mail $mail

    
    Assert-AreEqual $users.Count 1
    
    Assert-NotNull($users[0].DisplayName)
    Assert-NotNull($users[0].UserPrincipalName)
}


function Test-GetADUserWithBadObjectId
{
    
    $users = Get-AzADUser -ObjectId "baadc0de-baad-c0de-baad-c0debaadc0de"

    
    Assert-Null($users)
}


function Test-GetADUserWithGroupObjectId
{
    param([string]$objectId)

    
    $users = Get-AzADUser -ObjectId $objectId

    
    Assert-Null($users)
}


function Test-GetADUserWithUPN
{
    param([string]$UPN)

    
    $users = Get-AzADUser -UserPrincipalName $UPN

    
    Assert-AreEqual $users.Count 1
    Assert-AreEqual $users[0].UserPrincipalName $UPN
    Assert-NotNull($users[0].DisplayName)
    Assert-NotNull($users[0].Id)
}


function Test-GetADUserWithFPOUPN
{
    
    $users = Get-AzADUser -UserPrincipalName "azsdkposhteam_outlook.com

    
    Assert-AreEqual $users.Count 1
    Assert-AreEqual $users[0].UserPrincipalName "azsdkposhteam_outlook.com
    Assert-NotNull($users[0].DisplayName)
    Assert-NotNull($users[0].Id)
}


function Test-GetADUserWithBadUPN
{
    
    $users = Get-AzADUser -UserPrincipalName "baduser@rbactest.onmicrosoft.com"

    
    Assert-Null($users)
}


function Test-GetADUserWithSearchString
{
    param([string]$displayName)

    
    
    $users = Get-AzADUser -SearchString $displayName

    
    Assert-NotNull($users)
    Assert-AreEqual $users[0].DisplayName $displayName
    Assert-NotNull($users[0].Id)
    Assert-NotNull($users[0].UserPrincipalName)
}


function Test-GetADUserWithBadSearchString
{
    
    
    $users = Get-AzADUser -SearchString "badsearchstring"

    
    Assert-Null($users)
}


function Test-NewADApplication
{
    
    $displayName = getAssetName
    $homePage = "http://" + $displayName + ".com"
    $identifierUri = "http://" + $displayName

    
    $application = New-AzADApplication -DisplayName $displayName -HomePage $homePage -IdentifierUris $identifierUri

    
    Assert-NotNull $application
    $apps =  Get-AzADApplication
    Assert-NotNull $apps
    Assert-True { $apps.Count -ge 0 }

	
	$app1 =  Get-AzADApplication -ObjectId $application.ObjectId
	Assert-NotNull $app1
	Assert-AreEqual $app1.Count 1

    
    $app1 =  Get-AzADApplication -ApplicationId $application.ApplicationId
    Assert-NotNull $app1
    Assert-AreEqual $app1.Count 1

    
    $app1 = Get-AzADApplication -IdentifierUri $application.IdentifierUris[0]
    Assert-NotNull $app1
    Assert-AreEqual $app1.Count 1

    
    $app1 = Get-AzADApplication -DisplayNameStartWith $application.DisplayName
    Assert-NotNull $app1
    Assert-True { $app1.Count -ge 1}

    $newDisplayName = getAssetName
    $newHomePage = "http://" + $newDisplayName + ".com"
    $newIdentifierUri = "http://" + $newDisplayName

    
    Set-AzADApplication -ObjectId $application.ObjectId -DisplayName $newDisplayName -HomePage $newHomePage

    
    Set-AzADApplication -ApplicationId $application.ApplicationId -IdentifierUris $newIdentifierUri

    
    $app1 =  Get-AzADApplication -ObjectId $application.ObjectId
    Assert-NotNull $app1
    Assert-AreEqual $app1.Count 1
    Assert-AreEqual $app1.DisplayName $newDisplayName
    Assert-AreEqual $app1.HomePage $newHomePage
    Assert-AreEqual $app1.IdentifierUris[0] $newIdentifierUri

    
    Remove-AzADApplication -ObjectId $application.ObjectId -Force
}


function Test-NewADServicePrincipal
{
    param([string]$applicationId)

    
    $servicePrincipal = New-AzADServicePrincipal -ApplicationId $applicationId

    
    Assert-NotNull $servicePrincipal

    
    $sp1 = Get-AzADServicePrincipal -ObjectId $servicePrincipal.Id
    Assert-NotNull $sp1
    Assert-AreEqual $sp1.Count 1
    Assert-AreEqual $sp1.Id $servicePrincipal.Id

    
    $sp1 = Get-AzADServicePrincipal -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[0]
    Assert-NotNull $sp1
    Assert-AreEqual $sp1.Count 1
    Assert-True { $sp1.ServicePrincipalNames.Contains($servicePrincipal.ServicePrincipalNames[0]) }

    
    Remove-AzADServicePrincipal -ObjectId $servicePrincipal.Id -Force
}


function Test-NewADServicePrincipalWithoutApp
{
    
    $displayName = getAssetName

    
    $servicePrincipal = New-AzADServicePrincipal -DisplayName $displayName
	$role = Get-AzRoleAssignment -ObjectId $servicePrincipal.Id

    
    Assert-NotNull $servicePrincipal
    Assert-AreEqual $servicePrincipal.DisplayName $displayName
	Assert-Null $role

    
    $sp1 = Get-AzADServicePrincipal -ObjectId $servicePrincipal.Id
    Assert-NotNull $sp1
    Assert-AreEqual $sp1.Count 1
    Assert-AreEqual $sp1.Id $servicePrincipal.Id

    
    $sp1 = Get-AzADServicePrincipal -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[0]
    Assert-NotNull $sp1
    Assert-AreEqual $sp1.Count 1
    Assert-True { $sp1.ServicePrincipalNames.Contains($servicePrincipal.ServicePrincipalNames[0]) }

    
    $app1 =  Get-AzADApplication -ApplicationId $servicePrincipal.ApplicationId
    Assert-NotNull $app1
    Assert-AreEqual $app1.Count 1

    
    $newDisplayName = getAssetName

    Set-AzADServicePrincipal -ObjectId $servicePrincipal.Id -DisplayName $newDisplayName

    
    $sp1 = Get-AzADServicePrincipal -ObjectId $servicePrincipal.Id
    Assert-NotNull $sp1
    Assert-AreEqual $sp1.Count 1
    Assert-AreEqual $sp1.DisplayName $newDisplayName

    
    Remove-AzADApplication -ObjectId $app1.ObjectId -Force

    Assert-Throws { Remove-AzADServicePrincipal -ObjectId $servicePrincipal.Id -Force}
}


function Test-NewADServicePrincipalWithReaderRole
{
	
	$displayName = getAssetName
	$roleDefinitionName = "Reader"

	
	$servicePrincipal = New-AzADServicePrincipal -DisplayName $displayName -Role $roleDefinitionName
	Assert-NotNull $servicePrincipal
	Assert-AreEqual $servicePrincipal.DisplayName $displayName

	try
	{
		$role = Get-AzRoleAssignment -ObjectId $servicePrincipal.Id
		Assert-AreEqual $role.Count 1
		Assert-AreEqual $role.DisplayName $servicePrincipal.DisplayName
		Assert-AreEqual $role.ObjectId $servicePrincipal.Id
		Assert-AreEqual $role.RoleDefinitionName $roleDefinitionName
		Assert-AreEqual $role.ObjectType "ServicePrincipal"
	}
	finally
	{
		Remove-AzADApplication -ApplicationId $servicePrincipal.ApplicationId -Force
		Remove-AzRoleAssignment -ObjectId $servicePrincipal.Id -RoleDefinitionName $roleDefinitionName
	}
}


function Test-NewADServicePrincipalWithCustomScope
{
	
	$displayName = getAssetName
	$defaultRoleDefinitionName = "Contributor"
	$subscription = Get-AzSubscription | Select -Last 1 -Wait
	$resourceGroup = Get-AzResourceGroup | Select -Last 1 -Wait
	$scope = "/subscriptions/" + $subscription.Id + "/resourceGroups/" + $resourceGroup.ResourceGroupName

	
	$servicePrincipal = New-AzADServicePrincipal -DisplayName $displayName -Scope $scope
	Assert-NotNull $servicePrincipal
	Assert-AreEqual $servicePrincipal.DisplayName $displayName

	try
	{
		$role = Get-AzRoleAssignment -ObjectId $servicePrincipal.Id
		Assert-AreEqual $role.Count 1
		Assert-AreEqual $role.DisplayName $servicePrincipal.DisplayName
		Assert-AreEqual $role.ObjectId $servicePrincipal.Id
		Assert-AreEqual $role.RoleDefinitionName $defaultRoleDefinitionName
		Assert-AreEqual $role.Scope $scope
		Assert-AreEqual $role.ObjectType "ServicePrincipal"
	}
	finally
	{
		Remove-AzADApplication -ApplicationId $servicePrincipal.ApplicationId -Force
		Remove-AzRoleAssignment -ObjectId $servicePrincipal.Id -Scope $scope -RoleDefinitionName $defaultRoleDefinitionName
	}
}


function Test-CreateDeleteAppCredentials
{
    
	$getAssetName = ConvertTo-SecureString "test" -AsPlainText -Force
    $displayName = "test"
    $identifierUri = "http://" + $displayName
    $password = $getAssetName
	$keyId1 = "316af45c-83ff-42a5-a1d1-8fe9b2de3ac1"
	$keyId2 = "9b7fda23-cb39-4504-8aa6-3570c4239620"
	$keyId3 = "4141b479-4ca0-4919-8451-7e155de6aa0f"

    
    $application = New-AzADApplication -DisplayName $displayName -IdentifierUris $identifierUri -Password $password

    
    Assert-NotNull $application
	Try {
    
    $app1 =  Get-AzADApplication -ObjectId $application.ObjectId
    Assert-NotNull $app1

    
    $cred1 = Get-AzADAppCredential -ObjectId $application.ObjectId
    Assert-NotNull $cred1
    Assert-AreEqual $cred1.Count 1

    
    $start = (Get-Date).ToUniversalTime()
    $end = $start.AddYears(1)
    $cred = New-AzADAppCredentialWithId -ObjectId $application.ObjectId -Password $password -StartDate $start -EndDate $end -KeyId $keyId1
    Assert-NotNull $cred

    
    $cred2 = Get-AzADAppCredential -ObjectId $application.ObjectId
    Assert-NotNull $cred2
    Assert-AreEqual $cred2.Count 2
    $credCount = $cred2 | where {$_.KeyId -in $cred1.KeyId, $cred.KeyId}
    Assert-AreEqual $credCount.Count 2
	$cred2 = $cred

	
	$certPath = Join-Path $ResourcesPath "certificate.pfx"
	$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath)

	$binCert = $cert.GetRawCertData()
	$credValue = [System.Convert]::ToBase64String($binCert)
	$start = (Get-Date).ToUniversalTime()
	$end = $start.AddDays(1)
	$cred = New-AzADAppCredentialWithId -ObjectId $application.ObjectId -CertValue $credValue -StartDate $start -EndDate $end -KeyId $keyId2
    Assert-NotNull $cred

    
    $cred3 = Get-AzADAppCredential -ObjectId $application.ObjectId
    Assert-NotNull $cred3
    Assert-AreEqual $cred3.Count 3
    $credCount = $cred3 | where {$_.KeyId -in $cred1.KeyId, $cred2.KeyId, $cred.KeyId}
    Assert-AreEqual $credCount.Count 3
	$cred3 = $cred

	
	$binCert = $cert.GetRawCertData()
	$credValue = [System.Convert]::ToBase64String($binCert)
	$start = (Get-Date).ToUniversalTime()
	$end = $start.AddDays(1)
	$cred = New-AzADAppCredentialWithId -ObjectId $application.ObjectId -CertValue $credValue -StartDate $start -EndDate $end -KeyId $keyId3
    Assert-NotNull $cred

    
    $cred4 = Get-AzADAppCredential -ObjectId $application.ObjectId
    Assert-NotNull $cred4
    Assert-AreEqual $cred4.Count 4
    $credCount = $cred4 | where {$_.KeyId -in $cred1.KeyId, $cred2.KeyId, $cred3.KeyId, $cred.KeyId}
    Assert-AreEqual $credCount.Count 4

    
    Remove-AzADAppCredential -ApplicationId $application.ApplicationId -KeyId $cred.KeyId -Force
    $cred5 = Get-AzADAppCredential -ApplicationId $application.ApplicationId
    Assert-NotNull $cred5
    Assert-AreEqual $cred5.Count 3
    Assert-AreEqual $cred5[2].KeyId $cred1.KeyId

    
    Remove-AzADAppCredential -ObjectId $application.ObjectId -Force
    $cred5 = Get-AzADAppCredential -ObjectId $application.ObjectId
    Assert-Null $cred5                     
	 
    $newApplication = Get-AzADApplication -DisplayNameStartWith "PowershellTestingApp"
    Assert-Throws { New-AzADAppCredential -ApplicationId $newApplication.ApplicationId -Password "Somedummypwd"}
	}
	Finally{
		
		Remove-AzADApplication -ObjectId $application.ObjectId -Force
	}
}



function Test-CreateDeleteSpCredentials
{
	param([string]$applicationId)

    
	$getAssetName = ConvertTo-SecureString "test" -AsPlainText -Force
    $displayName = "test"
    $identifierUri = "http://" + $displayName
	$password = $getAssetName
	$keyId1 = "316af45c-83ff-42a5-a1d1-8fe9b2de3ac1"
	$keyId2 = "9b7fda23-cb39-4504-8aa6-3570c4239620"
	$keyId3 = "4141b479-4ca0-4919-8451-7e155de6aa0f"

    
    $servicePrincipal = New-AzADServicePrincipal -DisplayName $displayName -ApplicationId $applicationId

    
    Assert-NotNull $servicePrincipal

    Try
    {
    
    $sp1 =  Get-AzADServicePrincipal -ObjectId $servicePrincipal.Id
    Assert-NotNull $sp1.Id

    
    $cred1 = Get-AzADSpCredential -ObjectId $servicePrincipal.Id
    Assert-NotNull $cred1
    Assert-AreEqual $cred1.Count 1

    
    $start = (Get-Date).ToUniversalTime()
    $end = $start.AddYears(1)
    $cred = New-AzADSpCredentialWithId -ObjectId $servicePrincipal.Id -StartDate $start -EndDate $end -KeyId $keyId1
    Assert-NotNull $cred

    
    $cred2 = Get-AzADSpCredential -ObjectId $servicePrincipal.Id
    Assert-NotNull $cred2
    Assert-AreEqual $cred2.Count 2
    $credCount = $cred2 | where {$_.KeyId -in $cred1.KeyId, $cred.KeyId}
    Assert-AreEqual $credCount.Count 2
	$cred2 = $cred

	
	$certPath = Join-Path $ResourcesPath "certificate.pfx"
	$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath)

	$binCert = $cert.GetRawCertData()
	$credValue = [System.Convert]::ToBase64String($binCert)
	$start = (Get-Date).ToUniversalTime()
	$end = $start.AddDays(1)
	$cred = New-AzADSpCredentialWithId -ObjectId $servicePrincipal.Id -CertValue $credValue -StartDate $start -EndDate $end -KeyId $keyId2
    Assert-NotNull $cred

    
    $cred3 = Get-AzADSpCredential -ObjectId $servicePrincipal.Id
    Assert-NotNull $cred3
    Assert-AreEqual $cred3.Count 3
    $credCount = $cred3 | where {$_.KeyId -in $cred1.KeyId, $cred2.KeyId, $cred.KeyId}
    Assert-AreEqual $credCount.Count 3
	$cred3 = $cred

	
	$binCert = $cert.GetRawCertData()
	$credValue = [System.Convert]::ToBase64String($binCert)
	$start = (Get-Date).ToUniversalTime()
	$end = $start.AddDays(1)
	$cred = New-AzADSpCredentialWithId -ObjectId $servicePrincipal.Id -CertValue $credValue -StartDate $start -EndDate $end -KeyId $keyId3
    Assert-NotNull $cred

    
    $cred4 = Get-AzADSpCredential -ObjectId $servicePrincipal.Id
    Assert-NotNull $cred4
    Assert-AreEqual $cred4.Count 4
    $credCount = $cred4 | where {$_.KeyId -in $cred1.KeyId, $cred2.KeyId, $cred3.KeyId, $cred.KeyId}
    Assert-AreEqual $credCount.Count 4


    
    Remove-AzADSpCredential -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[0] -KeyId $cred.KeyId -Force
    $cred5 = Get-AzADSpCredential -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[0]
    Assert-NotNull $cred5
    Assert-AreEqual $cred5.Count 3
    Assert-AreEqual $cred5[2].KeyId $cred1.KeyId

    
    Remove-AzADSpCredential -ObjectId $servicePrincipal.Id -Force
    $cred5 = Get-AzADSpCredential -ObjectId $servicePrincipal.Id
    Assert-Null $cred5
    }
    Finally
    {
		
		Remove-AzADServicePrincipal -ObjectId $servicePrincipal.Id -Force
    }
}


function Test-RemoveServicePrincipalWithNameNotFound
{
    $FakeServicePrincipalName = "this is a fake service principal name and there are no way this can be valid"

    Assert-ThrowsContains {Remove-AzADServicePrincipal -ServicePrincipalName $FakeServicePrincipalName} "Could not find a service principal with the name"
}