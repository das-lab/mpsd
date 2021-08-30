
[CmdletBinding()]
param ()

function Import-SCCMModule {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$SCCMServer
	)
	
	
	$Architecture = (get-wmiobject win32_operatingsystem -computername $SCCMServer).OSArchitecture
	
	$Uninstall = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue }
	If ($Architecture -eq "64-bit") {
		$Uninstall += Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue }
	}
	
	$RegKey = ($Uninstall | Where-Object { $_ -like "*SMS Primary Site*" }) -replace 'HKEY_LOCAL_MACHINE', 'HKLM:'
	$Reg = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ItemProperty -Path $args[0] } -ArgumentList $RegKey
	
	$Directory = (($Reg.UninstallString).Split("\", 4) | Select-Object -Index 0, 1, 2) -join "\"
	
	$Module = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path $args[0] -Filter "ConfigurationManager.psd1" -Recurse } -ArgumentList $Directory
	
	If ($Module.Length -gt 1) {
		foreach ($Item in $Module) {
			If (($NewModule -eq $null) -or ($Item.CreationTime -gt $NewModule.CreationTime)) {
				$NewModule = $Item
			}
		}
		$Module = $NewModule
	}
	
	[string]$Module = "\\" + $SCCMServer + "\" + ($Module.Fullname -replace ":", "$")
	
	Import-Module -Name $Module
}

Import-SCCMModule -SCCMServer "SCCMServer"
