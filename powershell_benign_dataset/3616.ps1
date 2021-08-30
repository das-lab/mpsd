














function Test-AddAzureRmAutoscaleSetting
{
	
	$resourceId = "/subscriptions/b67f7fec-69fc-4974-9099-a26bd6ffeda3/resourceGroups/TestingMetricsScaleSet/providers/Microsoft.Compute/virtualMachineScaleSets/testingsc"
	$resourceGroup = "TestingMetricsScaleSet"

    
    

	$rule1 = New-AzAutoscaleRule -MetricName Requests -MetricResourceId $resourceId -Operator GreaterThan -MetricStatistic Average -Threshold 10 -TimeGrain 00:01:00 -ScaleActionCooldown 00:05:00 -ScaleActionDirection Increase -ScaleActionValue "1"
	$rule2 = New-AzAutoscaleRule -MetricName Requests -MetricResourceId $resourceId -Operator GreaterThan -MetricStatistic Average -Threshold 15 -TimeGrain 00:02:00 -ScaleActionCooldown 00:06:00 -ScaleActionDirection Decrease -ScaleActionValue "2"
	$profile1 = New-AzAutoscaleProfile -DefaultCapacity "1" -MaximumCapacity "10" -MinimumCapacity "1" -StartTimeWindow 2015-03-05T14:00:00 -EndTimeWindow 2015-03-05T14:30:00 -TimeWindowTimeZone GMT -Rule $rule1, $rule2 -Name "adios"
	$profile2 = New-AzAutoscaleProfile -DefaultCapacity "1" -MaximumCapacity "10" -MinimumCapacity "1" -Rule $rule1, $rule2 -Name "saludos" -RecurrenceFrequency Week -ScheduleDay "1" -ScheduleHour 5 -ScheduleMinute 15 -ScheduleTimeZone UTC

    try
    {
        
		Add-AzAutoscaleSetting -Location "East US" -Name MySetting -ResourceGroup $resourceGroup -TargetResourceId $resourceId -AutoscaleProfile $profile1, $profile2
    }
    finally
    {
        
        
    }
}


function Test-GetAzureRmAutoscaleSetting
{
    
    $rgname = 'TestingMetricsScaleSet'

    try
    {
	    $actual = Get-AzAutoscaleSetting -ResourceGroup $rgname -detailedOutput

        
		Assert-AreEqual $actual.Count 1
    }
    finally
    {
        
        
    }
}


function Test-GetAzureRmAutoscaleSettingByName
{
    
    $rgname = 'TestingMetricsScaleSet'

    try
    {
		$actual = Get-AzAutoscaleSetting -ResourceGroup $rgname -Name "MySetting" -detailedOutput

		
		Assert-NotNull $actual "Result is null"
    }
    finally
    {
        
        
    }
}


function Test-RemoveAzureRmAutoscaleSetting
{
    
    $rgname = 'Default-Web-EastUS'

    try
    {
		Remove-AzAutoscaleSetting -ResourceGroup $rgname -name DefaultServerFarm-Default-Web-EastUS
    }
    finally
    {
        
        
    }
}


function Test-GetAzureRmAutoscaleHistory
{
    try
    {
		$actual = Get-AzAutoscaleHistory -StartTime 2015-02-10T02:35:00Z -endTime 2015-02-10T02:40:00Z -detailedOutput

        
		Assert-AreEqual $actual.Count 2
    }
    finally
    {
        
        
    }
}



function Test-NewAzureRmAutoscaleNotification
{
    try
    {
		Assert-Throws { New-AzAutoscaleNotification } "At least one Webhook or one CustomeEmail must be present, or the notification must be sent to the admin or co-admin"

		$actual = New-AzAutoscaleNotification -CustomEmail gu@ms.com, hu@net.net

        
		Assert-Null $actual.Webhooks "webhooks"
		Assert-NotNull $actual.Email "email"
		Assert-NotNull $actual.Email.CustomEmails "custom emails"
		Assert-AreEqual 2 $actual.Email.CustomEmails.Length "length"
		Assert-False { $actual.Email.SendToSubscriptionAdministrator } "SendToSubscriptionAdministrator"
		Assert-False { $actual.Email.SendToSubscriptionCoAdministrators } "SendToSubscriptionCoAdministrators"

		$actual = New-AzAutoscaleNotification -SendEmailToSubscriptionAdministrator

        
		Assert-Null $actual.Webhooks
		Assert-NotNull $actual.Email
		Assert-Null $actual.Email.CustomeEmails
		Assert-True { $actual.Email.SendToSubscriptionAdministrator } "SendToSubscriptionAdministrator"
		Assert-False { $actual.Email.SendToSubscriptionCoAdministrators } "SendToSubscriptionCoAdministrators"

		$actual = New-AzAutoscaleNotification -SendEmailToSubscriptionCoAdministrator

        
		Assert-Null $actual.Webhooks
		Assert-NotNull $actual.Email
		Assert-Null $actual.Email.CustomeEmails
		Assert-False { $actual.Email.SendToSubscriptionAdministrator } "SendToSubscriptionAdministrator"
		Assert-True { $actual.Email.SendToSubscriptionCoAdministrators } "SendToSubscriptionCoAdministrators"
    }
    finally
    {
        
        
    }
}


function Test-NewAzureRmAutoscaleWebhook
{
    try
    {
		$actual = New-AzAutoscaleWebhook -ServiceUri "http://myservice.com"

        
		Assert-AreEqual "http://myservice.com" $actual.ServiceUri
		Assert-AreEqual 0 $actual.Properties.Count
    }
    finally
    {
        
        
    }
}
