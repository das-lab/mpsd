
[CmdletBinding(SupportsShouldProcess = $true)]
param (
	[parameter(Mandatory = $true, HelpMessage = "Specify the path containing the WinUPTP or Flash.cmd.")]
	[ValidateNotNullOrEmpty()]
	[string]$Path,
	[parameter(Mandatory = $false, HelpMessage = "Specify the BIOS password if necessary.")]
	[ValidateNotNullOrEmpty()]
	[string]$Password,
	[parameter(Mandatory = $false, HelpMessage = "Set the name of the log file produced by the flash utility.")]
	[ValidateNotNullOrEmpty()]
	[string]$LogFileName = "LenovoFlashBIOSUpdate.log"
)
Begin {
	
	try {
		$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
	}
	catch [System.Exception] {
		Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object"
	}
}
Process {
	
	function Write-CMLogEntry {
		param (
			[parameter(Mandatory = $true, HelpMessage = "Value added to the log file.")]
			[ValidateNotNullOrEmpty()]
			[string]$Value,
			[parameter(Mandatory = $true, HelpMessage = "Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
			[ValidateNotNullOrEmpty()]
			[ValidateSet("1", "2", "3")]
			[string]$Severity,
			[parameter(Mandatory = $false, HelpMessage = "Name of the log file that the entry will written to.")]
			[ValidateNotNullOrEmpty()]
			[string]$FileName = "Invoke-LenovoBIOSUpdate.log"
		)
		
		$LogFilePath = Join-Path -Path $Script:TSEnvironment.Value("_SMSTSLogPath") -ChildPath $FileName
		
		
		$Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
		
		
		$Date = (Get-Date -Format "MM-dd-yyyy")
		
		
		$Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
		
		
		$LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""LenovoBIOSUpdate.log"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
		
		
		try {
			Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
		}
		catch [System.Exception] {
			Write-Warning -Message "Unable to append log entry to Invoke-LenovoBIOSUpdate.log file. Error message: $($_.Exception.Message)"
		}
	}
	
	
    Set-Location -Path $Path

	
	Write-CMLogEntry -Value "Initiating script to determine flashing capabilities for Lenovo BIOS updates" -Severity 1
	
	
	if (([Environment]::Is64BitOperatingSystem) -eq $true) {
		$WinUPTPUtility = Get-ChildItem -Path $Path -Filter "*.exe" -Recurse | Where-Object { $_.Name -like "WinUPTP64.exe" } | Select-Object -ExpandProperty FullName
	}
	else {
		$WinUPTPUtility = Get-ChildItem -Path $Path -Filter "*.exe" -Recurse | Where-Object { $_.Name -like "WinUPTP.exe" } | Select-Object -ExpandProperty FullName
	}
	
	
	$FlashCMDUtility = Get-ChildItem -Path $Path -Filter "*.cmd" -Recurse | Where-Object { $_.Name -like "Flash.cmd" } | Select-Object -ExpandProperty FullName
	
	if ($WinUPTPUtility -ne $null) {
		
		Write-CMLogEntry -Value "Using WinUTPT BIOS update method" -Severity 1
		$FlashSwitches = " /S"
		$FlashUtility = $WinUPTPUtility
	}
	
	if ($FlashCMDUtility -ne $null) {
		
		Write-CMLogEntry -Value "Using FlashCMDUtility BIOS update method" -Severity 1
		$FlashSwitches = " /quiet /sccm /ign"
		$FlashUtility = $FlashCMDUtility
	}
	
	if (!$FlashUtility) {
		Write-CMLogEntry -Value "Supported upgrade utility was not found." -Severity 3
	}
	
	if ($Password -ne $null) {
		
		$FlashSwitches = $FlashSwitches + " /pass:$($Password)"
		Write-CMLogEntry -Value "Using the following switches for BIOS file: $($FlashSwitches -replace $Password, "<Password Removed>")" -Severity 1
	}
	
	
	$LogFilePath = Join-Path -Path $TSEnvironment.Value("_SMSTSLogPath") -ChildPath $LogFileName
	
	if (($TSEnvironment -ne $null) -and ($TSEnvironment.Value("_SMSTSinWinPE") -eq $true)) {
		try {
			
			$FlashProcess = Start-Process -FilePath $FlashUtility -ArgumentList $FlashSwitches -Passthru -Wait
			
			
			$FlashProcess.ExitCode | Out-File -FilePath $LogFilePath

            
            $WinUPTPLog = Get-ChildItem -Filter "*.log" -Recurse | Where-Object { $_.Name -like "winuptp.log" } -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
            Write-CMLogEntry -Value "winuptp.log file path is $($WinUPTPLog)" -Severity 1
            $SMSTSLogPath = Join-Path -Path $TSEnvironment.Value("_SMSTSLogPath") -ChildPath "winuptp.log"			
            Copy-Item -Path $WinUPTPLog -Destination $SMSTSLogPath -Force -ErrorAction SilentlyContinue
		}
		catch [System.Exception] {
			Write-CMLogEntry -Value "An error occured while updating the system BIOS in OS online phase. Error message: $($_.Exception.Message)" -Severity 3; exit 1
		}
	}
	else {
		
		
		
		$OSVolumeEncypted = if ((Manage-Bde -Status C:) -match "Protection On") { Write-Output $true } else { Write-Output $false }
		
		
		if ($OSVolumeEncypted -eq $true) {
			Write-CMLogEntry -Value "Suspending BitLocker protected volume: C:" -Severity 1
			Manage-Bde -Protectors -Disable C:
		}
		
		
		try {
			Write-CMLogEntry -Value "Running Flash Update - $($FlashUtility)" -Severity 1
			$FlashProcess = Start-Process -FilePath $FlashUtility -ArgumentList $FlashSwitches -Passthru -Wait
			
			
			$FlashProcess.ExitCode | Out-File -FilePath $LogFilePath
		}
		catch [System.Exception] {
			Write-Warning -Message "An error occured while updating the system bios. Error message: $($_.Exception.Message)"; exit 1
		}
	}
}