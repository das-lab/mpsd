
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the Primary Site server")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 2})]
    [string]$SiteServer = "$($env:COMPUTERNAME)",
    [parameter(Mandatory=$true, HelpMessage="Specify the name of a Distribution Point Group")]
    [string]$DPGName,
    [parameter(Mandatory=$false, HelpMessage="Specify the name of a Distribution Point Group")]
    [int]$CreatedDaysAgo = 1
)
Begin {
    
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
    
    try {
        Write-Verbose "Importing Configuration Manager module"
        Write-Debug ((($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) + "\ConfigurationManager.psd1")
        Import-Module ((($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) + "\ConfigurationManager.psd1") -Force -ErrorAction Stop -Verbose:$false
        if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue -Verbose:$false | Measure-Object).Count -ne 1) {
            New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer -ErrorAction Stop -Verbose:$false
        }
        
        Set-Location ($SiteCode + ":") -Verbose:$false
    }
    catch [Exception] {
        Throw $_.Exception.Message
    }
}
Process {
    
    try {
        $DPG = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_DistributionPointGroup -ComputerName $SiteServer -Filter "Name = '$($DPGName)'"
        if (($DPG | Measure-Object).Count -eq 1) {
            Write-Verbose "Found Distribution Point Group: $($DPG.Name)"
        }
        elseif (($DPG | Measure-Object).Count -gt 1) {
            Throw "Query for DPGs returned more than 1 object"
        }
        else {
            Throw "Unable to determine Distribution Point Group name from specified string for parameter 'DPGName'"
        }
    }
    catch [Exception] {
        Throw $_.Exception.Message
    }
    
    try {
        Write-Verbose "Enumerating applicable Applications"
        if ($PSBoundParameters["CreatedDaysAgo"]) {
            $Applications = Get-CMApplication -Verbose:$false | Select-Object LocalizedDisplayName, PackageID, DateCreated | Where-Object { $_.DateCreated -ge (Get-Date).AddDays(-$CreatedDaysAgo) }
        }
        else {
            $Applications = Get-CMApplication -Verbose:$false | Select-Object LocalizedDisplayName, PackageID
        }
        foreach ($Application in $Applications) {
            if (-not(Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_DPGroupDistributionStatusDetails -ComputerName $SiteServer -Filter "PackageID = '$($Application.PackageID)'" -ErrorAction SilentlyContinue)) {
                if ($PSCmdlet.ShouldProcess("$($DPG.Name)", "Distribute Application: $($Application.LocalizedDisplayName)")) {
                    $DPG.AddPackages($Application.PackageID) | Out-Null
                }
            }
        }
        Set-Location C:
    }
    catch [Exception] {
        Throw $_.Exception.Message
    }
}