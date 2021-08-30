
[CmdletBinding()]
param
(
		[boolean]$ListFeatures = $false,
		[string]$Feature,
		[ValidateSet('enable', 'disable')][string]$Setting,
		[String]$FeaturesFile
)

function Confirm-Feature {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[ValidateNotNull()][string]$FeatureName,
			[ValidateSet('Enable', 'Disable')][string]$FeatureState
	)
	
	$WindowsFeatures = Get-WindowsFeaturesList
	$WindowsFeature = $WindowsFeatures | Where-Object { $_.Name -eq $FeatureName }
	switch ($FeatureState) {
		'Enable' {
			If (($WindowsFeature.State -eq 'Enabled') -or ($WindowsFeature.State -eq 'Enable Pending')) {
				Return $true
			} else {
				Return $false
			}
		}
		'Disable' {
			If (($WindowsFeature.State -eq 'Disabled') -or ($WindowsFeature.State -eq 'Disable Pending')) {
				Return $true
			} else {
				Return $false
			}
		}
		default {
			Return $false
		}
	}
	
}

function Get-WindowsFeaturesList {

	
	[CmdletBinding()]
	param ()
	
	$Temp = dism /online /get-features
	$Temp = $Temp | Where-Object { ($_ -like '*Feature Name*') -or ($_ -like '*State*') }
	$i = 0
	$Features = @()
	Do {
		$FeatureName = $Temp[$i]
		$FeatureName = $FeatureName.Split(':')
		$FeatureName = $FeatureName[1].Trim()
		$i++
		$FeatureState = $Temp[$i]
		$FeatureState = $FeatureState.Split(':')
		$FeatureState = $FeatureState[1].Trim()
		$Feature = New-Object PSObject
		$Feature | Add-Member noteproperty Name $FeatureName
		$Feature | Add-Member noteproperty State $FeatureState
		$Features += $Feature
		$i++
	} while ($i -lt $Temp.Count)
	$Features = $Features | Sort-Object Name
	Return $Features
}

function Set-WindowsFeature {

	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Name,
			[Parameter(Mandatory = $true)][ValidateSet('enable', 'disable')][string]$State
	)
	
	$EXE = $env:windir + "\system32\dism.exe"
	Write-Host $Name"....." -NoNewline
	If ($State -eq "enable") {
		$Parameters = "/online /enable-feature /norestart /featurename:" + $Name
	} else {
		$Parameters = "/online /disable-feature /norestart /featurename:" + $Name
	}
	$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Parameters -Wait -PassThru -WindowStyle Minimized).ExitCode
	If ($ErrCode -eq 0) {
		$FeatureChange = Confirm-Feature -FeatureName $Name -FeatureState $State
		If ($FeatureChange -eq $true) {
			If ($State -eq 'Enable') {
				Write-Host "Enabled" -ForegroundColor Yellow
			} else {
				Write-Host "Disabled" -ForegroundColor Yellow
			}
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	} elseif ($ErrCode -eq 3010) {
		$FeatureChange = Confirm-Feature -FeatureName $Name -FeatureState $State
		If ($FeatureChange -eq $true) {
			If ($State -eq 'Enable') {
				Write-Host "Enabled & Pending Reboot" -ForegroundColor Yellow
			} else {
				Write-Host "Disabled & Pending Reboot" -ForegroundColor Yellow
			}
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	} else {
		If ($ErrCode -eq 50) {
			Write-Host "Failed. Parent feature needs to be enabled first." -ForegroundColor Red
		} else {
			Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		}
	}
}

function Set-FeaturesFromFile {

	
	[CmdletBinding()]
	param ()
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + '\'
	$FeaturesFile = $RelativePath + $FeaturesFile
	If ((Test-Path $FeaturesFile) -eq $true) {
		$FeaturesFile = Get-Content $FeaturesFile
		foreach ($Item in $FeaturesFile) {
			$Item = $Item.split(',')
			Set-WindowsFeature -Name $Item[0] -State $Item[1]
		}
	}
}

Clear-Host
If ($ListFeatures -eq $true) {
	$WindowsFeatures = Get-WindowsFeaturesList
	$WindowsFeatures
}
If ($FeaturesFile -ne '') {
	Set-FeaturesFromFile
}
If ($Feature -ne '') {
	Set-WindowsFeature -Name $Feature -State $Setting
}


