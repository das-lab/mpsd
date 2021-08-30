
[CmdletBinding()]
param
(
	[string]
	$AppsFile = $null,
	[string]
	$AppName = $null,
	[ValidateNotNullOrEmpty()][boolean]
	$GetAppList = $false,
	[ValidateNotNullOrEmpty()][boolean]
	$Log = $false
)
Import-Module Appx

function Get-AppName {

	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
		$Name
	)
	
	$Temp = $Name.Split('.')
	For ($j = 0; $j -lt $Temp.Count; $j++) {
		$Numeric = [bool]($Temp[$j] -as [double])
		If ($Temp[$j] -eq 'Net') {
			$Temp[$j] = "." + $Temp[$j]
		}
		If ($Numeric -eq $true) {
			If ($Temp[$j + 1] -ne $null) {
				$Temp[$j] = $Temp[$j] + '.'
			}
			$FormattedName = $FormattedName + $Temp[$j]
		} else {
			$FormattedName = $FormattedName + $Temp[$j] + [char]32
		}
	}
	Return $FormattedName
}


function Get-BuiltInAppsList {

	
	[CmdletBinding()]
	param ()
	
	$Apps = Get-AppxPackage
	$Apps = $Apps.Name
	$Apps = $Apps | Sort-Object
	If ($Log -eq $true) {
		$RelativePath = Get-RelativePath
		$Apps | Out-File -FilePath $RelativePath"AllAppslist.txt" -Encoding UTF8
	}
	For ($i = 0; $i -lt $Apps.count; $i++) {
		$Temp = Get-AppName -Name $Apps[$i]
		$Apps[$i] = $Temp
	}
	$Apps
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $RelativePath
}

function Uninstall-BuiltInApp {

	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]
		$AppName
	)
	
	$App = Get-AppName -Name $AppName
	Write-Host "Uninstalling"$App"....." -NoNewline
	$Output = Get-AppxPackage $AppName
	If ($Output -eq $null) {
		Write-Host "Not Installed" -ForegroundColor Yellow
	} else {
		$Output = Get-AppxPackage $AppName | Remove-AppxPackage
		$Output = Get-AppxPackage $AppName
		If ($Output -eq $null) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	}
}

function Uninstall-BuiltInApps {

	
	[CmdletBinding()]
	param ()
	
	$RelativePath = Get-RelativePath
	$AppsFile = $RelativePath + $AppsFile
	$List = Get-Content -Path $AppsFile
	foreach ($App in $List) {
		Uninstall-BuiltInApp -AppName $App
	}
}

cls

If ($GetAppList -eq $true) {
	Get-BuiltInAppsList
}

If (($AppName -ne $null) -and ($AppName -ne "")) {
	Uninstall-BuiltInApp -AppName $AppName
}

If (($GetAppList -ne $null) -and ($GetAppList -ne "")) {
	Uninstall-BuiltInApps
}
