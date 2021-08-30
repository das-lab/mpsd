
function Write-LogEntry {
    param(
        [parameter(Mandatory=$true, HelpMessage="Value added to the RemovedApps.log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "RemovedApps.log"
    )
    
    $LogFilePath = Join-Path -Path $env:windir -ChildPath "Temp\$($FileName)"

    
    try {
        Add-Content -Value $Value -LiteralPath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to RemovedApps.log file"
    }
}


Write-LogEntry -Value "Starting appx package removal"
$AppArrayList = Get-AppxPackage -PackageTypeFilter Bundle -AllUsers | Select-Object -Property Name, PackageFullName | Sort-Object -Property Name


$WhiteListedApps = @(
    "Microsoft.DesktopAppInstaller", 
    "Microsoft.Messaging", 
    "Microsoft.StorePurchaseApp"
    "Microsoft.WindowsCalculator", 
    "Microsoft.WindowsCommunicationsApps", 
    "Microsoft.WindowsSoundRecorder", 
    "Microsoft.WindowsStore"
)


foreach ($App in $AppArrayList) {
    
    if (($App.Name -in $WhiteListedApps)) {
        Write-LogEntry -Value "Skipping excluded application package: $($App.Name)"
    }
    else {
        
        $AppPackageFullName = Get-AppxPackage -Name $App.Name | Select-Object -ExpandProperty PackageFullName
        $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App.Name } | Select-Object -ExpandProperty PackageName

        
        try {
            Write-LogEntry -Value "Removing application package: $($AppPackageFullName)"
            Remove-AppxPackage -Package $AppPackageFullName -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message
        }

        
        if ($AppProvisioningPackageName -ne $null) {
            try {
                Write-LogEntry -Value "Removing application provisioning package: $($AppProvisioningPackageName)"
                Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message
            }
        }
    }
}


Write-LogEntry -Value "Starting Features on Demand V2 removal"
$WhiteListOnDemand = "NetFX3|Tools.Graphics.DirectX|Tools.DeveloperMode.Core|Language"


$OnDemandFeatures = Get-WindowsCapability -Online | Where-Object { $_.Name -notmatch $WhiteListOnDemand -and $_.State -like "Installed"} | Select-Object -ExpandProperty Name

foreach ($Feature in $OnDemandFeatures) {
    try {
        Write-LogEntry -Value "Removing feature on demand: $($Feature)"
        Get-WindowsCapability -Online -ErrorAction Stop | Where-Object { $_.Name -like $Feature } | Remove-WindowsCapability -Online -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message
    }
}
