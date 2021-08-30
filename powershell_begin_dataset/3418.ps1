














function Test-GetAllADGroups
{
    
    $groups = Get-AzureRmADGroup

    
    Assert-NotNull($groups)
    foreach($group in $groups) {
        Assert-NotNull($group.DisplayName)
        Assert-NotNull($group.Id)
    }
}


function Test-GetADGroupWithSearchString 
{
    param([string]$displayName)
    
    
    
    $groups = Get-AzureRmADGroup -SearchString $displayName

    
    Assert-AreEqual $groups.Count 1
    Assert-NotNull $groups[0].Id
    Assert-AreEqual $groups[0].DisplayName $displayName
}


function Test-GetADGroupWithBadSearchString
{
    
    
    $groups = Get-AzureRmADGroup -SearchString "BadSearchString"

    
    Assert-Null($groups)
}


function Test-GetADGroupWithObjectId
{
    param([string]$objectId)
    
    
    $groups = Get-AzureRmADGroup -ObjectId $objectId

    
    Assert-AreEqual $groups.Count 1
    Assert-AreEqual $groups[0].Id $objectId
    Assert-NotNull($groups[0].DisplayName)
}


function Test-GetADGroupSecurityEnabled
{
    param([string]$objectId, [string]$securityEnabled)
    
    
    $groups = Get-AzureRmADGroup -ObjectId $objectId

    
    Assert-AreEqual $groups.Count 1
    Assert-AreEqual $groups[0].Id $objectId
    Assert-AreEqual $groups[0].SecurityEnabled $securityEnabled
    Assert-NotNull($groups[0].DisplayName)
}


function Test-GetADGroupWithBadObjectId
{
    
    $groups = Get-AzureRmADGroup -ObjectId "baadc0de-baad-c0de-baad-c0debaadc0de"

    
    Assert-Null $groups
}


function Test-GetADGroupWithUserObjectId
{
    param([string]$objectId)

    
    $groups = Get-AzureRmADGroup -ObjectId $objectId

    
    Assert-Null $groups
}


function Test-GetADGroupMemberWithGroupObjectId
{
    param([string]$groupObjectId, [string]$userObjectId, [string]$userName)

    
    $members = Get-AzureRmADGroupMember -GroupObjectId $groupObjectId
    
    
    Assert-AreEqual $members.Count 1
    Assert-AreEqual $members[0].Id $userObjectId
    Assert-AreEqual $members[0].DisplayName $userName
}


function Test-GetADGroupMemberWithBadGroupObjectId
{
    
    Assert-Throws { Get-AzureRmADGroupMember -GroupObjectId "baadc0de-baad-c0de-baad-c0debaadc0de" }    
}


function Test-GetADGroupMemberWithUserObjectId
{
    param([string]$objectId)

    
    Assert-Throws { Get-AzureRmADGroupMember -GroupObjectId $objectId }    
}


function Test-GetADGroupMemberFromEmptyGroup
{
    param([string]$objectId)

    
    $members = Get-AzureRmADGroupMember -GroupObjectId $objectId
    
    
    Assert-Null($members)
}


function Test-GetADServicePrincipalWithObjectId
{
    param([string]$objectId)

    
    $servicePrincipals = Get-AzureRmADServicePrincipal -ObjectId $objectId

    
    Assert-AreEqual $servicePrincipals.Count 1
    Assert-AreEqual $servicePrincipals[0].Id $objectId
}


function Test-GetADServicePrincipalWithBadObjectId
{
    
    $servicePrincipals = Get-AzureRmADServicePrincipal -ObjectId "baadc0de-baad-c0de-baad-c0debaadc0de"

    
    Assert-Null($servicePrincipals)
}


function Test-GetADServicePrincipalWithUserObjectId
{
    param([string]$objectId)

    
    $servicePrincipals = Get-AzureRmADServicePrincipal -ObjectId $objectId

    
    Assert-Null($servicePrincipals)
}


function Test-GetADServicePrincipalWithSPN
{
    param([string]$SPN)

    
    $servicePrincipals = Get-AzureRmADServicePrincipal -ServicePrincipalName $SPN

    
    Assert-AreEqual $servicePrincipals.Count 1
    Assert-NotNull $servicePrincipals[0].Id
	Assert-True { $servicePrincipals[0].ServicePrincipalNames.Contains($SPN) }
}


