




















function Test-ListReservationSummariesMonthlyWithOrderId
{
    $reservationSummaries = Get-AzConsumptionReservationSummary -Grain monthly -ReservationOrderId ca69259e-bd4f-45c3-bf28-3f353f9cce9b
	Assert-NotNull $reservationSummaries	
	Foreach($reservationSummary in $reservationSummaries)
	{
		Assert-NotNull $reservationSummary.AveUtilizationPercentage
		Assert-NotNull $reservationSummary.Id
		Assert-NotNull $reservationSummary.MaxUtilizationPercentage
		Assert-NotNull $reservationSummary.MinUtilizationPercentage
		Assert-NotNull $reservationSummary.Name
		Assert-NotNull $reservationSummary.ReservationId
		Assert-NotNull $reservationSummary.ReservationOrderId
		Assert-NotNull $reservationSummary.ReservedHour
		Assert-NotNull $reservationSummary.SkuName
		Assert-NotNull $reservationSummary.Type
		Assert-NotNull $reservationSummary.UsageDate
		Assert-NotNull $reservationSummary.UsedHour
	}
}


function Test-ListReservationSummariesMonthlyWithOrderIdAndId
{
    $reservationSummaries = Get-AzConsumptionReservationSummary -Grain monthly -ReservationOrderId ca69259e-bd4f-45c3-bf28-3f353f9cce9b -ReservationId f37f4b70-52ba-4344-a8bd-28abfd21d640
	Assert-NotNull $reservationSummaries	
	Foreach($reservationSummary in $reservationSummaries)
	{
		Assert-NotNull $reservationSummary.AveUtilizationPercentage
		Assert-NotNull $reservationSummary.Id
		Assert-NotNull $reservationSummary.MaxUtilizationPercentage
		Assert-NotNull $reservationSummary.MinUtilizationPercentage
		Assert-NotNull $reservationSummary.Name
		Assert-NotNull $reservationSummary.ReservationId
		Assert-NotNull $reservationSummary.ReservationOrderId
		Assert-NotNull $reservationSummary.ReservedHour
		Assert-NotNull $reservationSummary.SkuName
		Assert-NotNull $reservationSummary.Type
		Assert-NotNull $reservationSummary.UsageDate
		Assert-NotNull $reservationSummary.UsedHour
	}
}


function Test-ListReservationSummariesDailyWithOrderId
{
    $reservationSummaries = Get-AzConsumptionReservationSummary -Grain daily -ReservationOrderId ca69259e-bd4f-45c3-bf28-3f353f9cce9b -StartDate 2017-10-01 -EndDate 2017-12-07
	Assert-NotNull $reservationSummaries	
	Foreach($reservationSummary in $reservationSummaries)
	{
		Assert-NotNull $reservationSummary.AveUtilizationPercentage
		Assert-NotNull $reservationSummary.Id
		Assert-NotNull $reservationSummary.MaxUtilizationPercentage
		Assert-NotNull $reservationSummary.MinUtilizationPercentage
		Assert-NotNull $reservationSummary.Name
		Assert-NotNull $reservationSummary.ReservationId
		Assert-NotNull $reservationSummary.ReservationOrderId
		Assert-NotNull $reservationSummary.ReservedHour
		Assert-NotNull $reservationSummary.SkuName
		Assert-NotNull $reservationSummary.Type
		Assert-NotNull $reservationSummary.UsageDate
		Assert-NotNull $reservationSummary.UsedHour
	}
}


function Test-ListReservationSummariesDailyWithOrderIdAndId
{
    $reservationSummaries = Get-AzConsumptionReservationSummary -Grain daily -ReservationOrderId ca69259e-bd4f-45c3-bf28-3f353f9cce9b -ReservationId f37f4b70-52ba-4344-a8bd-28abfd21d640 -StartDate 2017-10-01 -EndDate 2017-12-07
	Assert-NotNull $reservationSummaries	
	Foreach($reservationSummary in $reservationSummaries)
	{
		Assert-NotNull $reservationSummary.AveUtilizationPercentage
		Assert-NotNull $reservationSummary.Id
		Assert-NotNull $reservationSummary.MaxUtilizationPercentage
		Assert-NotNull $reservationSummary.MinUtilizationPercentage
		Assert-NotNull $reservationSummary.Name
		Assert-NotNull $reservationSummary.ReservationId
		Assert-NotNull $reservationSummary.ReservationOrderId
		Assert-NotNull $reservationSummary.ReservedHour
		Assert-NotNull $reservationSummary.SkuName
		Assert-NotNull $reservationSummary.Type
		Assert-NotNull $reservationSummary.UsageDate
		Assert-NotNull $reservationSummary.UsedHour
	}
}


function Test-ListReservationDetailsWithOrderId
{
    $reservationDetails = Get-AzConsumptionReservationDetail -ReservationOrderId ca69259e-bd4f-45c3-bf28-3f353f9cce9b -StartDate 2017-10-01 -EndDate 2017-12-07
	Assert-NotNull $reservationDetails	
	Foreach($reservationDetail in $reservationDetails)
	{
		Assert-NotNull $reservationDetail.Id
		Assert-NotNull $reservationDetail.InstanceId
		Assert-NotNull $reservationDetail.Name
		Assert-NotNull $reservationDetail.ReservationId
		Assert-NotNull $reservationDetail.ReservationOrderId
		Assert-NotNull $reservationDetail.ReservedHour
		Assert-NotNull $reservationDetail.SkuName
		Assert-NotNull $reservationDetail.TotalReservedQuantity
		Assert-NotNull $reservationDetail.Type
		Assert-NotNull $reservationDetail.UsageDate
		Assert-NotNull $reservationDetail.UsedHour
	}
}


function Test-ListReservationDetailsWithOrderIdAndId
{
    $reservationDetails = Get-AzConsumptionReservationDetail -ReservationOrderId ca69259e-bd4f-45c3-bf28-3f353f9cce9b -ReservationId f37f4b70-52ba-4344-a8bd-28abfd21d640 -StartDate 2017-10-01 -EndDate 2017-12-07
	Assert-NotNull $reservationDetails	
	Foreach($reservationDetail in $reservationDetails)
	{
		Assert-NotNull $reservationDetail.Id
		Assert-NotNull $reservationDetail.InstanceId
		Assert-NotNull $reservationDetail.Name
		Assert-NotNull $reservationDetail.ReservationId
		Assert-NotNull $reservationDetail.ReservationOrderId
		Assert-NotNull $reservationDetail.ReservedHour
		Assert-NotNull $reservationDetail.SkuName
		Assert-NotNull $reservationDetail.TotalReservedQuantity
		Assert-NotNull $reservationDetail.Type
		Assert-NotNull $reservationDetail.UsageDate
		Assert-NotNull $reservationDetail.UsedHour
	}
}