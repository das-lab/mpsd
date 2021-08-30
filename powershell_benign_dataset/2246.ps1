
Begin {
    
    try {
        $TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object" ; exit 1
    }
}
Process {
    
    function Write-CMLogEntry {
	    param(
		    [parameter(Mandatory=$true, HelpMessage="Value added to the smsts.log file.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$Value,

		    [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
		    [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
		    [string]$Severity,

		    [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$FileName = "EnableCredentialGuard.log"
	    )
	    
        $LogFilePath = Join-Path -Path $Script:TSEnvironment.Value("_SMSTSLogPath") -ChildPath $FileName

        
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))

        
        $Date = (Get-Date -Format "MM-dd-yyyy")

        
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

        
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""CredentialGuard"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	    
        try {
	        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to EnableCredentialGuard.log file"
        }
    }

    
    Write-CMLogEntry -Value "Starting configuration for Credential Guard" -Severity 1

    if ([int](Get-WmiObject -Class Win32_OperatingSystem).BuildNumber -lt 14393) {
        try {
            
            Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-HyperVisor -Online -All -LimitAccess -NoRestart -ErrorAction Stop
            Write-CMLogEntry -Value "Successfully enabled Microsoft-Hyper-V-HyperVisor feature" -Severity 1

            
            Enable-WindowsOptionalFeature -FeatureName IsolatedUserMode -Online -All -LimitAccess -NoRestart -ErrorAction Stop
            Write-CMLogEntry -Value "Successfully enabled IsolatedUserMode feature" -Severity 1
        }
        catch [System.Exception] {
            Write-CMLogEntry -Value "An error occured when enabling required windows features" -Severity 3
        }
    }
    
    
    $RegistryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
    if (-not(Test-Path -Path $RegistryKeyPath)) {
        Write-CMLogEntry -Value "Creating HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard registry key" -Severity 1
        New-Item -Path $RegistryKeyPath -ItemType Directory -Force
    }

    
    Write-CMLogEntry -Value "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\RequirePlatformSecurityFeatures value as DWORD with data 1" -Severity 1
    New-ItemProperty -Path $RegistryKeyPath -Name RequirePlatformSecurityFeatures -PropertyType DWORD -Value 1

    
    Write-CMLogEntry -Value "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\EnableVirtualizationBasedSecurity value as DWORD with data 1" -Severity 1
    New-ItemProperty -Path $RegistryKeyPath -Name EnableVirtualizationBasedSecurity -PropertyType DWORD -Value 1

    
    Write-CMLogEntry -Value "Adding HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\LsaCfgFlags value as DWORD with data 1" -Severity 1
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name LsaCfgFlags -PropertyType DWORD -Value 1

    
    Write-CMLogEntry -Value "Successfully enabled Credential Guard" -Severity 1
}