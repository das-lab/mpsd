
[CmdletBinding()]
param
(
		[string]$PSConsoleTitle = 'PowerShell Configuration'
)

function Set-ConsoleTitle {

	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][String]$ConsoleTitle
	)
	
	$host.ui.RawUI.WindowTitle = $ConsoleTitle
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Set-RegistryKeyValue {

	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$RegKeyName,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$RegKeyValue,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$RegKeyData,
			[string]$DisplayName = $null
	)
	
	If ($DisplayName -ne $null) {
		Write-Host "Setting"$DisplayName"....." -NoNewline
	}
	$NoOutput = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
	$Key = Get-Item -LiteralPath $RegKeyName -ErrorAction SilentlyContinue
	If ($Key -ne $null) {
		If ($RegKeyValue -eq '(Default)') {
			$Value = Get-ItemProperty $RegKey '(Default)' | Select-Object -ExpandProperty '(Default)'
		} else {
			$Value = $Key.GetValue($RegKeyValue, $null)
		}
		If ($Value -ne $RegKeyData) {
			Set-ItemProperty -Path $RegKeyName -Name $RegKeyValue -Value $RegKeyData -Force
		}
		
	} else {
		$NoOutput = New-Item -Path $RegKeyName -Force
		$NoOutput = New-ItemProperty -Path $RegKeyName -Name $RegKeyValue -Value $RegKeyData -Force
	}
	If ($RegKeyValue -eq '(Default)') {
		$Value = Get-ItemProperty $RegKey '(Default)' | Select-Object -ExpandProperty '(Default)'
	} else {
		$Value = $Key.GetValue($RegKeyValue, $null)
	}
	If ($DisplayName -ne $null) {
		If ($Value -eq $RegKeyData) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			Write-Host $Value
			Write-Host $RegKeyData
		}
	}
}

function Copy-Files {

	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$SourceDirectory,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$DestinationDirectory,
			[ValidateNotNullOrEmpty()][String]$FileFilter
	)
	
	$Dest = $DestinationDirectory
	If ((Test-Path $DestinationDirectory) -eq $false) {
		$NoOutput = New-Item -Path $DestinationDirectory -ItemType Directory -Force
	}
	$Files = Get-ChildItem $SourceDirectory -Filter $FileFilter
	If ($Files.Count -eq $null) {
		Write-Host "Copy"$Files.Name"....." -NoNewline
		Copy-Item $Files.FullName -Destination $Dest -Force
		$Test = $Dest + "\" + $Files.Name
		If (Test-Path $Test) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	} else {
		For ($i = 0; $i -lt $Files.Count; $i++) {
			$File = $Files[$i].FullName
			Write-Host "Copy"$Files[$i].Name"....." -NoNewline
			Copy-Item $File -Destination $Dest -Force
			$Test = $Dest + "\" + $Files[$i].Name
			If (Test-Path $Test) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed" -ForegroundColor Red
			}
		}
	}
}

Clear-Host

Set-ConsoleTitle -ConsoleTitle $PSConsoleTitle


$RelativePath = Get-RelativePath


$RegKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
$RegValue = $env:SystemRoot + '\system32\WindowsPowerShell\v1.0\Modules\;' + $env:ProgramFiles + '\windowspowershell\modules'
Set-RegistryKeyValue -DisplayName "PSModulePath" -RegKeyName $RegKey -RegKeyValue 'PSModulePath' -RegKeyData $RegValue


$RegKey = 'HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
Set-RegistryKeyValue -DisplayName "ExecutionPolicy" -RegKeyName $RegKey -RegKeyValue 'ExecutionPolicy' -RegKeyData 'RemoteSigned'


$RegKey = 'HKCR:\Microsoft.PowerShellScript.1\Shell\runas\command'
Set-RegistryKeyValue -DisplayName "RunAs Administrator" -RegKeyName $RegKey -RegKeyValue '(Default)' -RegKeyData '"c:\windows\system32\windowspowershell\v1.0\powershell.exe" -noexit "%1"'


$ModuleFolder = $env:ProgramFiles + "\WindowsPowerShell\Modules\Deployment"
Copy-Files -SourceDirectory $RelativePath -DestinationDirectory $ModuleFolder -FileFilter "Deployment.psm1"
