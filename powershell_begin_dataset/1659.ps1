







filter ping1 {
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string[]]$comps = $env:COMPUTERNAME,
        [int]$n = 1,
        [switch]$showhost
    )

    begin {
        $ping = New-Object System.Net.NetworkInformation.Ping
    }

    process {
        if (!$comps) {Throw 'No host provided'}
        foreach ($comp in $comps) {
            for ($i = 0; $i -lt $n; $i++) {
                try{ $result = $ping.send($comp) }catch{}
                switch ($result.status) {
                    'Success' { $success = $true }
                    default { $success = $false }
                }
            }
            
            if ($showhost) {
                switch ($success) {
                    $true { "True  $(try{ $result.address.tostring() }catch{ $comp })" }
                    $false { "False $comp" }
                }
            } else {
                switch ($success) {
                    $true { $true }
                    $false { $false }
                }
            }
        }
    }
}