function Test-GetADServicePrincipalWithBadSPN
{
    
    $servicePrincipals = Get-AzureRmADServicePrincipal -ServicePrincipalName "badspn"

    
    Assert-Null($servicePrincipals)
}


function Test-GetADServicePrincipalWithSearchString
{
    param([string]$displayName)

    
    $servicePrincipals = Get-AzureRmADServicePrincipal -SearchString $displayName

    
    Assert-AreEqual $servicePrincipals.Count 1
    Assert-AreEqual $servicePrincipals[0].DisplayName $displayName
    Assert-NotNull($servicePrincipals[0].Id)
    Assert-NotNull($servicePrincipals[0].ServicePrincipalNames)
	Assert-AreEqual $servicePrincipals[0].ServicePrincipalNames.Count 2
}


function Test-GetADServicePrincipalWithBadSearchString
{
    
    $servicePrincipals = Get-AzureRmADServicePrincipal -SearchString "badsearchstring"

    
    Assert-Null($servicePrincipals)
}


function Test-GetAllADUser
{
    
    $users = Get-AzureRmADUser

    
    Assert-NotNull($users)
    foreach($user in $users) {
        Assert-NotNull($user.DisplayName)
        Assert-NotNull($user.Id)
    }
}


function Test-GetADUserWithObjectId
{
    param([string]$objectId)

    
    $users = Get-AzureRmADUser -ObjectId $objectId

    
    Assert-AreEqual $users.Count 1
    Assert-AreEqual $users[0].Id $objectId
    Assert-NotNull($users[0].DisplayName)
    Assert-NotNull($users[0].UserPrincipalName)
}



function Test-GetADUserWithMail
{
    param([string]$mail)

    
    $users = Get-AzureRmADUser -Mail $mail

    
    Assert-AreEqual $users.Count 1
    
    Assert-NotNull($users[0].DisplayName)
    Assert-NotNull($users[0].UserPrincipalName)
}


function Test-GetADUserWithBadObjectId
{
    
    $users = Get-AzureRmADUser -ObjectId "baadc0de-baad-c0de-baad-c0debaadc0de"

    
    Assert-Null($users)
}


function Test-GetADUserWithGroupObjectId
{
    param([string]$objectId)

    
    $users = Get-AzureRmADUser -ObjectId $objectId

    
    Assert-Null($users)
}


function Test-GetADUserWithUPN
{
    param([string]$UPN)

    
    $users = Get-AzureRmADUser -UserPrincipalName $UPN

    
    Assert-AreEqual $users.Count 1
    Assert-AreEqual $users[0].UserPrincipalName $UPN
    Assert-NotNull($users[0].DisplayName)
    Assert-NotNull($users[0].Id)
}


function Test-GetADUserWithFPOUPN
{
    
    $users = Get-AzureRmADUser -UserPrincipalName "azsdkposhteam_outlook.com

    
    Assert-AreEqual $users.Count 1
    Assert-AreEqual $users[0].UserPrincipalName "azsdkposhteam_outlook.com
    Assert-NotNull($users[0].DisplayName)
    Assert-NotNull($users[0].Id)
}


function Test-GetADUserWithBadUPN
{
    
    $users = Get-AzureRmADUser -UserPrincipalName "baduser@rbactest.onmicrosoft.com"

    
    Assert-Null($users)
}


function Test-GetADUserWithSearchString
{
    param([string]$displayName)

    
    
    $users = Get-AzureRmADUser -SearchString $displayName

    
    Assert-NotNull($users)
    Assert-AreEqual $users[0].DisplayName $displayName
    Assert-NotNull($users[0].Id)
    Assert-NotNull($users[0].UserPrincipalName)
}


function Test-GetADUserWithBadSearchString
{
    
    
    $users = Get-AzureRmADUser -SearchString "badsearchstring"

    
    Assert-Null($users)
}


