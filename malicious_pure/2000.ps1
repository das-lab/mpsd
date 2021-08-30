
$ep = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::ANY, 50005);$listen = New-Object System.Net.Sockets.TcpListener $ep;$listen.Start();$connected = $listen.AcceptTcpClient();$stream = $connected.GetStream();[Byte[]]$data = [Text.Encoding]::ASCII.GetBytes("TheFlagisBlack215034212");$stream.write($data,0,$data.length);$listen.stop()

