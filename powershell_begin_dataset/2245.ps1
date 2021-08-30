
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Set the URI for the ConfigMgr WebService.")]
    [ValidateNotNullOrEmpty()]
    [string]$URI,

    [parameter(Mandatory=$true, HelpMessage="Specify the known secret key for the ConfigMgr WebService.")]
    [ValidateNotNullOrEmpty()]
    [string]$SecretKey,

    [parameter(Mandatory=$false, HelpMessage="Define a filter used when calling ConfigMgr WebService to only return objects matching the filter.")]
    [ValidateNotNullOrEmpty()]
    [string]$Filter = [System.String]::Empty
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
		    [parameter(Mandatory=$true, HelpMessage="Value added to the log file.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$Value,

		    [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
		    [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
		    [string]$Severity,

		    [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$FileName = "DriverPackageDownload.log"
	    )
	    
        $LogFilePath = Join-Path -Path $Script:TSEnvironment.Value("_SMSTSLogPath") -ChildPath $FileName

        
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))

        
        $Date = (Get-Date -Format "MM-dd-yyyy")

        
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

        
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""DriverPackageDownloader"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	    
        try {
	        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to DriverPackageDownload.log file. Error message: $($_.Exception.Message)"
        }
    }

    
    Write-CMLogEntry -Value "Driver download package process initiated" -Severity 1

    
    $ComputerManufacturer = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer).Trim()
    Write-CMLogEntry -Value "Manufacturer determined as: $($ComputerManufacturer)" -Severity 1

    
    switch -Wildcard ($ComputerManufacturer) {
        "*Microsoft*" {
            $ComputerManufacturer = "Microsoft"
            $ComputerModel = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
        }
        "*HP*" {
            $ComputerManufacturer = "Hewlett-Packard"
            $ComputerModel = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
        }
        "*Hewlett-Packard*" {
            $ComputerManufacturer = "Hewlett-Packard"
            $ComputerModel = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
        }
        "*Dell*" {
            $ComputerManufacturer = "Dell"
            $ComputerModel = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
        }
        "*Lenovo*" {
            $ComputerManufacturer = "Lenovo"
            $ComputerModel = Get-WmiObject -Class Win32_ComputerSystemProduct | Select-Object -ExpandProperty Version
        }
        "*Acer*" { 
            $ComputerManufacturer = "Acer"
            $ComputerModel = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
        }
    }
    Write-CMLogEntry -Value "Computer model determined as: $($ComputerModel)" -Severity 1

    
    try {
        $WebService = New-WebServiceProxy -Uri $URI -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-CMLogEntry -Value "Unable to establish a connection to ConfigMgr WebService. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
    }

    
    try {
        $Packages = $WebService.GetCMPackage($SecretKey, $Filter)
        Write-CMLogEntry -Value "Retrieved a total of $(($Packages | Measure-Object).Count) driver packages from web service" -Severity 1
    }
    catch [System.Exception] {
        Write-CMLogEntry -Value "An error occured while calling ConfigMgr WebService for a list of available packages. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
    }

    
    $PackageList = New-Object -TypeName System.Collections.ArrayList

    
    $ErrorActionPreference = "Stop"

    
    try {
        $TSPackageID = $TSEnvironment.Value("_SMSTSPackageID")
        $OSImageVersion = $WebService.GetCMOSImageVersionForTaskSequence($SecretKey, $TSPackageID)
        Write-CMLogEntry -Value "Retrieved OS Image version from web service: $($OSImageVersion)" -Severity 1
    }
    catch [System.Exception] {
        Write-CMLogEntry -Value "An error occured while calling ConfigMgr WebService to determine OS Image version. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
    }

    
    switch -Wildcard ($OSImageVersion) {
        "10.0*" {
            $OSName = "Windows 10"
        }
        "6.3*" {
            $OSName = "Windows 8.1"
        }
        "6.1*" {
            $OSName = "Windows 7"
        }
    }
    Write-CMLogEntry -Value "Determined OS name from version: $($OSName)" -Severity 1

    
    if ($OSName -ne $null) {
        
        $ComputerSystemType = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty "Model"
        if ($ComputerSystemType -notin @("Virtual Machine", "VMware Virtual Platform", "VirtualBox", "HVM domU", "KVM")) {
            
            if ($Packages -ne $null) {
                
                foreach ($Package in $Packages) {
                    
                    if (($Package.PackageName -match "\b$($ComputerModel)\b") -and ($ComputerManufacturer -match $Package.PackageManufacturer) -and ($Package.PackageName -match $OSName)) {
                        
                        if ($OSName -like "Windows 10") {
                            switch ($ComputerManufacturer) {
                                "Hewlett-Packard" {
                                    if ($Package.PackageName -match $OSImageVersion) {
                                        $MatchFound = $true
                                    }
                                }
                                "Microsoft" {
                                    if ($Package.PackageName -match $OSImageVersion) {
                                        $MatchFound = $true
                                    }
                                }
                                Default {
                                    if ($Package.PackageName -match $OSName) {
                                        $MatchFound = $true
                                    }
                                }
                            }
                        }
                        else {
                            if ($Package.PackageName -match $OSName) {
                                $MatchFound = $true
                            }                            
                        }
                        
                        
                        if ($MatchFound -eq $true) {
                            Write-CMLogEntry -Value "Match found for computer model, manufacturer and operating system: $($Package.PackageName) ($($Package.PackageID))" -Severity 1
                            $PackageList.Add($Package) | Out-Null
                        }
                        else {
                            Write-CMLogEntry -Value "Package does not meet computer model, manufacturer and operating system criteria: $($Package.PackageName) ($($Package.PackageID))" -Severity 2
                        }
                    }
                    else {
                        Write-CMLogEntry -Value "Package does not meet computer model and manufacturer criteria: $($Package.PackageName) ($($Package.PackageID))" -Severity 2
                    }
                }

                
                if ($PackageList -ne $null) {
                    
                    if ($PackageList.Count -eq 1) {
                        Write-CMLogEntry -Value "Driver package list contains a single match, attempting to set task sequence variable" -Severity 1

                        
                        try {
                            $TSEnvironment.Value("OSDDownloadDownloadPackages") = $($PackageList[0].PackageID)
                            Write-CMLogEntry -Value "Successfully set OSDDownloadDownloadPackages variable with PackageID: $($PackageList[0].PackageID)" -Severity 1
                        }
                        catch [System.Exception] {
                            Write-CMLogEntry -Value "An error occured while setting OSDDownloadDownloadPackages variable. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
                        }
                    }
                    elseif ($PackageList.Count -ge 2) {
                        Write-CMLogEntry -Value "Driver package list contains multiple matches, attempting to set task sequence variable" -Severity 1

                        
                        try {
                            $Package = $PackageList | Sort-Object -Property PackageCreated -Descending | Select-Object -First 1
                            
                            $TSEnvironment.Value("OSDDownloadDownloadPackages") = $($Package[0].PackageID)
                            Write-CMLogEntry -Value "Successfully set OSDDownloadDownloadPackages variable with PackageID: $($Package[0].PackageID)" -Severity 1
                        }
                        catch [System.Exception] {
                            Write-CMLogEntry -Value "An error occured while setting OSDDownloadDownloadPackages variable. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
                        }
                    }
                    else {
                        Write-CMLogEntry -Value "Unable to determine a matching driver package from list since an unsupported count was returned from package list, bailing out" -Severity 2 ; exit 1
                    }
                }
                else {
                    Write-CMLogEntry -Value "Empty driver package list detected, bailing out" -Severity 2 ; exit 1
                }
            }
            else {
                Write-CMLogEntry -Value "Driver package list returned from web service did not contain any objects matching the computer model and manufacturer, bailing out" -Severity 2 ; exit 1
            }
        }
        else {
            Write-CMLogEntry -Value "Unsupported computer platform detected, bailing out" -Severity 2 ; exit 1
        }
    }
    else {
        Write-CMLogEntry -Value "Unable to detect current operating system name from task sequence reference, bailing out" -Severity 2 ; exit 1
    }
}