function Test-NewADApplication
{
    
    $displayName = getAssetName
    $homePage = "http://" + $displayName + ".com"
    $identifierUri = "http://" + $displayName

    
    $application = New-AzureRmADApplication -DisplayName $displayName -HomePage $homePage -IdentifierUris $identifierUri

    
    Assert-NotNull $application

	
	$app1 =  Get-AzureRmADApplication -ObjectId $application.ObjectId
	Assert-NotNull $app1
	Assert-AreEqual $app1.Count 1

	
	$app1 =  Get-AzureRmADApplication -ApplicationId $application.ApplicationId
	Assert-NotNull $app1
	Assert-AreEqual $app1.Count 1

	
	$app1 = Get-AzureRmADApplication -IdentifierUri $application.IdentifierUris[0]
	Assert-NotNull $app1
	Assert-AreEqual $app1.Count 1

	
	$app1 = Get-AzureRmADApplication -DisplayNameStartWith $application.DisplayName
	Assert-NotNull $app1
	Assert-True { $app1.Count -ge 1}

	$newDisplayName = getAssetName
    $newHomePage = "http://" + $newDisplayName + ".com"
    $newIdentifierUri = "http://" + $newDisplayName
	
	
	Set-AzureRmADApplication -ObjectId $application.ObjectId -DisplayName $newDisplayName -HomePage $newHomePage

	
	Set-AzureRmADApplication -ApplicationId $application.ApplicationId -IdentifierUris $newIdentifierUri
	
	
	$app1 =  Get-AzureRmADApplication -ObjectId $application.ObjectId
	Assert-NotNull $app1
	Assert-AreEqual $app1.Count 1
	Assert-AreEqual $app1.DisplayName $newDisplayName
	Assert-AreEqual $app1.HomePage $newHomePage
	Assert-AreEqual $app1.IdentifierUris[0] $newIdentifierUri

	
	Remove-AzureRmADApplication -ObjectId $application.ObjectId -Force
}


function Test-NewADServicePrincipal
{
    param([string]$applicationId)

    
    $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $applicationId

    
    Assert-NotNull $servicePrincipal

	
	$sp1 = Get-AzureRmADServicePrincipal -ObjectId $servicePrincipal.Id
	Assert-NotNull $sp1
	Assert-AreEqual $sp1.Count 1
	Assert-AreEqual $sp1.Id $servicePrincipal.Id

	
	$sp1 = Get-AzureRmADServicePrincipal -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[0]
	Assert-NotNull $sp1
	Assert-AreEqual $sp1.Count 1
	Assert-True { $sp1.ServicePrincipalNames.Contains($servicePrincipal.ServicePrincipalNames[0]) }

	
	Remove-AzureRmADServicePrincipal -ObjectId $servicePrincipal.Id -Force
}


function Test-NewADServicePrincipalWithoutApp
{	
	
    $displayName = getAssetName

    
    $servicePrincipal = New-AzureRmADServicePrincipal -DisplayName $displayName

    
    Assert-NotNull $servicePrincipal
	Assert-AreEqual $servicePrincipal.DisplayName $displayName

	
	$sp1 = Get-AzureRmADServicePrincipal -ObjectId $servicePrincipal.Id
	Assert-NotNull $sp1
	Assert-AreEqual $sp1.Count 1
	Assert-AreEqual $sp1.Id $servicePrincipal.Id

	
	$sp1 = Get-AzureRmADServicePrincipal -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[0]
	Assert-NotNull $sp1
	Assert-AreEqual $sp1.Count 1
	Assert-True { $sp1.ServicePrincipalNames.Contains($servicePrincipal.ServicePrincipalNames[0]) }

	
	$app1 =  Get-AzureRmADApplication -ApplicationId $servicePrincipal.ApplicationId
	Assert-NotNull $app1
	Assert-AreEqual $app1.Count 1

	
	$newDisplayName = getAssetName
	
	Set-AzureRmADServicePrincipal -ObjectId $servicePrincipal.Id -DisplayName $newDisplayName

	
	$sp1 = Get-AzureRmADServicePrincipal -ObjectId $servicePrincipal.Id
	Assert-NotNull $sp1
	Assert-AreEqual $sp1.Count 1
	Assert-AreEqual $sp1.DisplayName $newDisplayName

	
	Remove-AzureRmADApplication -ObjectId $app1.ObjectId -Force

	Assert-Throws { Remove-AzureRmADServicePrincipal -ObjectId $servicePrincipal.Id -Force}
}


