function Get-HttpStatus
{


    [CmdletBinding()] Param(
        [Parameter(Mandatory = $True)]
        [String]
        $Target,

        [String]
        [ValidateNotNullOrEmpty()]
        $Path = '.\Dictionaries\admin.txt',

        [Int]
        $Port,

        [Switch]
        $UseSSL
    )
    
    if (Test-Path $Path) {
    
        if ($UseSSL -and $Port -eq 0) {
            
            $Port = 443
        } elseif ($Port -eq 0) {
            
            $Port = 80
        }
    
        $TcpConnection = New-Object System.Net.Sockets.TcpClient
        Write-Verbose "Path Test Succeeded - Testing Connectivity"
        
        try {
            
            $TcpConnection.Connect($Target, $Port)
        } catch {
            Write-Error "Connection Test Failed - Check Target"
            $Tcpconnection.Close()
            Return 
        }
        
        $Tcpconnection.Close()
    } else {
           Write-Error "Path Test Failed - Check Dictionary Path"
           Return
    }
    
    if ($UseSSL) {
        $SSL = 's'
        
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }
    } else {
        $SSL = ''
    }
    
    if (($Port -eq 80) -or ($Port -eq 443)) {
        $PortNum = ''
    } else {
        $PortNum = ":$Port"
    }
    
    
    foreach ($Item in Get-Content $Path) {

        $WebTarget = "http$($SSL)://$($Target)$($PortNum)/$($Item)"
        $URI = New-Object Uri($WebTarget)

        try {
            $WebRequest = [System.Net.WebRequest]::Create($URI)
            $WebResponse = $WebRequest.GetResponse()
            $WebStatus = $WebResponse.StatusCode
            $ResultObject += $ScanObject
            $WebResponse.Close()
        } catch {
            $WebStatus = $Error[0].Exception.InnerException.Response.StatusCode
            
            if ($WebStatus -eq $null) {
                
                
                $WebStatus = $Error[0].Exception.InnerException.Status
            }
        } 
        
        $Result = @{ Status = $WebStatus;
                     URL = $WebTarget}
        
        $ScanObject = New-Object -TypeName PSObject -Property $Result
        
        Write-Output $ScanObject
        
    }
}
