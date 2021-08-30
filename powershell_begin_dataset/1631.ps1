

function Get-BitLockerInfo {
    param (
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$PsExecPath = 'C:\pstools\psexec.exe'
    )

    
    if (Test-Connection -ComputerName $ComputerName -Quiet -Count 2) {
        try{
            $user = (Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName ).UserName
        }
        catch {
            $user = 'UNKNOWN'
        }

        $hash = [ordered]@{
            'ComputerName' = $ComputerName
            'User'         = $user
        }

        
        
        $bitlockerinfo = (& $PsExecPath \\$ComputerName manage-bde -status c:) -replace ':','=' | Where-Object { $_ -match "^(\s{4})" } | ConvertFrom-StringData
        
        foreach ($key in $bitlockerinfo.Keys) {
            $hash.Add("$key", $bitlockerinfo."$key")
        }

        
        [PSCustomObject]$hash

    } else {
        Write-Error "Could not reach target computer: '$ComputerName'."
    }
}