function Test-CreateDeleteAppPasswordCredentials
{	
    
    $displayName = getAssetName
    $identifierUri = "http://" + $displayName
	$password = getAssetName

    
    $application = New-AzureRmADApplication -DisplayName $displayName -IdentifierUris $identifierUri -Password $password

    
    Assert-NotNull $application

	
	$app1 =  Get-AzureRmADApplication -ObjectId $application.ObjectId
	Assert-NotNull $app1

	
	$cred1 = Get-AzureRmADAppCredential -ObjectId $application.ObjectId
	Assert-NotNull $cred1
	Assert-AreEqual $cred1.Count 1

	
	$start = (Get-Date).ToUniversalTime()
	$end = $start.AddYears(1)
	$cred = New-AzureRmADAppCredential -ObjectId $application.ObjectId -Password $password -StartDate $start -EndDate $end
	Assert-NotNull $cred

	
	$cred2 = Get-AzureRmADAppCredential -ObjectId $application.ObjectId
	Assert-NotNull $cred2
	Assert-AreEqual $cred2.Count 2
	$credCount = $cred2 | where {$_.KeyId -in $cred1.KeyId, $cred.KeyId}
	Assert-AreEqual $credCount.Count 2

	
	Remove-AzureRmADAppCredential -ApplicationId $application.ApplicationId -KeyId $cred.KeyId -Force
	$cred3 = Get-AzureRmADAppCredential -ApplicationId $application.ApplicationId 
	Assert-NotNull $cred3
	Assert-AreEqual $cred3.Count 1
	Assert-AreEqual $cred3[0].KeyId $cred1.KeyId

	
	Remove-AzureRmADAppCredential -ObjectId $application.ObjectId -All -Force
	$cred3 = Get-AzureRmADAppCredential -ObjectId $application.ObjectId
	Assert-Null $cred3

	
	Remove-AzureRmADApplication -ObjectId $application.ObjectId -Force
}



function Test-CreateDeleteSpPasswordCredentials
{	
    
    $displayName = getAssetName
	$password = getAssetName

    
	$servicePrincipal = New-AzureRmADServicePrincipal -DisplayName $displayName  -Password $password

    
    Assert-NotNull $servicePrincipal

	Try
	{
	
	$sp1 =  Get-AzureRmADServicePrincipal -ObjectId $servicePrincipal.Id
	Assert-NotNull $sp1.Id

	
	$cred1 = Get-AzureRmADSpCredential -ObjectId $servicePrincipal.Id
	Assert-NotNull $cred1
	Assert-AreEqual $cred1.Count 1

	
	$start = (Get-Date).ToUniversalTime()
	$end = $start.AddYears(1)
	$cred = New-AzureRmADSpCredential -ObjectId $servicePrincipal.Id -Password $password -StartDate $start -EndDate $end
	Assert-NotNull $cred

	
	$cred2 = Get-AzureRmADSpCredential -ObjectId $servicePrincipal.Id
	Assert-NotNull $cred2
	Assert-AreEqual $cred2.Count 2
	$credCount = $cred2 | where {$_.KeyId -in $cred1.KeyId, $cred.KeyId}
	Assert-AreEqual $credCount.Count 2

	
	Remove-AzureRmADSpCredential -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[0] -KeyId $cred.KeyId -Force
	$cred3 = Get-AzureRmADSpCredential -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[0] 
	Assert-NotNull $cred3
	Assert-AreEqual $cred3.Count 1
	Assert-AreEqual $cred3[0].KeyId $cred1.KeyId

	
	Remove-AzureRmADSpCredential -ObjectId $servicePrincipal.Id -All -Force
	$cred3 = Get-AzureRmADSpCredential -ObjectId $servicePrincipal.Id
	Assert-Null $cred3
    }
	Finally
	{
	  
	  $app =  Get-AzureRmADApplication -ApplicationId $servicePrincipal.ApplicationId
	  Remove-AzureRmADApplication -ObjectId $app.ObjectId -Force
	}
}