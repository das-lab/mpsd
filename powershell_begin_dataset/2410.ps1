
[CmdletBinding()]
[OutputType([bool])]
param (
	[Parameter(Mandatory,
			   ValueFromPipeline,
			ValueFromPipelineByPropertyName)]
	[ValidatePattern('.*\.ps1$')]
	[string]$ScriptFilePath,
	[string]$ScriptParameters,
	[Parameter(Mandatory)]
	[string]$LocalScriptFolderPath,
	[Parameter(Mandatory)]
	[hashtable]$TaskTriggerOptions,
	[Parameter(Mandatory)]
	[string]$TaskName,
	[Parameter(Mandatory)]
	[string]$TaskRunAsUser,
	[Parameter(Mandatory)]
	[string]$TaskRunAsPassword,
	[ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1})]
	[string]$Computername = 'localhost',
	[ValidateSet('x86', 'x64')]
	[string]$PowershellRunAsArch
)

begin {
	$ErrorActionPreference = 'Stop'
	Set-StrictMode -Version Latest
	
	function Test-PsRemoting {
		param (
			[Parameter(Mandatory)]
			$computername
		)
		
		try {
			$errorActionPreference = "Stop"
			$result = Invoke-Command -ComputerName $computername { 1 }
		} catch {
			return $false
		}
		
		
		
		if ($result -ne 1) {
			Write-Verbose "Remoting to $computerName returned an unexpected result."
			return $false
		}
		$true
	}
	
	function Get-ComputerArchitecture {
		if ((Get-CimInstance -ComputerName $Computername Win32_ComputerSystem -Property SystemType).SystemType -eq 'x64-based PC') {
			'x64'
		} else {
			'x86'	
		}
	}
	
	function Get-PowershellFilePath {
		
		if (($PowershellRunAsArch -eq 'x86') -and ((Get-ComputerArchitecture) -eq 'x64')) {
			if ($Computername -eq 'localhost') {
				
				"$($PsHome.Replace('System32','SysWow64'))\powershell.exe"
			} else {
				Invoke-Command -ComputerName $Computername -ScriptBlock { "$($PsHome.Replace('System32','SysWow64'))\powershell.exe" }
			}
		} else {
			
			if ($Computername -eq 'localhost') {
				
				"$PsHome\powershell.exe"
			} else {
				Invoke-Command -ComputerName $Computername -ScriptBlock { "$PsHome\powershell.exe" }
			}
		}
	}
	
	function New-MyScheduledTask {
		try {
			$PowershellFilePath = Get-PowershellFilePath
			if ($Computername -ne 'localhost') {
				$ScriptBlock = {
					$Action = New-ScheduledTaskAction -Execute $using:PowershellFilePath -Argument "-NonInteractive -NoLogo -NoProfile -File $using:ScriptFilePath $using:ScriptParameters"
					$TaskTriggerOptions = $using:TaskTriggerOptions
					$Trigger = New-ScheduledTaskTrigger @TaskTriggerOptions
					$RunAsUser = $using:TaskRunAsUser
					$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings (New-ScheduledTaskSettingsSet);
					Register-ScheduledTask -TaskName $using:TaskName -InputObject $Task -User $using:TaskRunAsUser -Password $using:TaskRunAsPassword
				}
				$Params = @{
					'Scriptblock' = $ScriptBlock
					'Computername' = $Computername
				}
				Invoke-Command @Params
			} else {
				$Action = New-ScheduledTaskAction -Execute $PowershellFilePath -Argument "-NonInteractive -NoLogo -NoProfile -File $ScriptFilePath"
				$Trigger = New-ScheduledTaskTrigger @TaskTriggerOptions
				$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings (New-ScheduledTaskSettingsSet);
				Register-ScheduledTask -TaskName $TaskName -InputObject $Task -User $TaskRunAsUser -Password $TaskRunAsPassword
			}
		} catch {
			Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
			$false
		}
	}
	
	function Get-UncPath ($HostName,$LocalPath) {
		$NewPath = $LocalPath -replace (":", "$")
		if ($NewPath.EndsWith("\")) {
			$NewPath = [Regex]::Replace($NewPath, "\\$", "")
		}
		"\\$HostName\$NewPath"
	}
	
	try {
		if (($Computername -ne 'localhost') -and !(Test-PsRemoting -computername $Computername)) {
			throw "PS remoting not available on the computer $Computername"
		}
		
		$LocalScriptFolderPath = $LocalScriptFolderPath.TrimEnd('\')
	} catch {
		Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
		exit
	}
}

process {
	try {
		
		
		if ($ScriptFilePath.StartsWith('\\') -or ($Computername -ne 'localhost')) {
			Copy-Item -Path $ScriptFilePath -Destination (Get-UncPath -HostName $Computername -LocalPath $LocalScriptFolderPath)
			$ScriptFilePath = "$LocalScriptFolderPath\$($ScriptFilePath | Split-Path -Leaf)"
		}
		New-MyScheduledTask | Out-Null
		$true
	} catch {
		Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
		$false
	}
}