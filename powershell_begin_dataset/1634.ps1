












function Get-ComputerShares {
    param (
        [string]$comp = $env:COMPUTERNAME
    )
    
    if (!$comp) { throw 'No comps.' }

    $ping = New-Object System.Net.NetworkInformation.Ping
    try {
        $result = $ping.Send($comp)
    } catch {
        $result = $null
    }

    $sharename = $type = $comment = $ip = '-'
    if ($result.Status -eq 'Success') {
        
        $ip = $result.Address.ToString()

        
        $netview = iex "cmd /c net view $comp 2>&1" | ? {$_}

        
        if ($netview.count -lt 5) {
            [pscustomobject]@{
                Computer = $comp
                IP = $ip
                ShareName = $sharename
                Type = $type
                Comment = $comment
            }
            return
        }

        $netview = $netview | ? {$_  -match '\s{2}'} | select -Skip 1

        foreach ($line in $netview) {
            $line = $line -split '\s{2,}'

            $sharename = $line[0]
            $type = $line[1]
            $comment = $line[2]

            [pscustomobject]@{
                Computer = $comp
                IP = $ip
                ShareName = $sharename
                Type = $type
                Comment = $comment
            }
        }
    } else {
        [pscustomobject]@{
            Computer = $comp
            IP = $ip
            ShareName = $sharename
            Type = $type
            Comment = $comment
        }
    }
}
