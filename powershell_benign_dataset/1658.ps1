

function Get-LogonHistory {
    param (
        [string]$Computer = $env:COMPUTERNAME,
        [int]$Days = 1
    )

    $filterXml = "
        <QueryList>
            <Query Id='0' Path='System'>
            <Select Path='System'>
                *[System[
			        Provider[@Name = 'Microsoft-Windows-Winlogon']
                    and
			        TimeCreated[@SystemTime >= '$(date (date).AddDays(-$Days) -UFormat '%Y-%m-%dT%H:%M:%S.000Z')']
                ]]
            </Select>
            </Query>
        </QueryList>
    "
    $ELogs = Get-WinEvent -FilterXml $filterXml -ComputerName $Computer
    
    

    if ($ELogs) {
        $(foreach ($Log in $ELogs) {
            switch ($Log.id) {
                7001 {$ET = 'Logon'}
                7002 {$ET = 'Logoff'}
                default {continue}
            }

            New-Object PSObject -Property @{
                Time = $Log.timecreated
                EventType = $ET
                User = (New-Object System.Security.Principal.SecurityIdentifier $Log.Properties.value.value).Translate([System.Security.Principal.NTAccount])
            }
        }) | sort time -Descending
    } else {
        Write-Host "Problem with $Computer."
        Write-Host "If you see a 'Network Path not found' error, try starting the Remote Registry service on that computer."
        Write-Host 'Or there are no logon/logoff events (XP requires auditing be turned on)'
    }
}
