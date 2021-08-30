














function Test-RaClassicAdmins
{
    
    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"
    $subscription = $(Get-AzureRmContext).Subscription

    
    $classic =  Get-AzureRmRoleAssignment -IncludeClassicAdministrators  | Where-Object { $_.Scope -ieq ('/subscriptions/' + $subscription[0].Id) -and $_.RoleDefinitionName -ieq 'ServiceAdministrator;AccountAdministrator' }
	
    
    Assert-NotNull $classic
    Assert-True { $classic.Length -ge 1 }
}


function Test-RaClassicAdminsWithScope
{
    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"
    
    $subscription = Get-AzureRmSubscription

    
    $classic = Get-AzureRmRoleAssignment -Scope ("/subscriptions/" + $subscription[0].Id) -IncludeClassicAdministrators | Where-Object { $_.Scope.ToLower().Contains("/subscriptions/" + $subscription[0].Id) -and $_.RoleDefinitionName -ieq 'ServiceAdministrator;AccountAdministrator' }

    
    Assert-NotNull $classic
    Assert-True { $classic.Length -ge 1 }

    
    $classic = Get-AzureRmRoleAssignment -Scope ("/subscriptions/" + $subscription[1].Id) -IncludeClassicAdministrators | Where-Object { $_.Scope.ToLower().Contains("/subscriptions/" + $subscription[1].Id) -and $_.RoleDefinitionName -ieq 'ServiceAdministrator;AccountAdministrator' }

    
    Assert-NotNull $classic
    Assert-True { $classic.Length -ge 1 }
}


function Test-RaNegativeScenarios
{
    
     Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"

    $subscription = $(Get-AzureRmContext).Subscription

    
    $badOid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    $badObjectResult = "Cannot find principal using the specified options"
	$assignments = Get-AzureRmRoleAssignment -ObjectId $badOid
    Assert-AreEqual 0 $assignments.Count

	
	Assert-Throws { Get-AzureRmRoleAssignment -ObjectId $badOid -ExpandPrincipalGroups } $badObjectResult

    
    $badUpn = 'nonexistent@provider.com'
    Assert-Throws { Get-AzureRmRoleAssignment -UserPrincipalName $badUpn } $badObjectResult
    
    
    $badSpn = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
    Assert-Throws { Get-AzureRmRoleAssignment -ServicePrincipalName $badSpn } $badObjectResult
    
    
    $badScope = '/subscriptions/'+ $subscription[0].Id +'/providers/nonexistent'
    $badScopeException = "InvalidResourceNamespace: The resource namespace 'nonexistent' is invalid."
    Assert-Throws { Get-AzureRmRoleAssignment -Scope $badScope } $badScopeException
}


