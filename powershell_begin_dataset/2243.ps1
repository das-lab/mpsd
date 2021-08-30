 
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Save","Revert")]
    [string]$Mode
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
		    [string]$FileName = "SaveTPMOwnerPassword.log"
	    )
	    
        $LogFilePath = Join-Path -Path $Script:TSEnvironment.Value("_SMSTSLogPath") -ChildPath $FileName

        
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))

        
        $Date = (Get-Date -Format "MM-dd-yyyy")

        
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

        
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""SaveTPMOwnerPassword"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	    
        try {
	        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to SaveTPMOwnerPassword.log file"
        }
    }

    function Test-RegistryValue {
	    param(
		    [parameter(Mandatory=$true, HelpMessage="Path to key where value to test exists")]
		    [ValidateNotNullOrEmpty()]
		    [string]$Path,

		    [parameter(Mandatory=$true, HelpMessage="Name of the value")]
		    [ValidateNotNullOrEmpty()]
		    [string]$Name
        )
        
        try {
            $Existence = Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Name -ErrorAction Stop
            if ($Existence -ne $null) {
                return $true
            }
        }
        catch [System.Exception] {
            return $false
        }
    }

    
    Write-CMLogEntry -Value "Invoking TPM Owner Password control" -Severity 1

    
    switch ($Mode) {
        "Save" {
            
            $OAFTSVariable = $TSEnvironment.Value("_OSDOAF")
            if ($OAFTSVariable -ne $null) {
                
                try {
                    New-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Services\TPM\WMI\Admin" -Name OwnerAuthFull -Value "$($OAFTSVariable)" -Force -ErrorAction Stop
                    Write-CMLogEntry -Value "Successfully set OwnerAuthFull value with TPM Owner Password" -Severity 1
                }
                catch [System.Exception] {
                    Write-CMLogEntry -Value "An error occured when attempting to create the OwnerAuthFull value in the registry. Error message: $($_.Exception.Message)" -Severity 3
                }

                
                try {
                    $TPMKeyPath = "HKLM:\Software\Policies\Microsoft\TPM"
                    if (Test-Path -Path $TPMKeyPath) {
                        New-Item -Path $TPMKeyPath -Force -ErrorAction Stop
                    }
                    Write-CMLogEntry -Value "Successfully validated TPM key location" -Severity 1
                }
                catch [System.Exception] {
                    Write-CMLogEntry -Value "An error occured when attempting to create the TPM key in the registry. Error message: $($_.Exception.Message)" -Severity 3
                }
        
                
                try {
                    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\TPM" -Name OSManagedAuthLevel -Value 4 -Force -ErrorAction Stop
                    Write-CMLogEntry -Value "Successfully set OSManagedAuthLevel value with data value of 4 (old TPM Owner Password behavior)" -Severity 1
                }
                catch [System.Exception] {
                    Write-CMLogEntry -Value "An error occured when attempting to create the OSManagedAuthLevel value in the registry. Error message: $($_.Exception.Message)" -Severity 3
                }
            }
        }
        "Revert" {
            
            try {
                New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\TPM" -Name OSManagedAuthLevel -Value 2 -Force -ErrorAction Stop
                Write-CMLogEntry -Value "Successfully reverted OSManagedAuthLevel value with data value of 2 (new TPM Owner Password behavior)" -Severity 1
            }
            catch [System.Exception] {
                Write-CMLogEntry -Value "An error occured when attempting to revert the OSManagedAuthLevel value in the registry. Error message: $($_.Exception.Message)" -Severity 3
            }

            
            try {
                $TPMOwnerAuthPath = "HKLM:\SYSTEM\ControlSet001\Services\TPM\WMI\Admin"
                if (Test-RegistryValue -Path $TPMOwnerAuthPath -Name OwnerAuthFull) {
                    Remove-ItemProperty -Path $TPMOwnerAuthPath -Name OwnerAuthFull -Force -ErrorAction Stop
                    Write-CMLogEntry -Value "Successfully removed OwnerAuthFull value from registry" -Severity 1
                }
            }
            catch [System.Exception] {
                Write-CMLogEntry -Value "An error occured when attempting to remove the OwnerAuthFull value in the registry. Error message: $($_.Exception.Message)" -Severity 3
            }
        }
    }
}
