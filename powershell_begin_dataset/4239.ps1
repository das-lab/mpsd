
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
         [Bool]
         $Allshares,
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
        
        $endpointResult = New-Object PSObject | Select-Object Host, PortOpen, LoggedOnUsers, LocalAdministrators, Members, SharesTested, FilesFound
        $endpointResult.PortOpen = 'Open'
        $endpointResult.Host = $IPAddress
        $Socket.Close()        
    } else {
        $portclosed = 'True'
    }
        
    $Socket = $null
   
    if ($endpointResult.PortOpen -eq 'Open')
    {
        if ($command) {
        
        Invoke-WmiMethod -Path Win32_process -Name create -ComputerName $IPAddress -Credential $getcreds -ArgumentList $Command
        }
        
        $proc = Get-WmiObject -ComputerName $IPAddress -Credential $getcreds -query "SELECT * from win32_process WHERE Name = 'explorer.exe'"

        
        ForEach ($p in $proc) {
            $temp = '' | Select-Object Computer, Domain, User
            $user = ($p.GetOwner()).User
            $domain = ($p.GetOwner()).Domain
            if($user){
            $username = "$domain\$user"
            $endpointResult.LoggedOnUsers += "'$username' " 
            }

            
            
            $arr = @()   
            $ComputerName = (Get-WmiObject -ComputerName $IPAddress -Credential $getcreds -Class Win32_ComputerSystem).Name 
            $wmi = Get-WmiObject -ComputerName $ComputerName -Credential $getcreds -Query "SELECT * FROM Win32_GroupUser WHERE GroupComponent=`"Win32_Group.Domain='$ComputerName',Name='Administrators'`""  
  
            
            if ($wmi -ne $null)  
            {  
                foreach ($item in $wmi)  
                {  
                    $data = $item.PartComponent -split '\,' 
                    $domain = ($data[0] -split '=')[1] 
                    $name = ($data[1] -split '=')[1] 
                    $arr += ("$domain\$name").Replace('"','')
                    $currentuser = ("$domain\$name").Replace('"','')
                    [Array]::Sort($arr) 
                    if ($currentuser)
                    {
                    $endpointResult.Members += "'$currentuser' "
                    }
                    if ($currentuser -contains $username)
                    {
                    $endpointResult.LocalAdministrators += "'$currentuser' "
                    }
                }  
            }  
        }

        if (!$Allshares) {
            
            $wmiquery = 'Select * from Win32_Share'
            $availableShares = Get-WmiObject -Query $wmiquery -ComputerName $IPAddress -Credential($getcreds) 
            foreach ($share in $availableShares){
                if ($share.Name -eq 'ADMIN$'){
                    $sharename = $share.Name                   
                    $endpointResult.SharesTested += "'$sharename' "
                    $drive = ($share.Path).Substring(0,1)
                    $path = (($share.Path).Substring(2)).Replace('\','\\')
                    $path = $path+'\\'
                    $path = $path.Replace('\\\\\\\\','\\')
                    $path = $path.Replace('\\\\\\','\\')
                    $path = $path.Replace('\\\\','\\')
                    $datesearch = (Get-Date).AddMonths(-1).ToString('MM/dd/yyyy')
                    $wmiquery = "SELECT * FROM CIM_DataFile WHERE Drive='"+$drive+":' AND Path='"+$path+"' AND Extension='exe' AND CreationDate > '"+$datesearch+"' "
                    Get-WmiObject -Query $wmiquery -ComputerName $IPAddress -Credential($getcreds) | foreach{ $filename = $_.Name; $endpointResult.FilesFound += "'$filename' "} 
                 }
            }
        } else {
            
            $wmiquery = 'Select * from Win32_Share'
            $availableShares = Get-WmiObject -Query $wmiquery -ComputerName $IPAddress -Credential($getcreds) 
            foreach ($share in $availableShares){
                if ($share.Name -ne 'IPC$'){
                    $sharename = $share.Name
                    $endpointResult.SharesTested += "'$sharename' "
                    $drive = ($share.Path).Substring(0,1)
                    $path = (($share.Path).Substring(2)).Replace('\','\\')
                    $path = $path+'\\'
                    $path = $path.Replace('\\\\\\\\','\\')
                    $path = $path.Replace('\\\\\\','\\')
                    $path = $path.Replace('\\\\','\\')
                    $datesearch = (Get-Date).AddMonths(-1).ToString('MM/dd/yyyy')
                    $wmiquery = "SELECT * FROM CIM_DataFile WHERE Drive='"+$drive+":' AND Path='"+$path+"' AND Extension='exe' AND CreationDate > '"+$datesearch+"' "
                    Get-WmiObject -Query $wmiquery -ComputerName $IPAddress -Credential($getcreds) | foreach{ $filename = $_.Name; $endpointResult.FilesFound += "'$filename' "} 
                 }
            }
        }
    }   
    return $endpointResult
}

function Invoke-WMIChecker
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
         [Bool]
         $Allshares,
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
    Write-Output $iprangefull.count Total hosts read from file
     
    $jobs = @()
    $start = get-date
    Write-Output `n"Begin Scanning at $start" -ForegroundColor Red

    
    
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
        [void]$ps[$i].AddParameter('Allshares', $Allshares) 
        [void]$ps[$i].AddParameter('Command', $Command)   
        
        $jobs += $ps[$i].BeginInvoke();
     
        
        $wait += $jobs[$i].AsyncWaitHandle
    
        $i++
    }
     
    Write-Output 'Waiting for scanning threads to finish...' -ForegroundColor Cyan

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

    Write-Output "We scanned $($iprangefull.count) endpoints in $($totaltime.totalseconds) seconds" -ForegroundColor green
    $endpointResults
}