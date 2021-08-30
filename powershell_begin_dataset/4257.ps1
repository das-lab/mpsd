
function New-IPv4Range
{
  param(
    [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
           $StartIP,
           
    [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
           $EndIP      
  )
  
    
    $ip1 = ([System.Net.IPAddress]$StartIP).GetAddressBytes()
    [Array]::Reverse($ip1)
    $ip1 = ([System.Net.IPAddress]($ip1 -join '.')).Address

    $ip2 = ([System.Net.IPAddress]$EndIP).GetAddressBytes()
    [Array]::Reverse($ip2)
    $ip2 = ([System.Net.IPAddress]($ip2 -join '.')).Address

    for ($x=$ip1; $x -le $ip2; $x++) {
        $ip = ([System.Net.IPAddress]$x).GetAddressBytes()
        [Array]::Reverse($ip)
        $ip -join '.'
    }
}

function New-IPRange
{
    [CmdletBinding(DefaultParameterSetName='CIDR')]
    Param(
        [parameter(Mandatory=$true,
        ParameterSetName = 'CIDR',
        Position=0)]
        [string]$CIDR,

        [parameter(Mandatory=$true,
        ParameterSetName = 'Range',
        Position=0)]
        [string]$Range   
    )
    if($CIDR)
    {
        $IPPart,$MaskPart = $CIDR.Split('/')
        $AddressFamily = ([System.Net.IPAddress]::Parse($IPPart)).AddressFamily

        
        $subnetMaskObj = [IPHelper.IP.Subnetmask]::Parse($MaskPart, $AddressFamily)
        
        
        $StartIP = [IPHelper.IP.IPAddressAnalysis]::GetClasslessNetworkAddress($IPPart, $subnetMaskObj)
        $EndIP = [IPHelper.IP.IPAddressAnalysis]::GetClasslessBroadcastAddress($IPPart,$subnetMaskObj)
        
        
        $StartIP = [IPHelper.IP.IPAddressAnalysis]::Increase($StartIP)
        $EndIP = [IPHelper.IP.IPAddressAnalysis]::Decrease($EndIP)
        [IPHelper.IP.IPAddressAnalysis]::GetIPRange($StartIP, $EndIP)
    }
    elseif ($Range)
    {
        $StartIP, $EndIP = $range.split('-')
        [IPHelper.IP.IPAddressAnalysis]::GetIPRange($StartIP, $EndIP)
    }
}


function New-IPv4RangeFromCIDR 
{
    param(
		[Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
				   $Network
    )
    
    $StrNetworkAddress = ($Network.split('/'))[0]
    [int]$NetworkLength = ($Network.split('/'))[1]
    $NetworkIP = ([System.Net.IPAddress]$StrNetworkAddress).GetAddressBytes()
    $IPLength = 32-$NetworkLength
    [Array]::Reverse($NetworkIP)
    $NumberOfIPs = ([System.Math]::Pow(2, $IPLength)) -1
    $NetworkIP = ([System.Net.IPAddress]($NetworkIP -join '.')).Address
    $StartIP = $NetworkIP +1
    $EndIP = $NetworkIP + $NumberOfIPs
    
    If ($EndIP -isnot [double])
    {
        $EndIP = $EndIP -as [double]
    }
    If ($StartIP -isnot [double])
    {
        $StartIP = $StartIP -as [double]
    }
    
    $StartIP = ([System.Net.IPAddress]$StartIP).IPAddressToString
    $EndIP = ([System.Net.IPAddress]$EndIP).IPAddressToString
    New-IPv4Range $StartIP $EndIP
}

$runme =
{
     param
     (
         [Object]
         $IPAddress,
         [Object]
         $Creds,
         [Object]
         $Command
     )

    $getcreds = $Creds
    $Port = 135
    $Socket = New-Object Net.Sockets.TcpClient
    $Socket.client.ReceiveTimeout = 2000
    $ErrorActionPreference = 'SilentlyContinue'
    $Socket.Connect($IPAddress, $Port)
    $ErrorActionPreference = 'Continue'
    
    if ($Socket.Connected) {
        
        $endpointResult = New-Object PSObject | Select-Object Host, PortOpen
        $endpointResult.PortOpen = 'Open'
        $endpointResult.Host = $IPAddress
        $Socket.Close()        
    } else {
        $portclosed = 'True'
    }
        
    $Socket = $null
   
    if ($endpointResult.PortOpen -eq 'Open')
    {
        
        $WMIResult = Invoke-WmiMethod -Path Win32_process -Name create -ComputerName $IPAddress -Credential $getcreds -ArgumentList $Command
        If ($WMIResult.Returnvalue -eq 0) {
            Write-Output "Executed WMI Command with Sucess: $Command `n" 
        } else {
            Write-Output "WMI Command Failed - Could be due to permissions or UAC is enabled on the remote host, Try mounting the C$ share to check administrative access to the host"
        } 
    } else {
        Write-Output "TCP Port 135 not available on host: $IPAddress"  
    }
    return $endpointResult
}

function Invoke-WMICommand
{
     param
     (
         [Object]
         $IPAddress,
         [Object]
         $IPRangeCIDR,
         [Object]
         $IPList,
         [Object]
         $Threads,
         [Object]
         $Command,
         [Object]
         $username,
         [Object]
         $password
     )
    
    if ($username) { 
        $PSS = ConvertTo-SecureString $password -AsPlainText -Force
        $getcreds = new-object system.management.automation.PSCredential $username,$PSS
    } else {
        $getcreds = Get-Credential
    }

    if ($IPList) {$iprangefull = Get-Content $IPList}
    if ($IPRangeCIDR) {$iprangefull = New-IPv4RangeFromCIDR $IPRangeCIDR}
    if ($IPAddress) {$iprangefull = $IPAddress}
    Write-Output ''
    Write-Output $iprangefull.count + "Total hosts read from file"
     
    $jobs = @()
    $start = get-date
    Write-Output "Begin Scanning at $start"

    
    
    if (!$Threads){$Threads = 64}   
    $pool = [runspacefactory]::CreateRunspacePool(1, $Threads)   
    $pool.Open()
    $endpointResults = @()
    $jobs = @()   
    $ps = @()   
    $wait = @()

    $i = 0
    
    foreach ($endpoint in $iprangefull)
    {
        while ($($pool.GetAvailableRunspaces()) -le 0) {
            Start-Sleep -milliseconds 500
        }
    
        
        $ps += [powershell]::create()

        
        $ps[$i].runspacepool = $pool

        
        [void]$ps[$i].AddScript($runme)
        [void]$ps[$i].AddParameter('IPAddress', $endpoint)
        [void]$ps[$i].AddParameter('Creds', $getcreds) 
        [void]$ps[$i].AddParameter('Command', $Command)   
        
        $jobs += $ps[$i].BeginInvoke();
     
        
        $wait += $jobs[$i].AsyncWaitHandle
    
        $i++
    }
     
    Write-Output 'Waiting for scanning threads to finish...'

    $waitTimeout = get-date

    while ($($jobs | Where-Object {$_.IsCompleted -eq $false}).count -gt 0 -or $($($(get-date) - $waitTimeout).totalSeconds) -gt 60) {
            Start-Sleep -milliseconds 500
        } 
  
    
    for ($y = 0; $y -lt $i; $y++) {     
  
        try {   
            
            $endpointResults += $ps[$y].EndInvoke($jobs[$y])   
  
        } catch {   
       
            
            write-warning "error: $_"  
        }
    
        finally {
            $ps[$y].Dispose()
        }     
    }

    $pool.Dispose()
    
    
    $end = get-date
    $totaltime = $end - $start

    Write-Output "We scanned $($iprangefull.count) endpoints in $($totaltime.totalseconds) seconds"
    $endpointResults
}