
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server name with SMS Provider installed")]
    [ValidateNotNullorEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Name of the device that will be removed from any specified device collections")]
    [ValidateNotNullorEmpty()]
    [string]$DeviceName
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
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}
Process {
    
    function Write-LogFile {
        param(
            [parameter(Mandatory=$true, HelpMessage="Name of the log file, e.g. 'FileName'. File extension should not be specified")]
            [ValidateNotNullOrEmpty()]
            [string]$Name,
            [parameter(Mandatory=$true, HelpMessage="Value added to the specified log file")]
            [ValidateNotNullOrEmpty()]
            [string]$Value,
            [parameter(Mandatory=$true, HelpMessage="Choose a location where the log file will be created")]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("UserTemp","WindowsTemp")]
            [string]$Location
        )
        
        switch ($Location) {
            "UserTemp" { $LogLocation = ($env:TEMP + "\") }
            "WindowsTemp" { $LogLocation = ($env:SystemRoot + "\Temp\") }
        }
        
        $LogFile = ($LogLocation + $Name + ".log")
        
        if (-not(Test-Path -Path $LogFile -PathType Leaf)) {
            New-Item -Path $LogFile -ItemType File -Force | Out-Null
        }
        
        Add-Content -Value $Value -LiteralPath $LogFile -Force
    }

    
    Write-LogFile -Name "RemoveDeviceFromCollection" -Location WindowsTemp -Value "Determine ResourceID for DeviceName: $($DeviceName)"
    $ResourceIDs = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_R_System -Filter "Name like '$($DeviceName)'" | Select-Object -ExpandProperty ResourceID
    foreach ($ResourceID in $ResourceIDs) {
        Write-LogFile -Name "RemoveDeviceFromCollection" -Location WindowsTemp -Value "ResourceID: $($ResourceID)"
        
        $CollectionIDList = New-Object -TypeName System.Collections.ArrayList
        
        $CollectionIDList.AddRange(@("PS100052","PS1000A8","PS1000A1","PS100053"))
        foreach ($CollectionID in $CollectionIDList) {
            $Collection = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -Filter "CollectionID like '$($CollectionID)'"
            $Collection.Get()
            foreach ($CollectionRule in $Collection.CollectionRules) {
                
                if ($CollectionRule.ResourceID -like $ResourceID) {
                    Write-LogFile -Name "RemoveDeviceFromCollection" -Location WindowsTemp -Value "Removing '$($DeviceName)' from '$($Collection.Name)"
                    $Collection.DeleteMembershipRule($CollectionRule)
                }
            }
        }
    }
}