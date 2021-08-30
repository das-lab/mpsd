

[CmdletBinding()]
param
(
		[string]$AppsFile = 'Applications.txt',
		[ValidateNotNullOrEmpty()][string]$ConsoleTitle = 'Application Shortcuts',
		[switch]$OutputToTextFile,
		[switch]$GetApplicationList
)

function Add-AppToStartMenu {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[Parameter(Mandatory = $true)][string]$Application
	)
	
	$Success = $true
	$Status = Remove-AppFromStartMenu -Application $Application
	If ($Status -eq $false) {
		$Success = $false
	}
	Write-Host 'Pinning'$Application' to start menu.....' -NoNewline
	((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where-Object{ $_.Name -eq $Application }).verbs() | Where-Object{ $_.Name.replace('&', '') -match 'Pin to Start' } | ForEach-Object{ $_.DoIt() }
	If ($? -eq $true) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Add-AppToTaskbar {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[Parameter(Mandatory = $true)][string]$Application
	)
	
	$Success = $true
	$Status = Remove-AppFromTaskbar -Application $Application
	If ($Status -eq $false) {
		$Success = $false
	}
	Write-Host 'Pinning'$Application' to start menu.....' -NoNewline
	((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where-Object{ $_.Name -eq $Application }).verbs() | Where-Object{ $_.Name.replace('&', '') -match 'Pin to taskbar' } | ForEach-Object{ $_.DoIt() }
	If ($? -eq $true) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Get-ApplicationList {

	
	[CmdletBinding()]
	param
	(
			[switch]$SaveOutput
	)
	
	$RelativePath = Get-RelativePath
	$OutputFile = $RelativePath + "ApplicationList.csv"
	$Applications = (New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items()
	$Applications = $Applications | Sort-Object -Property name -Unique
	If ($SaveOutput.IsPresent) {
		If ((Test-Path -Path $OutputFile) -eq $true) {
			Remove-Item -Path $OutputFile -Force
		}
		"Applications" | Out-File -FilePath $OutputFile -Encoding UTF8 -Force
		$Applications.Name | Out-File -FilePath $OutputFile -Encoding UTF8 -Append -Force
	}
	$Applications.Name
}

function Get-Applications {

	
	[CmdletBinding()][OutputType([object])]
	param ()
	
	$RelativePath = Get-RelativePath
	$File = $RelativePath + $AppsFile
	$Contents = Get-Content -Path $File -Force
	Return $Contents
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Invoke-PinActions {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][object]$AppList
	)
	
	$Success = $true
	foreach ($App in $AppList) {
		$Entry = $App.Split(',')
		If ($Entry[1] -eq 'startmenu') {
			If ($Entry[2] -eq 'add') {
				$Status = Add-AppToStartMenu -Application $Entry[0]
				If ($Status -eq $false) {
					$Success = $false
				}
			} elseif ($Entry[2] -eq 'remove') {
				$Status = Remove-AppFromStartMenu -Application $Entry[0]
				If ($Status -eq $false) {
					$Success = $false
				}
			} else {
				Write-Host $Entry[0]" was entered incorrectly"
			}
		} elseif ($Entry[1] -eq 'taskbar') {
			If ($Entry[2] -eq 'add') {
				$Status = Add-AppToTaskbar -Application $Entry[0]
				If ($Status -eq $false) {
					$Success = $false
				}
			} elseif ($Entry[2] -eq 'remove') {
				$Status = Remove-AppFromTaskbar -Application $Entry[0]
				If ($Status -eq $false) {
					$Success = $false
				}
			} else {
				Write-Host $Entry[0]" was entered incorrectly"
			}
		}
	}
	Return $Success
}

function Remove-AppFromStartMenu {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[Parameter(Mandatory = $true)][string]$Application
	)
	
	$Success = $true
	Write-Host 'Unpinning'$Application' from start menu.....' -NoNewline
	((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where-Object{ $_.Name -eq $Application }).verbs() | Where-Object{ $_.Name.replace('&', '') -match 'Unpin from Start' } | ForEach-Object{ $_.DoIt() }
	If ($? -eq $true) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Remove-AppFromTaskbar {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[Parameter(Mandatory = $true)][string]$Application
	)
	
	$Success = $true
	Write-Host 'Unpinning'$Application' from task bar.....' -NoNewline
	((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where-Object{ $_.Name -eq $Application }).verbs() | Where-Object{ $_.Name.replace('&', '') -match 'Unpin from taskbar' } | ForEach-Object{ $_.DoIt() }
	If ($? -eq $true) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Set-ConsoleTitle {

	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][String]$Title
	)
	
	$host.ui.RawUI.WindowTitle = $Title
}

Clear-Host
$Success = $true
Set-ConsoleTitle -Title $ConsoleTitle
If ($GetApplicationList.IsPresent) {
	If ($OutputToTextFile.IsPresent) {
		Get-ApplicationList -SaveOutput
	} else {
		Get-ApplicationList
	}
}
If (($AppsFile -ne $null) -or ($AppsFile -ne "")) {
	$ApplicationList = Get-Applications
	$Success = Invoke-PinActions -AppList $ApplicationList
}




If ($Success -eq $false) {
	Exit 1
}
