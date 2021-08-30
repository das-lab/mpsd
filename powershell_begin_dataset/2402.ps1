. "$PSScriptRoot\Publish-PowerShellGalleryModule.ps1"

$commandName = 'Publish-PowerShellGalleryModule'

describe 'Publish-PowerShellGalleryModule' {
	
		mock 'Test-Path' {
			$true
		}

		mock 'ShowMenu'

		mock 'PromptChoice'

		mock 'GetRequiredManifestKeyParams' {
			@{
				Version = 'ver'
				Description = 'desc'
				Author = 'authorhere'
				ProjectUri = 'urihere'
			}
		}

		mock 'New-ModuleManifest'

		mock 'Test-ModuleManifest' {
			$true
		}

		mock 'Add-Content'

		mock 'Update-ModuleManifest'

		mock 'Publish-Module'

		mock 'Invoke-Test'

		function Get-Module {
			@{
				Path = 'manifestpath'
				Description = 'deschere'
				Author = 'authhere'
				Version = 'verhere'
				LicenseUri = 'licurihere'
				ModuleBase = 'modulebase'
				Name = 'modulename'
			}
		}
	

	$parameterSets = @(
		@{
			ModuleFilePath = 'C:\module.psm1'
			TestName = 'Mandatory params'
		}
		@{
			ModuleFilePath = 'C:\module.psm1'
			RunOptionalTests = $true
			NuGetApiKey = 'xxxx'
			PublishToGallery = $true
			TestName = 'All tests / Publish to Gallery'
		}
		@{
			ModuleFilePath = 'C:\module.psm1'
			RunOptionalTests = $true
			NuGetApiKey = 'xxxx'
			TestName = 'All tests'
		}
		@{
			ModuleFilePath = 'C:\module.psm1'
			NuGetApiKey = 'xxxx'
			PublishToGallery = $true
			TestName = 'Publish to Gallery'
		}
	)

	$testCases = @{
		All = $parameterSets
		AllTests = $parameterSets.where({$_.ContainsKey('RunOptionalTests')})
		PublishToGallery = $parameterSets.where({$_.ContainsKey('PublishToGallery')})
		NoApi = $parameterSets.where({-not $_.ContainsKey('NuGetApiKey')})
		NugetApi = $parameterSets.where({$_.ContainsKey('NuGetApiKey')})
	}

	it 'should run all mandatory tests: <TestName>' -TestCases $testCases.NugetApi {
		param($ModuleFilePath,$RunOptionalTests,$NuGetApiKey,$PublishGallery)

		$result = & $commandName @PSBoundParameters

		$testNames = 'Module manifest exists','Manifest has all required keys','Manifest passes Test-Modulemanifest validation'
		foreach ($name in $testNames) {
			$assMParams = @{
				CommandName = 'Invoke-Test'
				Times = 1
				Exactly = $true
				Scope = 'It'
				ParameterFilter = { $PSBoundParameters.TestName -eq $name }
			}
			Assert-MockCalled @assMParams
		}

	}

	

	
	
		
	
	

	

	

	
	
		
	
	


	

	

	
	
		
	
	
	
	

	

	
	
	
	

	

	
	
	
	

	

	
	
	

	
	
	
	

	

	
	
	
	

	

	

	
	
}

