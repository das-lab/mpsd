
[CmdletBinding(SupportsShouldProcess=$true)]
[OutputType([PSObject])]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Specify the CI_UniqueID for the application to be translated")]
    [ValidateNotNullOrEmpty()]
    [string[]]$CIUniqueID
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
}
Process {
    $ResultsList = New-Object -TypeName System.Collections.ArrayList
    foreach ($ID in $CIUniqueID) {
        Write-Verbose -Message "Query: SELECT * FROM SMS_ApplicationLatest WHERE CI_UniqueID like '%$($ID)%'"
        $Application = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ApplicationLatest" -ComputerName $SiteServer -Filter "CI_UniqueID like '%$($ID)%'"
        if ($Application -ne $null) {
            $PSObject = [PSCustomObject]@{
                DisplayName = $Application.LocalizedDisplayName
                Version = $Application.SoftwareVersion
                CI_UniqueID = $Application.CI_UniqueID
            }
            $ResultsList.Add($PSObject) | Out-Null
        }
        else {
            Write-Verbose -Message "Unable to find an application matching the CI_UniqueID with '$($ID)'"
        }
    }
    Write-Output $ResultsList
}