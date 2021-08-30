
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the path containing the Flash64W.exe and BIOS executable.")]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [parameter(Mandatory=$false, HelpMessage="Specify the BIOS password if necessary.")]
    [ValidateNotNullOrEmpty()]
    [string]$Password,

    [parameter(Mandatory=$false, HelpMessage="Set the name of the log file produced by the flash utility.")]
    [ValidateNotNullOrEmpty()]
    [string]$LogFileName = "DellFlashBIOSUpdate.log"
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
	    param(
		    [parameter(Mandatory=$true, HelpMessage="Value added to the log file.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$Value,

		    [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
		    [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
		    [string]$Severity,

		    [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$FileName = "Invoke-DellBIOSUpdate.log"
	    )
	    
        $LogFilePath = Join-Path -Path $TSEnvironment.Value("_SMSTSLogPath") -ChildPath $FileName

        
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))

        
        $Date = (Get-Date -Format "MM-dd-yyyy")

        
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

        
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""DellBIOSUpdate.log"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	    
        try {
	        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to Invoke-DellBIOSUpdate.log file. Error message: $($_.Exception.Message)"
        }
    }

	
    Write-CMLogEntry -Value "Initiating script to determine flashing capabilities for Dell BIOS updates" -Severity 1

	
	$FlashUtility = Get-ChildItem -Path $Path -Filter "*.exe" -Recurse | Where-Object { $_.Name -like "Flash64W.exe" } | Select-Object -ExpandProperty FullName
	Write-CMLogEntry -Value "Attempting to use flash utility: $($FlashUtility)" -Severity 1

	if ($FlashUtility -ne $null) {
		
		$CurrentBIOSFile = Get-ChildItem -Path $Path -Filter "*.exe" -Recurse | Where-Object { $_.Name -notlike ($FlashUtility | Split-Path -leaf) } | Select-Object -ExpandProperty FullName
		Write-CMLogEntry -Value "Attempting to use BIOS update file: $($CurrentBIOSFile)" -Severity 1	

		if ($CurrentBIOSFile -ne $null) {
			
			$BIOSLogFile = Join-Path -Path $TSEnvironment.Value("_SMSTSLogPath") -ChildPath $LogFileName

			
			$FlashSwitches = "/b=$($CurrentBIOSFile) /s /f /l=$($BIOSLogFile)"

			
			if ($PSBoundParameters["Password"]) {
				if (-not([System.String]::IsNullOrEmpty($Password))) {
					$FlashSwitches = $FlashSwitches + " /p=$($Password)"
				}
			}	

			if (($TSEnvironment -ne $null) -and ($TSEnvironment.Value("_SMSTSinWinPE") -eq $true)) {
				Write-CMLogEntry -Value "Current environment is determined as WinPE" -Severity 1

				try {
					
					Write-CMLogEntry -Value "Using the following switches for Flash64W.exe: $($FlashSwitches -replace $Password, "<password removed>")" -Severity 1
					$FlashProcess = Start-Process -FilePath $FlashUtility -ArgumentList $FlashSwitches -Passthru -Wait -ErrorAction Stop
					
					
					if ($FlashProcess.ExitCode -eq 2) {
						
						$TSEnvironment.Value("SMSTSBiosUpdateRebootRequired") = "True"
						$TSEnvironment.Value("SMSTSBiosInOSUpdateRequired") = "False"
					}
					else {
						$TSEnvironment.Value("SMSTSBiosUpdateRebootRequired") = "False"
						$TSEnvironment.Value("SMSTSBiosInOSUpdateRequired") = "True"
					}
				}
				catch [System.Exception] {
					Write-CMLogEntry -Value "An error occured while updating the system BIOS during OS offline phase. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
				}
			}
			else {
				
				

				Write-CMLogEntry -Value "Current environment is determined as FullOS" -Severity 1
				
				
				$OSVolumeEncypted = if ((Manage-Bde -Status C:) -match "Protection On") { Write-Output $true } else { Write-Output $false }
				
				
				if ($OSVolumeEncypted -eq $true) {
					Write-CMLogEntry -Value "Suspending BitLocker protected volume: C:" -Severity 1
					Manage-Bde -Protectors -Disable C:
				}
				
				
				try
				{										
					if (([Environment]::Is64BitOperatingSystem) -eq $true) {
						Write-CMLogEntry -Value "Starting 64-bit flash BIOS update process" -Severity 1
						Write-CMLogEntry -Value "Using the following switches for BIOS file: $($FlashSwitches -replace $Password, "<Password Removed>")" -Severity 1

						
						$FlashUpdate = Start-Process -FilePath $FlashUtility -ArgumentList $FlashSwitches -Passthru -Wait -ErrorAction Stop
					}
					else {
						
						$FileSwitches = " /l=$($BIOSLogFile) /s"

						
						if ($PSBoundParameters["Password"]) {
							if (-not([System.String]::IsNullOrEmpty($Password))) {
								$FileSwitches = $FileSwitches + " /p=$($Password)"
							}
						}

						Write-CMLogEntry -Value "Starting 32-bit flash BIOS update process" -Severity 1
						Write-CMLogEntry -Value "Using the following switches for BIOS file: $($FileSwitches -replace $Password, "<Password Removed>")" -Severity 1						

						
						$FileUpdate = Start-Process -FilePath $CurrentBIOSFile -ArgumentList $FileSwitches -PassThru -Wait -ErrorAction Stop
					}
					
				}
				catch [System.Exception]
				{
					Write-CMLogEntry -Value "An error occured while updating the system BIOS in OS online phase. Error message: $($_.Exception.Message)" -Severity 3; exit 1
				}
			}
		}
		else {
			Write-CMLogEntry -Value "Unable to locate the current BIOS update file" -Severity 2 ; exit 1
		}
	}
	else {
		Write-CMLogEntry -Value "Unable to locate the Flash64W.exe utility" -Severity 2 ; exit 1
	}
}