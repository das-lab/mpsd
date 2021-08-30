














function Test-GetReservationOrder
{
    
    
    
	$type = "Microsoft.Capacity/reservationOrders"
	$reservationOrderId = "704aee8c-c906-47c7-bd22-781841fb48b5"
    $reservation = Get-AzReservationOrder -ReservationOrderId $reservationOrderId

	Assert-NotNull $reservation
	Assert-True { $reservation.Etag -gt 0 }
	$expectedId = "/providers/microsoft.capacity/reservationOrders/" + $reservationOrderId
	Assert-AreEqual $expectedId $reservation.Id
	Assert-AreEqual $reservationOrderId $reservation.Name
	Assert-AreEqual $type $reservation.Type
}


function Test-ListReservationOrders
{
	$type = "Microsoft.Capacity/reservationOrders"

    $reservationList = Get-AzReservationOrder

	Assert-NotNull $reservationList
	Foreach ($reservation in $reservationList)
	{
		Assert-NotNull $reservation
		Assert-True { $reservation.Etag -gt 0 }
		Assert-NotNull $reservation.Name
		$expectedId = "/providers/microsoft.capacity/reservationOrders/" + $reservation.Name
		Assert-AreEqual $expectedId $reservation.Id
		Assert-AreEqual $type $reservation.Type
	}

}
