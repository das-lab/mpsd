
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Computer name of the system being deployed")]
    [ValidateNotNullorEmpty()]
    [string]$ComputerName,
    [parameter(Mandatory=$true, HelpMessage="Path to the MDT Deployment Share with monitoring enabled")]
    [ValidateNotNullorEmpty()]
    [string]$DeploymentShare,
    [parameter(Mandatory=$true, HelpMessage="Path to DartRemoteViewer.exe")]
    [ValidateNotNullorEmpty()]
    [ValidatePattern("^(?:[\w]\:|\\)(\\[a-z_\-\s0-9\.]+)+\.(exe)$")]
    [ValidateScript({
        
        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters" ; break
        }
        else {
            
            if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
                Write-Warning -Message "Unable to locate part of or the whole specified path" ; break
            }
            elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
                return $true
            }
            else {
                Write-Warning -Message "Unhandled error" ; break
            }
        }
    })]
    [string]$DaRTRemoteViewer
)
Begin {
    
    if ([System.Environment]::Is64BitProcess) {
        try {
            Write-Verbose -Message "Attempting to load Microsoft.BDD.PSSnapIn"
            Add-PSSnapIn -Name Microsoft.BDD.PSSnapIn -ErrorAction Stop -Verbose:$false | Out-Null
            Write-Verbose -Message "Creating PSDrive 'DS001' with root: $($DeploymentShare)"
            if (-not(Get-PSDrive -Name "DS001" -ErrorAction SilentlyContinue -Verbose:$false)) {
                New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "$($DeploymentShare)" -ErrorAction Stop -Verbose:$false | Out-Null
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
        
        try {
            Add-Type -AssemblyName "System.Windows.Forms" -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }
    else {
        Write-Warning -Message "Unable to load Microsoft.BDD.PSSnapIn. Point to SysNative instead of System32 path for PowerShell.exe" ; break
    }
}
Process {
    
    function Show-MessageBox {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            [Parameter(Mandatory=$true)]
            [string]$WindowTitle,
            [Parameter(Mandatory=$true)]
            [System.Windows.Forms.MessageBoxButtons]$Button,
            [Parameter(Mandatory=$true)]
            [System.Windows.Forms.MessageBoxIcon]$Icon
        )
        return [System.Windows.Forms.MessageBox]::Show($Message, $WindowTitle, $Button, $Icon)
    }
    
    try {
        $MonitoringData = Get-MDTMonitorData -Path "DS001:" | Where-Object { ($_.Name -eq "$($ComputerName)") -and ($_.DeploymentStatus -eq 1) }
        if ($MonitoringData -ne $null) {
            Write-Verbose -Message "Located monitored deployment for computer: $($ComputerName)"
            $ArgmentList = "-ticket=$($MonitoringData.DartTicket) -ipaddress=$($MonitoringData.DartIP) -port=$($MonitoringData.DartPort)"
            Write-Verbose -Message "Launching DartRemoteViewer.exe with the following arguments: '$($ArgmentList)'"
            Start-Process -FilePath $DaRTRemoteViewer -ArgumentList $ArgmentList -ErrorAction Stop
        }
        else {
            $Prompt = Show-MessageBox -Message "Unable to find active Operating System Deployment for $($ComputerName)" -WindowTitle "No data found" -Button OK -Icon Information
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}