function Test-RaByScope
{
    
    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"

    $definitionName = 'Reader'
    $users = Get-AzureRmADUser | Select-Object -First 1 -Wait
    $subscription = $(Get-AzureRmContext).Subscription
    $resourceGroups = Get-AzureRmResourceGroup | Select-Object -Last 1 -Wait
    $scope = '/subscriptions/'+ $subscription[0].Id +'/resourceGroups/' + $resourceGroups[0].ResourceGroupName
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."
    
    
    [Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleAssignmentNames.Enqueue("fa1a4d3b-2cca-406b-8956-6b6b32377641")
    $newAssignment = New-AzureRmRoleAssignment `
                        -ObjectId $users[0].Id.Guid `
                        -RoleDefinitionName $definitionName `
                        -Scope $scope 
    
    
    DeleteRoleAssignment $newAssignment

    
    Assert-NotNull $newAssignment
    Assert-AreEqual	$definitionName $newAssignment.RoleDefinitionName 
    Assert-AreEqual	$scope $newAssignment.Scope 
    Assert-AreEqual	$users[0].DisplayName $newAssignment.DisplayName
    
    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaByResourceGroup
{
    
    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"

    $definitionName = 'Contributor'
    $users = Get-AzureRmADUser | Select-Object -Last 1 -Wait
    $resourceGroups = Get-AzureRmResourceGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."
    Assert-AreEqual 1 $resourceGroups.Count "No resource group found. Unable to run the test."

    
    [Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleAssignmentNames.Enqueue("7a750d57-9d92-4be1-ad66-f099cecffc01")
    $newAssignment = New-AzureRmRoleAssignment `
                        -ObjectId $users[0].Id.Guid `
                        -RoleDefinitionName $definitionName `
                        -ResourceGroupName $resourceGroups[0].ResourceGroupName
    
    
    DeleteRoleAssignment $newAssignment
    
    
    Assert-NotNull $newAssignment
    Assert-AreEqual	$definitionName $newAssignment.RoleDefinitionName 
    Assert-AreEqual	$users[0].DisplayName $newAssignment.DisplayName
    
    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaByResource
{
    
    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"

    $definitionName = 'Owner'
    $groups = Get-AzureRmADGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $groups.Count "There should be at least one group to run the test."
    $resourceGroups = Get-AzureRmResourceGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $resourceGroups.Count "No resource group found. Unable to run the test."
    $resource = Get-AzureRmResource | Select-Object -Last 1 -Wait
    Assert-NotNull $resource "Cannot find any resource to continue test execution."

    
    [Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleAssignmentNames.Enqueue("78D6502F-74FC-4800-BB0A-0E1A7BEBECA4")
    $newAssignment = New-AzureRmRoleAssignment `
                        -ObjectId $groups[0].Id.Guid `
                        -RoleDefinitionName $definitionName `
                        -ResourceGroupName $resource.ResourceGroupName `
                        -ResourceType $resource.ResourceType `
                        -ResourceName $resource.Name
    
    
    DeleteRoleAssignment $newAssignment
    
    
    Assert-NotNull $newAssignment
    Assert-AreEqual	$definitionName $newAssignment.RoleDefinitionName 
    Assert-AreEqual	$groups[0].DisplayName $newAssignment.DisplayName
    
    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaByServicePrincipal
{
    
    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"

    $definitionName = 'Reader'
    $servicePrincipals = Get-AzureRmADServicePrincipal | Select-Object -Last 1 -Wait
    $subscription = $(Get-AzureRmContext).Subscription
    $resourceGroups = Get-AzureRmResourceGroup | Select-Object -Last 1 -Wait
    $scope = '/subscriptions/'+ $subscription[0].Id +'/resourceGroups/' + $resourceGroups[0].ResourceGroupName
    Assert-AreEqual 1 $servicePrincipals.Count "No service principals found. Unable to run the test."

    
    [Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleAssignmentNames.Enqueue("a4b82891-ebee-4568-b606-632899bf9453")
    $newAssignment = New-AzureRmRoleAssignment `
                        -ServicePrincipalName $servicePrincipals[0].ServicePrincipalNames[0] `
                        -RoleDefinitionName $definitionName `
                        -Scope $scope 
                        
    
    
    DeleteRoleAssignment $newAssignment
    
    
    Assert-NotNull $newAssignment
    Assert-AreEqual	$definitionName $newAssignment.RoleDefinitionName 
    Assert-AreEqual	$scope $newAssignment.Scope 
    Assert-AreEqual	$servicePrincipals[0].DisplayName $newAssignment.DisplayName
    
    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaByUpn
{
    
    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"

    $definitionName = 'Contributor'
    $users = Get-AzureRmADUser | Select-Object -Last 1 -Wait
    $resourceGroups = Get-AzureRmResourceGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."
    Assert-AreEqual 1 $resourceGroups.Count "No resource group found. Unable to run the test."

    
	[Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleAssignmentNames.Enqueue("8E052D34-3F84-4083-BA00-5E8772F7D46D")
    $newAssignment = New-AzureRmRoleAssignment `
                        -SignInName $users[0].UserPrincipalName `
                        -RoleDefinitionName $definitionName `
                        -ResourceGroupName $resourceGroups[0].ResourceGroupName
    
    
    DeleteRoleAssignment $newAssignment
    
    
    Assert-NotNull $newAssignment
    Assert-AreEqual	$definitionName $newAssignment.RoleDefinitionName 
    Assert-AreEqual	$users[0].DisplayName $newAssignment.DisplayName

    VerifyRoleAssignmentDeleted $newAssignment
}

 
function Test-RaUserPermissions 
{ 
    param([string]$rgName, [string]$action) 
    
    
    
    
    $rg = Get-AzureRmResourceGroup
	$errorMsg = "User should have access to only 1 RG. Found: {0}" -f $rg.Count
	Assert-AreEqual 1 $rg.Count $errorMsg

	
	Assert-Throws{ New-AzureRmResourceGroup -Name 'NewGroupFromTest' -Location 'WestUS'}        
}


function Test-RaAuthorizationChangeLog
{
	$log1 = Get-AzureRmAuthorizationChangeLog -startTime 2016-07-28 -EndTime 2016-07-28T22:30:00Z

	
	Assert-True { $log1.Count -ge 1 } "At least one record should be returned for the user"
}




function CreateRoleAssignment
{
    param([string]$roleAssignmentId, [string]$userId, [string]$definitionName, [string]$resourceGroupName) 

    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"

    [Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleAssignmentNames.Enqueue($roleAssignmentId)
    $newAssignment = New-AzureRmRoleAssignment `
                        -ObjectId $userId `
                        -RoleDefinitionName $definitionName `
                        -ResourceGroupName $resourceGroupName

    return $newAssignment
}


function DeleteRoleAssignment
{
    param([Parameter(Mandatory=$true)] [object] $roleAssignment)
    
    Remove-AzureRmRoleAssignment -ObjectId $roleAssignment.ObjectId.Guid `
                               -Scope $roleAssignment.Scope `
                               -RoleDefinitionName $roleAssignment.RoleDefinitionName
}


function VerifyRoleAssignmentDeleted
{
    param([Parameter(Mandatory=$true)] [object] $roleAssignment)
    
    $deletedRoleAssignment = Get-AzureRmRoleAssignment -ObjectId $roleAssignment.ObjectId.Guid `
                                                     -Scope $roleAssignment.Scope `
                                                     -RoleDefinitionName $roleAssignment.RoleDefinitionName  | where {$_.roleAssignmentId -eq $roleAssignment.roleAssignmentId}
    Assert-Null $deletedRoleAssignment
}