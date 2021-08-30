






 
 
 
Param 
(  
    [parameter(Mandatory=$true, Position=0, HelpMessage="Define valdation type: All, Domain, Zone, ZoneAging, ZoneDelegation, Forwarder, RootHints")] 
    [Alias("Type")] 
    [String[]] $ValidationType, 
    [parameter(Mandatory=$false, Position=1, HelpMessage="Full path of cache files.")] 
    [String] $Path = $pwd.path + "\",     
    [parameter(Mandatory=$false, HelpMessage="Clean-Up old cache files.")] 
    [Switch] $CleanUpOldCacheFiles, 
    [parameter(Mandatory=$false, HelpMessage="Clean-Up old report files.")] 
    [Switch] $CleanUpOldReports, 
    [parameter(Mandatory=$false, HelpMessage="Applicable with CleanUpOldCacheFiles & CleanUpOldReports switches and deletes the files without user confirmation.")] 
    [Switch] $Force, 
    [parameter(Mandatory=$false, HelpMessage="List of name resolvers on which health check need to be performed.")] 
    [String[]] $DnsServerList = $null, 
    [parameter(Mandatory=$false, HelpMessage="List of all available root domains across the enterprise.")] 
    [String[]] $DomainList = $null, 
    [parameter(Mandatory=$false, HelpMessage="List of zones to be verified.")] 
    [String[]] $ZoneList = $null, 
    [parameter(Mandatory=$false, HelpMessage="List of zone hosting servers, which hosts one or more zones.")] 
    [String[]] $ZoneHostingServerList = $null, 
    [parameter(Mandatory=$false, HelpMessage="List of DHCP servers across the enterprise.")] 
    [String[]] $DhcpServerList = $null 
) 
 



Set-StrictMode -Version 2 
 



Import-Module DNSServer -ErrorAction Ignore 
Import-Module DHCPServer -ErrorAction Ignore 
Import-Module ActiveDirectory -ErrorAction Ignore 
 
if (-not (Get-Module DNSServer)) { 
    throw 'The Windows Feature "DNS Server Tools" is not installed. ` 
        (On server SKU run "Install-WindowsFeature -Name RSAT-DNS-Server", on client SKU install RSAT client)' 
} 
 



$script:validValidationTypes = @("Domain", "Zone", "ZoneAging", "ZoneDelegation", "Forwarder", "RootHints"); 
$script:allValidationType = "All"; 
$script:switchParamVal = "__SWITCH__"; 
$script:cmdLetReturnedStatus = $null; 
 
$script:dnsServerList = $DnsServerList; 
$script:domainList = $DomainList; 
$script:zoneList = $ZoneList; 
$script:zoneHostingServerList = $ZoneHostingServerList; 
$script:dhcpServerList = $DhcpServerList; 
 
$script:dnsServerListFilePath = $Path + "DnsServerList.txt"; 
$script:domainListFilePath = $Path + "DomainList.txt"; 
$script:zoneListFilePath = $Path + "ZoneList.txt"; 
$script:zoneHostingServerListFilePath = $Path + "ZoneHostingServerList.txt"; 
$script:dhcpServerListFilePath = $Path + "DhcpServerList.txt"; 
 
$script:domainAndHostingServersList = $null; 
$script:zoneAndHostingServersList = $null; 
 



if ($CleanUpOldCacheFiles -and (Test-Path -Path ($Path + "*.txt") -PathType Leaf)) 
{ 
    if ($Force) { 
        Remove-Item -Path ($Path + "*.txt") -Force; 
    } else { 
        Remove-Item -Path ($Path + "*.txt") -Confirm; 
    } 
} 
 



if ($CleanUpOldReports -and (Test-Path -Path ($Path + "*.html") -PathType Leaf)) 
{ 
    if ($Force) { 
        Remove-Item -Path ($Path + "*.html") -Force; 
    } else { 
        Remove-Item -Path ($Path + "*.html") -Confirm; 
    } 
} 
 



$script:logLevel = @{ 
    "Verbose" = [int]1 
    ;"Host" = [int]2 
    ;"Warning" = [int]3 
    ;"Error" = [int]4 
} 
 



$script:resultView =@{ 
    "List" = "List" 
    ;"Table" = "Table" 
} 
 



Function LogComment 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [string]$message, 
    [int]$level = $script:logLevel.Verbose 
) 
    $message = ([DateTime]::Now).ToString() + ": " + $message; 
    switch ($level) 
    { 
        $script:logLevel.Verbose {Write-Verbose $message}; 
        $script:logLevel.Host {Write-Host -ForegroundColor Cyan $message}; 
        $script:logLevel.Warning {Write-Warning $message};    
        $script:logLevel.Error {Write-Error $message}; 
        default {throw "Not a valid log level: " + $level}; 
    } 
} 
 




Function ExecuteCmdLet 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [string]$cmdLetName, 
    [HashTable]$params = @{}    
) 
    $cmdString=$cmdLetName; 
    $displayString=$cmdLetName; 
    $script:cmdLetReturnedStatus = [RetStatus]::Success; 
    if ($null -ne $params) { 
        foreach($key in $params.keys) { 
            if ($script:switchParamVal -eq $params[$key]) { 
                $cmdString +=" -$key ";   
                $displayString +=" -$key "; 
            } else { 
                $cmdString += " -$key `$params[`"$key`"]"; 
                $displayString += " -$key $($params[$key])"; 
            } 
        } 
    }     
    $cmdString += " -ErrorAction Stop 2> `$null"; 
    $displayString += " -ErrorAction Stop 2> `$null"; 
    LogComment $displayString $script:logLevel.Host; 
    $retObj = $null; 
    try { 
        $retObj = Invoke-Expression $cmdString; 
    } catch [Exception] { 
        if (Get-Member -InputObject $_.Exception -Name "Errordata") 
        { 
            
            if (5 -eq $_.Exception.Errordata.error_Code) { 
                LogComment $("Caught error: Access is denied, considering it as current login creds don't have server read access.") ` 
                    $script:logLevel.Warning; 
                $script:cmdLetReturnedStatus = [RetStatus]::AccessIsDenied; 
            } elseif (1722 -eq $_.Exception.Errordata.error_Code) { 
                LogComment $("Caught error: The RPC server is unavailable, considering it as server is down.") ` 
                    $script:logLevel.Warning; 
                $script:cmdLetReturnedStatus = [RetStatus]::RpcServerIsUnavailable; 
            } elseif (9601 -eq $_.Exception.Errordata.error_Code) { 
                LogComment $("Caught error: DNS zone does not exist, considering it as given server isn't hosting input zone.") ` 
                    $script:logLevel.Warning; 
                $script:cmdLetReturnedStatus = [RetStatus]::ZoneDoesNotExist; 
            } elseif (9611 -eq $_.Exception.Errordata.error_Code) { 
                LogComment $("Caught error: Invalid DNS zone type, considering it as we can't perform current operation on input zone.") ` 
                    $script:logLevel.Warning; 
                $script:cmdLetReturnedStatus = [RetStatus]::OperationIsNotSupported; 
            } elseif (9714 -eq $_.Exception.Errordata.error_Code) { 
                LogComment $("Caught error: DNS name does not exist, considering it as input record doesn't exist.") ` 
                    $script:logLevel.Warning; 
                $script:cmdLetReturnedStatus = [RetStatus]::RecordDoesNotExist; 
            } else { 
                LogComment $("Caught error while executing '" + $displayString + "' with errorcode: " + $_.Exception.Errordata.error_Code) ` 
                    $script:logLevel.Error; 
                $script:cmdLetReturnedStatus = $([String]$_.Exception.Errordata.error_Code + ":" + $_.Exception.Errordata.error_WindowsErrorMessage); 
                
            } 
        } elseif (Get-Member -InputObject $_ -Name "FullyQualifiedErrorId") { 
            
            if ($_.FullyQualifiedErrorId.Contains("DNS_ERROR_RCODE_NAME_ERROR")) { 
                LogComment $("Caught error: ResolveDnsNameResolutionFailed in Resolve-DnsName.") $script:logLevel.Warning; 
                $script:cmdLetReturnedStatus = [RetStatus]::ResolveDnsNameResolutionFailed; 
            } elseif ($_.FullyQualifiedErrorId.Contains("System.Net.Sockets.SocketException")) { 
                LogComment $("Caught error: ResolveDnsNameServerNotFound in Resolve-DnsName.") $script:logLevel.Warning; 
                $script:cmdLetReturnedStatus = [RetStatus]::ResolveDnsNameServerNotFound; 
            } elseif ($_.FullyQualifiedErrorId.Contains("ERROR_TIMEOUT")) { 
                LogComment $("Caught error: ResolveDnsNameTimeoutPeriodExpired in Resolve-DnsName.") $script:logLevel.Warning; 
                $script:cmdLetReturnedStatus = [RetStatus]::ResolveDnsNameServerNotFound; 
            } else { 
                LogComment $("Caught error while executing '" + $displayString + "' `n" + $_.Exception) $script:logLevel.Error;   
                $script:cmdLetReturnedStatus = $([String]$_.FullyQualifiedErrorId + ":" + $_.Exception); 
                throw;   
            } 
        } else { 
            LogComment $("Caught error while executing '" + $displayString + "' `n" + $_.Exception) $script:logLevel.Error;   
            $script:cmdLetReturnedStatus = $($_.Exception); 
            throw;                               
        } 
    } 
    if ($null -eq $retObj) { 
        LogComment "CmdLet returned with NULL..." $script:logLevel.Host;         
    } 
    return $retObj 
} 
 






Function Get-EnterpriseDnsServerList 
{ 
param (   
    $dnsServerListFilePath = $script:dnsServerListFilePath, 
    $dhcpServerListFilePath = $script:dhcpServerListFilePath, 
    $dnsServerListFromCmdLine = $script:dnsServerList 
)     
    $dnsServerList = $null;   
    if ($null -eq $dnsServerListFromCmdLine) {     
        
        $dnsServerList = Get-FileContent $dnsServerListFilePath;     
    } else { 
        $dnsServerList = $dnsServerListFromCmdLine; 
    } 
    if ($null -eq $dnsServerList) { 
        LogComment "Unable to load DNS servers from the cache. So loading from DHCP servers."          
        if (-not(Get-Module DHCPServer)) { 
            LogComment $('The Windows Feature "DHCP Server Tools" is not installed. ` 
                (On server SKU run "Install-WindowsFeature -Name RSAT-DHCP", on client SKU install RSAT client)') ` 
                $script:logLevel.Warning; 
            LogComment $("Skipping this step and returning with NULL DNS List.") $script:logLevel.Warning;  
            return $null; 
        } 
         
        
        $dhcpServerList = Get-EnterpriseDhcpServerList $dhcpServerListFilePath; 
         
        if ($null -eq $dhcpServerList) { 
            LogComment $("No DHCP servers were found, returning with NULL DNS server list.") $script:logLevel.Warning; 
            return $null; 
        } 
         
        
        $optionList = @(); 
 
        $v4Options = Get-EnterpriseDhcpv4OptionId $dhcpServerList $false; 
        $optionList += $v4Options; 
 
        $v4Options = Get-EnterpriseDhcpv4OptionId $dhcpServerList $true; 
        $optionList += $v4Options; 
 
        $v6Options = Get-EnterpriseDhcpv6OptionId $dhcpServerList $false; 
        $optionList += $v6Options; 
 
        $v6Options = Get-EnterpriseDhcpv6OptionId $dhcpServerList $true; 
        $optionList += $v6Options; 
         
        $optionList = $optionList  | ?{-not([String]::IsNullOrEmpty($_))}; 
         
        if ($null -eq $optionList) { 
            LogComment $("No DNS server found in configured DHCP options across all input DHCP servers, returning with NULL DNS server list.") $script:logLevel.Warning; 
        } else { 
            
            $servers = @(); 
            $optionList | %{ $servers += $_.Value }; 
            $dnsServerList = $servers | sort -Unique;         
            ExecuteCmdLet "Set-Content" @{"Path" = $dnsServerListFilePath; "Value" = $dnsServerList}; 
        } 
    }     
    return $dnsServerList; 
} 
 





Function Get-EnterpriseDomainList 
{ 
param ( 
    $domainListFilePath = $script:domainListFilePath, 
    $domainListFromCmdLine = $script:domainList 
) 
    $domainList = $null; 
    if ($null -eq $domainListFromCmdLine) { 
        
        $domainList = Get-FileContent $domainListFilePath;     
    } else { 
        $domainList = $domainListFromCmdLine; 
    } 
    if ($null -eq $domainList) { 
        LogComment "Failed to load domains from the file. So loading from AD."; 
        try { 
            if (Get-Module ActiveDirectory) {                 
                $forestObj = ExecuteCmdLet "Get-ADForest"; 
                if ($null -ne $forestObj) { 
                    $domainList = $forestObj.Domains; 
                } 
                if ($null -ne $domainList) { 
                    ExecuteCmdLet "Set-Content" @{"Path" = $domainListFilePath; "Value" = $domainList}; 
                } else { 
                    LogComment $("Unable to obtain domainList from Get-ADForest. Returning with NULL DomainList.") ` 
                        $script:logLevel.Warning; 
                } 
            } else { 
                LogComment $('The Windows Feature "Active Directory module for Windows PowerShell" is not installed. ` 
                    (On server SKU run "Install-WindowsFeature -Name RSAT-AD-PowerShell", on client SKU install RSAT client)') $script:logLevel.Warning; 
                LogComment $("Skipping this step and returning with NULL DomainList.") $script:logLevel.Warning;                 
            } 
        } catch [Exception] { 
            LogComment $("Get-ADForest failed, Skipping this step and returning with NULL DomainList. `n" ` 
                + $_.Exception) $script:logLevel.Warning; 
        } 
    } 
     
    return $domainList; 
} 
 




Function Get-EnterpriseZoneList 
{ 
param ( 
    $zoneListFilePath = $script:zoneListFilePath, 
    $zoneListFromCmdLine = $script:zoneList 
) 
    $zoneList = $null; 
    if ($null -eq $zoneListFromCmdLine) { 
        
        $zoneList = Get-FileContent $zoneListFilePath;     
    } else { 
        $zoneList = $zoneListFromCmdLine; 
    }    
    return $zoneList; 
} 
 





Function Get-EnterpriseZoneHostingServerList 
{ 
param ( 
    $zoneHostingServerListFilePath = $script:zoneHostingServerListFilePath, 
    $dnsServerList = $script:dnsServerList, 
    $zoneHostingServerListFromCmdLine = $script:zoneHostingServerList 
)     
    $zoneHostingServerList = $null; 
     
    if ($null -eq $zoneHostingServerListFromCmdLine) {        
        
        LogComment $("Filling Zone Hosting Servers list from the file."); 
        $zoneHostingServerList = Get-FileContent $zoneHostingServerListFilePath;     
    } else { 
        $zoneHostingServerList = $zoneHostingServerListFromCmdLine; 
    }         
     
    if ($null -eq $zoneHostingServerList) { 
        
        LogComment $("Zone Hosting Servers list isn't available, returning with DNS Server list."); 
        $zoneHostingServerList = $dnsServerList;  
    }     
    return $zoneHostingServerList; 
} 
 





Function Get-EnterpriseDhcpServerList 
{ 
param ( 
    $dhcpServerListFilePath = $script:dhcpServerListFilePath, 
    $dhcpServerListFromCmdLine = $script:dhcpServerList 
)  
    $dhcpServerList = $null; 
    if ($null -eq $dhcpServerListFromCmdLine) {        
        
        $dhcpServerList = Get-FileContent $dhcpServerListFilePath;  
    } else { 
        $dhcpServerList = $dhcpServerListFromCmdLine; 
    } 
    if ($null -eq $dhcpServerList) {  
        LogComment "Failed to load DHCP server list from the file. So loading from AD."; 
        $dhcpObjList = ExecuteCmdLet "Get-DhcpServerInDC"; 
        foreach($dhcpObj in $dhcpObjList) { 
            if ($null -eq $dhcpServerList) {$dhcpServerList = @()}; 
            $dhcpServerList += $dhcpObj.IPAddress; 
        } 
    } 
     
    return $dhcpServerList; 
} 
 





Function Get-EnterpriseDomainAndHostingServersHash 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $domainHostingServers, 
    $domainListFilePath = $script:domainListFilePath      
) 
    $domainAndHostingServersHash = $null;   
    
    
    $domainList = Get-EnterpriseDomainList $domainListFilePath; 
    if ($null -ne $domainList) {     
        
        $domainAndHostingServersHash = @{}; 
        foreach($domain in $domainList) { 
            $domainHostingServer = Get-ZoneHostingServerListFromNSRecords $domain; 
            $domainAndHostingServersHash.Add($domain, $domainHostingServer); 
        } 
        Write-HashTableInHtml $domainAndHostingServersHash "DomainAndHostingServersHash"; 
    } else {     
        LogComment $("Failed to get domain list. So returning with NULL HashTable.") $script:logLevel.Warning; 
    }     
    return $domainAndHostingServersHash; 
} 
 




Function Get-EnterpriseZoneAndHostingServersHash 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $zoneHostingServerList, 
    $zoneListFilePath = $script:zoneListFilePath      
) 
    $zoneAndHostingServersHash = $null;   
    
    $zoneList = Get-EnterpriseZoneList $zoneListFilePath;   
    if ($null -ne $zoneList) {     
        $zoneAndHostingServersHash = Get-ServersHostingTheZones $zoneList $zoneHostingServerList; 
    } else {     
        LogComment $("Failed to load zones from the file. So loading it from zoneHostingServerList."); 
        if ($null -ne $zoneHostingServerList) {             
            $zoneAndHostingServersHash = Get-ZonesHostingOnServers $zoneHostingServerList;    
            Write-HashTableInHtml $zoneAndHostingServersHash "ZoneAndHostingServersHash"; 
        } else { 
            LogComment $("Failed to get Zone Hosting Servers list. Returning with NULL.") $script:logLevel.Warning;            
        } 
    }     
    return $zoneAndHostingServersHash; 
} 
 




Function Get-ServersHostingTheZones 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $zoneList, 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $zoneHostingServerList  
) 
    $zoneAndHostingServersHash = $null; 
    foreach($zone in $zoneList) { 
        if ($null -eq $zoneAndHostingServersHash) {$zoneAndHostingServersHash = @{}}; 
        if ($zoneAndHostingServersHash.ContainsKey($zone)) { 
            LogComment $($zone + " is already there in ZoneAndHostingServersList."); 
            continue; 
        } 
        LogComment $("Searching for servers which are hosting Zone: " + $zone); 
        $serverList = $null; 
        foreach($server in $zoneHostingServerList) { 
            $tempZoneObj = ExecuteCmdLet "Get-DnsServerZone" @{"ComputerName" = $server; "ZoneName" = $zone}; 
            if ($null -ne $tempZoneObj) { 
                if ($null -eq $serverList) {$serverList = @()};  
                LogComment $($server + " is hosting Zone: " + $zone); 
                $serverList += $server; 
            } else { 
                if ([RetStatus]::ZoneDoesNotExist -eq $script:cmdLetReturnedStatus) { 
                    LogComment $($server + " doesn't host Zone: " + $zone); 
                } else { 
                    LogComment $("Failed to get " + $zone + " info on " + $server + " with error " + $script:cmdLetReturnedStatus) ` 
                       $script:logLevel.Error;  
                } 
            } 
        }  
        if ($null -eq $serverList) { 
            LogComment $("Didn't find any server which is hosting Zone: " + $zone) ` 
                $script:logLevel.Warning; 
        } 
        $zoneAndHostingServersHash.Add($zone, $serverList);            
    }  
     
    return $zoneAndHostingServersHash; 
} 
 




Function Get-ZonesHostingOnServers 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $zoneHostingServerList  
) 
    $zoneAndHostingServersHash = $null;     
     
    foreach($zoneHostingServer in $zoneHostingServerList) {                 
        $tempZoneObj = ExecuteCmdLet "Get-DnsServerZone" @{"ComputerName" = $zoneHostingServer}; 
        if ($null -ne $tempZoneObj) { 
            foreach ($zone in $tempZoneObj) { 
                if (($false -eq $zone.IsAutoCreated) -and ("TrustAnchors" -ne $zone.ZoneName)) { 
                    if ($null -eq $zoneAndHostingServersHash) {$zoneAndHostingServersHash = @{}};  
                    LogComment $($zoneHostingServer + " is hosting Zone: " + $zone.ZoneName); 
                    if ($zoneAndHostingServersHash.ContainsKey($zone.ZoneName)) { 
                        $zoneAndHostingServersHash[$zone.ZoneName] += $zoneHostingServer; 
                    } else { 
                        $zoneAndHostingServersHash.Add($zone.ZoneName, @($zoneHostingServer)); 
                    } 
                } 
            } 
        }  else { 
            if ([RetStatus]::Success -eq $script:cmdLetReturnedStatus) { 
                LogComment $($zoneHostingServer + " doesn't host any Zone"); 
            } else { 
                LogComment $("Failed to get Zone info on " + $zoneHostingServer + " with error " + $script:cmdLetReturnedStatus) ` 
                    $script:logLevel.Error;  
            } 
        } 
    }     
    return $zoneAndHostingServersHash; 
} 
 



Function Get-EnterpriseDhcpv4OptionId 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [Array]$dhcpServerList, 
    $scopeOption = $false,  
    $OptionId = 6 
) 
    $optionList = @(); 
 
    foreach ($dhcpServer in $dhcpServerList) { 
        try { 
            if ($true -eq $scopeOption) { 
                $scopeOptions = @(); 
                $scopeList = ExecuteCmdLet "Get-DhcpServerv4Scope" @{"ComputerName" = $dhcpServer}; 
                foreach ($scope in $scopeList) { 
                    try { 
                        $scopeOption = ExecuteCmdLet "Get-DhcpServerv4OptionValue" ` 
                            @{"ComputerName" = $dhcpServer; "OptionId" = $OptionId; "ScopeId" = $scope.ScopeId}; 
                        $scopeOptions += $scopeOption; 
                    } catch { 
                        LogComment "Failed to get options for the scope $($scope.ScopeId). Continuing..."; 
                    } 
                } 
                $optionList += $scopeOptions; 
            } else { 
                try { 
                    $serverOptions = ExecuteCmdLet "Get-DhcpServerv4OptionValue" ` 
                        @{"ComputerName" = $dhcpServer; "OptionId" = $OptionId}; 
                    $optionList += $serverOptions; 
                } catch { 
                    LogComment "Get-DhcpServerv4OptionValue -ComputerName $($dhcpServer) -OptionId $OptionId failed. Continuing..."; 
                } 
            } 
        } catch { 
            LogComment "Get-DhcpServerv4Scope -ComputerName $($dhcpServer) failed" $script:logLevel.Error; 
        } 
    } 
     
    $optionList = $optionList  | ?{-not([String]::IsNullOrEmpty($_))}; 
    if ($null -eq $optionList) { 
        LogComment $("No DHCPv4 option found across the DHCP servers for ScopeOption = " + $scopeOption + ", returning with NULL option list.") $script:logLevel.Warning; 
    } 
    return $optionList; 
} 
 



Function Get-EnterpriseDhcpv6OptionId 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [Array]$dhcpServerList, 
    $scopeOption = $false,  
    $OptionId = 23 
) 
    $optionList = @(); 
 
    foreach ($dhcpServer in $dhcpServerList) { 
        try { 
            if ($true -eq $scopeOption) { 
                $scopeOptions = @(); 
                $scopeList = ExecuteCmdLet "Get-DhcpServerv6Scope" @{"ComputerName" = $dhcpServer}; 
                foreach ($scope in $scopeList) { 
                    try { 
                        $scopeOption = ExecuteCmdLet "Get-DhcpServerv6OptionValue" ` 
                            @{"ComputerName" = $dhcpServer; "OptionId" = $OptionId; "Prefix" = $scope.Prefix}; 
                        $scopeOptions += $scopeOption; 
                    } catch { 
                        LogComment "Failed to get options for the scope $($scope.Prefix). Continuing..."; 
                    } 
                } 
                $optionList += $scopeOptions; 
            } else { 
                try { 
                    $serverOptions = ExecuteCmdLet "Get-DhcpServerv6OptionValue" ` 
                        @{"ComputerName" = $dhcpServer; "OptionId" = $OptionId}; 
                    $optionList += $serverOptions; 
                } catch { 
                    LogComment "Get-DhcpServerv6OptionValue -ComputerName $($dhcpServer) -OptionId $OptionId failed. Continuing..."; 
                } 
            } 
        } catch { 
            LogComment $("Get-DhcpServerv6Scope -ComputerName $($dhcpServer) failed") $script:logLevel.Error; 
        } 
    } 
 
    $optionList = $optionList  | ?{-not([String]::IsNullOrEmpty($_))}; 
    if ($null -eq $optionList) { 
        LogComment $("No DHCPv6 option found across the DHCP servers for ScopeOption = " + $scopeOption + ", returning with NULL option list.") $script:logLevel.Warning; 
    } 
    return $optionList; 
} 
 






Function Test-ZoneHealthAcrossAllDnsServers 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $zoneList, 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $dnsServerList, 
    [bool]$isRootZone = $false, 
    [String]$outputReportName = $MyInvocation.MyCommand 
) 
    $statusArray = @(); 
     
    foreach($zone in $zoneList) { 
     
        $status = New-Object PSObject; 
        $status | Add-Member -memberType NoteProperty -name "ZoneName" -value $zone; 
         
        foreach($dnsServer in $dnsServerList) {  
            try { 
                $result = [RetStatus]::Success; 
                $resultStream = $null; 
                 
                $retVal1 = Test-DnsServerForInputDnsName $zone $dnsServer; 
                $resultStream = $resultStream + "ResolveDnsName:" + $retVal1 + "`n"; 
                $retVal2 = Test-DnsServerForInputZone $zone $dnsServer $dnsServer;  
                $resultStream = $resultStream + "TestDnsServer:" + $retVal2 + "`n"; 
             
                if (!(([RetStatus]::Success -eq $retVal1) -and ([RetStatus]::Success -eq $retVal2))) { 
                    $result = [RetStatus]::Failure; 
                } 
             
                
                if ($isRootZone) { 
                    $retVal3 = Test-DnsServerForInputDnsName ("_msdcs." + $zone) $dnsServer; 
                    $resultStream = $resultStream + "MsdcsResolveDnsName:" + $retVal3 + "`n"; 
                    $retVal4 = Test-DnsServerForInputZone ("_msdcs." + $zone) $dnsServer $dnsServer; 
                    $resultStream = $resultStream + "MsdcsTestDnsServer:" + $retVal4 + "`n"; 
                    $retVal5 = Test-DnsServerForInputDnsName ("_ldap._tcp.dc._msdcs." + $zone) $dnsServer "SRV"; 
                    $resultStream = $resultStream + "LdapTCPMsdcsResolveDnsName:" + $retVal5 + "`n"; 
                    if (!(([RetStatus]::Success -eq $retVal3) -and ([RetStatus]::Success -eq $retVal4) -and ([RetStatus]::Success -eq $retVal5))) { 
                        $result = [RetStatus]::Failure; 
                    } 
                } 
             
                if ([RetStatus]::Success -eq $result) { 
                    LogComment $("Validation of " + $zone + " passed on DNS Server: " + $dnsServer); 
                    LogComment $("Validation of " + $zone + " passed on DNS Server: " + $dnsServer) 
                        $script:logLevel.Host;                 
                } else {                     
                    LogComment $("Validation of " + $zone + " failed on DNS Server: " + $dnsServer) 
                        $script:logLevel.Error;  
                    LogComment $("Validation output:" + $resultStream) $script:logLevel.Error; 
                    $result = $resultStream; 
                } 
            } catch { 
                LogComment $("Test-ZoneHealthAcrossAllDnsServers failed for Zone: " + $zone + " on DNSServer: " + $dnsServer + " `n " + $_.Exception) ` 
                    $script:logLevel.Error; 
                $result = [RetStatus]::Failure; 
            }             
            $status = Insert-ResultInObject $status $dnsServer $result; 
        }   
        $statusArray += $status; 
    }     
    Generate-Report $statusArray $outputReportName $script:resultView.Table; 
    return $statusArray; 
} 
 





Function Test-RootDomainHealthAcrossAllDnsServers 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [HashTable]$domainAndHostingServerHash, 
    $dnsServerList 
) 
    Test-ZoneHealthAcrossAllDnsServers $domainAndHostingServerHash.Keys $dnsServerList $true $MyInvocation.MyCommand 
} 
 







Function Test-ZoneAgingHealth 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [HashTable]$zoneAndHostingServersHash 
) 
 
    $status = New-Object PSObject; 
    foreach($zone in $zoneAndHostingServersHash.keys) { 
             
        $result = [RetStatus]::Success;  
        $agingStatus = $false; 
        $defaultRefreshInterval = [Timespan]::FromHours(168); 
         
        foreach($server in $zoneAndHostingServersHash[$zone]) {          
            try {                
                $retObj = ExecuteCmdLet "Get-DnsServerZoneAging" @{"ComputerName" = $server; "ZoneName" = $zone}; 
                                         
                if ($null -ne $retObj) { 
                    if ($retObj.AgingEnabled) { 
                        LogComment $("Aging is enabled on Server: " + $server + " for Zone: " + $zone);   
                     
                        
                        
                        if ($defaultRefreshInterval -ne $retObj.RefreshInterval) { 
                            LogComment $("RefreshInterval is set to non-default value: " + $retObj.RefreshInterval) ` 
                                $script:logLevel.Warning; 
                        } 
                        if ($defaultRefreshInterval -ne $retObj.NoRefreshInterval) { 
                            LogComment $("NoRefreshInterval is set to non-default value: " + $retObj.NoRefreshInterval) ` 
                                $script:logLevel.Warning; 
                        }  
                        if ($null -eq $retObj.ScavengeServers) { 
                            LogComment $("There's no ScavengeServers configured.") $script:logLevel.Warning; 
                        }     
                     
                        
                        if ($agingStatus) { 
                            $result = [RetStatus]::Failure; 
                            LogComment $("Aging is enabled on more than one server for Zone: " + $zone) ` 
                                $script:logLevel.Warning; 
                        } else {                          
                            $agingStatus = $true; 
                        } 
                    } else { 
                        LogComment $("Aging is disabled on Server: " + $server + " for Zone: " + $zone);                    
                    } 
                } else { 
                    if ([RetStatus]::OperationIsNotSupported -eq $script:cmdLetReturnedStatus) { 
                        LogComment $($zone + " is non-primary zone on " + $server); 
                    } else { 
                        LogComment $("Failed to get " + $zone + " aging info on " + $server + " with error " + $script:cmdLetReturnedStatus) ` 
                            $script:logLevel.Error; 
                        $result = [RetStatus]::Failure; 
                    } 
                }                
            } catch { 
                LogComment $("Test-ZoneAgingHealth failed for Zone: " + $zone + " on Server: " + $server + " `n " + $_.Exception) ` 
                    $script:logLevel.Error; 
                $result = [RetStatus]::Failure; 
            } 
         
            
            if (!$agingStatus) { 
                LogComment $("No server found with zone aging enabled for the Zone: " + $zone) ` 
                    $script:logLevel.Warning;  
                $result = [RetStatus]::Failure; 
            } 
             
            if ([RetStatus]::Success -eq $result) { 
                LogComment $("Zone Aging setting validation of " + $zone + " passed."); 
                LogComment $("Zone Aging setting validation of " + $zone + " passed.") ` 
                    $script:logLevel.Host;                 
            } else { 
                LogComment $("Zone Aging setting validation of " + $zone + " failed.") ` 
                    $script:logLevel.Error;                 
            }         
            $status = Insert-ResultInObject $status $zone $result; 
        } 
    }     
    Generate-Report $status $MyInvocation.MyCommand $script:resultView.List; 
    return $status; 
} 
 




Function Test-ZoneDelegationHealth 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [HashTable]$zoneAndHostingServersHash 
)     
    $statusArray = @();     
     
    foreach($zone in $zoneAndHostingServersHash.keys) {      
        foreach($server in $zoneAndHostingServersHash[$zone]) {   
            
            $rrObj = ExecuteCmdLet "Get-DnsServerResourceRecord" @{"ComputerName" = $server; "RRType" = "NS"; "ZoneName" = $zone};              
            
            $rrObj = $rrObj |? hostname -ne "@";             
            $zoneDelObj = $null;             
            if ($null -ne $rrObj) { 
                LogComment $("Performing delegation check for " + $zone + " on " + $server); 
                foreach($rr in $rrObj) {  
                    $result = [RetStatus]::Success; 
                    $resultStream = $null; 
                    $status = New-Object PSObject; 
                    $status | Add-Member -memberType NoteProperty -name "ZoneName :: Server" -value ($zone + " :: " + $server) -Force;                     
                    try { 
                        $zoneDelObj = ExecuteCmdLet "Get-DnsServerZoneDelegation" @{"ComputerName" = $server; "ZoneName" = $zone; "ChildZoneName" = $rr.hostname};  
                        if ($null -eq $zoneDelObj) { 
                            LogComment $("Failed to get info for " + $rr.hostname + " on " + $server + " with error " + $script:cmdLetReturnedStatus) ` 
                                $script:logLevel.Error;  
                            if ([RetStatus]::Success -eq $script:cmdLetReturnedStatus) { 
                                $result = [RetStatus]::Failure; 
                            } else {                             
                                $result = $script:cmdLetReturnedStatus; 
                            } 
                        } else {  
                            foreach($zoneDel in $zoneDelObj) { 
                                $zoneDelName = $zoneDel.ChildZoneName; 
                                LogComment $("Validating ZoneDelegation: " + $zoneDelName + " at server: " + $server); 
                                [Array]$rr_ip = $zoneDel.IPAddress 
                                foreach ($ipRec in $rr_ip) { 
                                    if ($null -ne $ipRec){ 
                                        $ipAddr = @(); 
                                        if ($ipRec.RecordType -eq "A") { 
                                            $ipAddr = $ipRec.RecordData.IPv4Address 
                                        } else { 
                                            $ipAddr = $ipRec.RecordData.IPv6Address 
                                        }   
                                        foreach ($ip in $ipAddr) { 
                                            $retVal = Test-DnsServerForInputDnsName $zoneDelName $ip; 
                                            $resultStream = $resultStream + $ip.IPAddressToString + ":" + $retVal + "`n"; 
                                            if ([RetStatus]::Success -eq $retVal) { 
                                                LogComment $("Validated NameServer IP: " + $ip + " for ZoneDelegation: " + $zoneDelName + " on Server: " + $server); 
                                                LogComment $("Validated NameServer IP: " + $ip + " for ZoneDelegation: " + $zoneDelName + " on Server: " + $server) ` 
                                                    $script:logLevel.Host;                 
                                            } else { 
                                                $result = [RetStatus]::Failure; 
                                                LogComment $("Validation of NameServer IP: " + $ip + " for ZoneDelegation: " + $zoneDelName + " on Server: " + $server + " failed.") ` 
                                                    $script:logLevel.Error; 
                                            } 
                                        } 
                                    } else { 
                                        $result = [RetStatus]::Failure; 
                                        $resultStream = $resultStream + "NullIPAddressRecord;"; 
                                        LogComment $("IPAddress record is null for ZoneDelegation: " + $zoneDelName + " on Server: " + $server) $script:logLevel.Error; 
                                    }   
                                }  
                            } 
                            if ([RetStatus]::Success -ne $result) { 
                                $result = $resultStream; 
                                LogComment $("Validation output:" + $resultStream) $script:logLevel.Error; 
                            } 
                        } 
                    } catch { 
                        LogComment $("Test-ZoneDelegationHealth failed for Zone: " + $zone + " on Server: " + $server + " `n " + $_.Exception) ` 
                            $script:logLevel.Error; 
                        $result = [RetStatus]::Failure; 
                    } 
                    $status = Insert-ResultInObject $status $rr.hostname $result; 
                    $statusArray += $status; 
                }             
            } else { 
                if ([RetStatus]::Success -eq $script:cmdLetReturnedStatus) { 
                    LogComment $("There's no non-root NS record in " + $zone + " on " + $server); 
                } elseif ([RetStatus]::OperationIsNotSupported -eq $script:cmdLetReturnedStatus) { 
                    LogComment $($zone + " isn't a primary or secondary zone on " + $server); 
                } else { 
                    LogComment $("Failed to get NS records under " + $zone + " on " + $server + " with error " + $script:cmdLetReturnedStatus)  ` 
                        $script:logLevel.Error;  
                    $status = New-Object PSObject; 
                    $status | Add-Member -memberType NoteProperty -name "ZoneName :: Server" -value ($zone + " :: " + $server) -Force; 
                    $status = Insert-ResultInObject $status "Get-DnsServerResourceRecord" $script:cmdLetReturnedStatus; 
                    $statusArray += $status; 
                } 
            } 
        }         
    }      
    Generate-Report $statusArray $MyInvocation.MyCommand $script:resultView.List; 
    return $statusArray; 
} 
 




Function Test-ConfiguredForwarderHealth 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()]     
    $dnsServerList 
) 
    $statusArray = @(); 
     
    foreach($dnsServer in $dnsServerList) { 
        $status = New-Object PSObject; 
        $status | Add-Member -memberType NoteProperty -name "DNSServer" -value $dnsServer;  
        try { 
            $retObj = ExecuteCmdLet "Get-DnsServerForwarder" @{"ComputerName" = $dnsServer}; 
            if ($null -ne $retObj) { 
                LogComment $("Performing Forwarder health check for DnsServer: " + $dnsServer); 
                foreach($fwdIp in $retObj.IPAddress) {              
                    $result = Test-DnsServerForInputContext $fwdIp.IPAddressToString "Forwarder" $dnsServer; 
                    if ([RetStatus]::Success -eq $result) {                 
                        LogComment $("Validated Forwarder: " + $fwdIp.IPAddressToString + " of DNS Server: " + $dnsServer); 
                        LogComment $("Validated Forwarder: " + $fwdIp.IPAddressToString + " of DNS Server: " + $dnsServer) ` 
                            $script:logLevel.Host;                 
                    } else {             
                        LogComment $("Validation of Forwarder: " + $fwdIp.IPAddressToString + " of DNS Server: " + $dnsServer + " failed.") ` 
                            $script:logLevel.Error; 
                    }      
                    $status = Insert-ResultInObject $status $fwdIp $result; 
                }             
            } else { 
                if ([RetStatus]::Success -ne $script:cmdLetReturnedStatus) { 
                    LogComment $("Unable to get Forwarder list for DnsServer: " + $dnsServer) ` 
                        $script:logLevel.Error;    
                    $status = Insert-ResultInObject $status "Get-DnsServerForwarder" $script:cmdLetReturnedStatus; 
                } else { 
                    LogComment $("There's no forwarder configured on DnsServer: " + $dnsServer); 
                    $status = Insert-ResultInObject $status "NoForwarderConfigured" $script:cmdLetReturnedStatus; 
                }                
            } 
        } catch { 
            LogComment $("Test-ConfiguredForwarderHealth failed on DNSServer: " + $dnsServer + " `n " + $_.Exception) ` 
                $script:logLevel.Error; 
            $status = Insert-ResultInObject $status "ForwarderHealthCheckFailed" [RetStatus]::Failure; 
        } 
        $statusArray += $status; 
    }     
    Generate-Report $statusArray $MyInvocation.MyCommand $script:resultView.List;  
    return $statusArray; 
} 
 




Function Test-ConfiguredRootHintsHealth 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()]     
    $dnsServerList 
)     
    $statusArray = @(); 
     
    foreach($dnsServer in $dnsServerList) { 
     
        $status = New-Object PSObject; 
        $status | Add-Member -memberType NoteProperty -name "DNSServer" -value $dnsServer;    
        try { 
            $retObj = ExecuteCmdLet "Get-DnsServerRootHint" @{"ComputerName" = $dnsServer}; 
            if ($null -ne $retObj) { 
                LogComment $("Performing RootHints health check for DnsServer: " + $dnsServer); 
                foreach($rH in $retObj) {          
                    $result = [RetStatus]::Success; 
                    $resultStream = $null; 
                    $rHName = $rH.NameServer.RecordData.NameServer; 
                    LogComment $("Validating RootHints: " + $rHName + " for DnsServer: " + $dnsServer); 
                    [Array]$rr_ip = $rH.IPAddress 
                    foreach ($ipRec in $rr_ip) { 
                        $ipAddr = @(); 
                        if ($ipRec.RecordType -eq "A") { 
                            $ipAddr = $ipRec.RecordData.IPv4Address 
                        } else { 
                            $ipAddr = $ipRec.RecordData.IPv6Address 
                        }   
                        foreach ($ip in $ipAddr) { 
                            $retVal = Test-DnsServerForInputContext $ip "RootHints" $dnsServer; 
                            $resultStream = $resultStream + $ip.IPAddressToString + ":" + $retVal + "`n"; 
                            if ([RetStatus]::Success -eq $retVal) { 
                                LogComment $("Validated RootHints: " + $ip + " of DNS Server: " + $dnsServer); 
                                LogComment $("Validated RootHints: " + $ip + " of DNS Server: " + $dnsServer) ` 
                                    $script:logLevel.Host;                 
                            } else { 
                                $result = [RetStatus]::Failure; 
                                LogComment $("Validation of RootHints: " + $ip + " of DNS Server: " + $dnsServer + " failed.") ` 
                                    $script:logLevel.Error; 
                            } 
                        }                         
                    } 
                    if ([RetStatus]::Success -eq $result) { 
                        $status = Insert-ResultInObject $status $rHName $result; 
                    } else { 
                        $status = Insert-ResultInObject $status $rHName $resultStream; 
                        LogComment $("Validation output:" + $resultStream) $script:logLevel.Error; 
                    } 
                } 
            } else { 
                if ([RetStatus]::Success -ne $script:cmdLetReturnedStatus) { 
                    LogComment $("Unable to get RootHints list for DnsServer: " + $dnsServer) ` 
                        $script:logLevel.Error;    
                    $status = Insert-ResultInObject $status "Get-DnsServerRootHint" $script:cmdLetReturnedStatus; 
                } else { 
                    LogComment $("There's no RootHints configured on DnsServer: " + $dnsServer); 
                    $status = Insert-ResultInObject $status "NoRootHintConfigured" $script:cmdLetReturnedStatus; 
                } 
            } 
        } catch { 
            LogComment $("Test-ConfiguredRootHintsHealth failed on DNSServer: " + $dnsServer + " `n " + $_.Exception) ` 
                $script:logLevel.Error; 
            $result = [RetStatus]::Failure; 
            $status = Insert-ResultInObject $status "RootHintsHealthCheckFailed" $result; 
        } 
        $statusArray += $status; 
    } 
     
    Generate-Report $statusArray $MyInvocation.MyCommand $script:resultView.List; 
    return $statusArray; 
} 
 



Function Test-DnsServerForInputDnsName 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $dnsName, 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $dnsServer, 
    $rrType = "All" 
)     
    $result = [RetStatus]::Failure;  
 
    try {     
        $retObj = ExecuteCmdLet "Resolve-DnsName" @{"Name" = $dnsName; "Type" = $rrType; "Server" = $dnsServer}; 
        if ($null -eq $retObj) { 
            LogComment $("Resolve-DnsName for " + $dnsName + " failed on server " + $dnsServer + " with " + $script:cmdLetReturnedStatus) ` 
                $script:logLevel.Error;  
            $result = $script:cmdLetReturnedStatus; 
        } else { 
            LogComment $("Name resolution of " + $dnsName + " passed on server " + $dnsServer);  
            $result = [RetStatus]::Success; 
        } 
         
    } catch { 
        LogComment $("Test-DnsServerForInputDnsName failed " + $_.Exception) $script:logLevel.Error; 
        $result = [RetStatus]::Failure; 
    }    
     
    return $result; 
} 
 



Function Test-DnsServerForInputZone 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $zoneName, 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $dnsServer, 
    $remoteServer = "." 
)     
    $result = [RetStatus]::Failure;  
 
    try { 
     
        $dnsServerIP = $null; 
        if (![Net.IPaddress]::TryParse($dnsServer, [ref]$dnsServerIP)) { 
            try { 
                
                $dnsServerIP = [System.Net.Dns]::GetHostAddresses($dnsServer).IPAddressToString.Split(" ")[0];                 
            } catch { 
                LogComment $("Exception while trying to get IP Address of  " + $dnsServer + "`n" + $_.Exception) ` 
                    $script:logLevel.Error; 
                throw; 
            } 
        } 
         
        $retObj = ExecuteCmdLet "Test-DnsServer" @{"ComputerName" = $remoteServer; "ZoneName" = $zoneName; "IPAddress" = $dnsServerIP}; 
        if ($null -eq $retObj) {   
            LogComment $("Test-DnsServer failed for " + $zoneName + " on server " + $dnsServer) $script:logLevel.Warning;  
            $result = $script:cmdLetReturnedStatus; 
        } else { 
            if (($retObj.Result -eq "Success") -or ($retObj.Result -eq "NotAuthoritativeForZone")) { 
                LogComment $("Test-DnsServer passed for " + $zoneName + " on server " + $dnsServer + " with Result: " + $retObj.Result); 
                $result = [RetStatus]::Success; 
            } else { 
                LogComment $("Test-DnsServer failed for " + $zoneName + " on server " + $dnsServer + " with Result: " + $retObj.Result) ` 
                    $script:logLevel.Warning;  
                $result = $retObj.Result; 
            } 
        } 
    } catch { 
        LogComment $("Test-DnsServerForInputDnsName failed " + $_.Exception) $script:logLevel.Error; 
        $result = [RetStatus]::Failure; 
    }    
     
    return $result; 
} 
 



Function Test-DnsServerForInputContext 
{ 
param (     
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $dnsServer, 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $context, 
    $remoteServer = "." 
)     
    $result = [RetStatus]::Failure;   
 
    try { 
     
        $retObj = ExecuteCmdLet "Test-DnsServer" @{"ComputerName" = $remoteServer; "IPAddress" = $dnsServer; "Context" = $context}; 
        if ($null -eq $retObj) {   
            LogComment $("Test-DnsServer failed for DnsServer: " + $dnsServer + " with context: " + $context) $script:logLevel.Warning;  
            $result = $script:cmdLetReturnedStatus; 
        } else { 
            if ($retObj.Result -eq "Success") { 
                LogComment $("Test-DnsServer Passed for DnsServer: " + $dnsServer + " with context: " + $context + " and Result: " + $retObj.Result); 
                $result = [RetStatus]::Success; 
            } else { 
                LogComment $("Test-DnsServer Failed for DnsServer: " + $dnsServer + " with context: " + $context + " and Result: " + $retObj.Result) ` 
                    $script:logLevel.Warning;  
                $result = $retObj.Result; 
            } 
        } 
    } catch { 
        LogComment $("Test-DnsServerForInputContext failed " + $_.Exception) $script:logLevel.Error; 
        $result = [RetStatus]::Failure; 
    }    
     
    return $result; 
} 
 



Function Get-ZoneHostingServerListFromNSRecords 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    $dnsZone,     
    $dnsServer = $null 
)    
    try { 
        $retObj = $null; 
        $zoneHostingServerList = $null; 
        if ($null -eq $dnsServer) { 
            $retObj = ExecuteCmdLet "Resolve-DnsName" @{"Name" = $dnsZone; "Type" = "NS"}; 
        } else {     
            $retObj = ExecuteCmdLet "Resolve-DnsName" @{"Name" = $dnsZone; "Type" = "NS"; "Server" = $dnsServer}; 
        } 
         
        if ($null -eq $retObj) { 
            if ([RetStatus]::Success -eq $script:cmdLetReturnedStatus) { 
                LogComment $("No NS records found for zone: " + $dnsZone + " on server: " + $dnsServer) ` 
                    $script:logLevel.Warning;  
            } else { 
                LogComment $("Resolve-DnsName for " + $dnsZone + " failed on server " + $dnsServer + " with " + $script:cmdLetReturnedStatus) ` 
                    $script:logLevel.Error;  
            }             
        } else { 
            LogComment $("NS records found for zone: " + $dnsZone + " on server: " + $dnsServer); 
            $retObj = $retObj | ? Type -eq "NS"; 
            $zoneHostingServerList = @(); 
            $retObj | % {$zoneHostingServerList += $_.NameHost}; 
        } 
         
    } catch { 
        LogComment $("Get-ZoneHostingServerListFromNSRecords failed " + $_.Exception) $script:logLevel.Error; 
    }   
    return $zoneHostingServerList; 
} 
 




Function Get-FileContent 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [String]$filePath 
) 
    $fileContent = $null; 
    if (Test-Path $filePath) { 
        $fileContent = ExecuteCmdLet "Get-Content" @{"Path" = $filePath};         
    } else { 
        LogComment $($filePath + " not found."); 
    } 
    if ($null -ne $fileContent) { 
        $fileContent = $fileContent | ?{-not([String]::IsNullOrEmpty($_))}; 
    } else { 
        LogComment $("Returning with Null content for " + $filePath); 
    } 
    return $fileContent; 
} 
 



Function Generate-Report 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [Object]$inputObj,  
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [String]$contextName, 
    [String]$viewAs = $script:resultView.Table 
)     
 
    $head = @' 
    <!--mce:0--> 
'@ 
 
    $header = "<H1>DNS Health Report for " + $contextName + "</H1>"; 
    $ouputFile = $contextName + ".html"; 
    $inputObj = $inputObj | ? {$null -ne ($_ | gm -m properties)}; 
    $inputObj | 
        ConvertTo-Html -Head $head -Body $header -As $viewAs |  
        Out-File $ouputFile | Out-Null; 
         
    
    $success2Search = "<td>" + [RetStatus]::Success + "</td>"; 
    $success2Replace = "<td style=`"color:green;font-weight:bold;`">" + [RetStatus]::Success + "</td>"; 
    $failure2Search = "<td>" + [RetStatus]::Failure + "</td>"; 
    $failure2Replace = "<td style=`"color:red;font-weight:bold;`">" + [RetStatus]::Failure + "</td>"; 
     
    $content = Get-Content -path $ouputFile; 
    $content = $content -creplace $success2Search, $success2Replace; 
    $content = $content -creplace $failure2Search, $failure2Replace; 
    $content | Set-Content $ouputFile  -Encoding UTF8 | Out-Null; 
} 
 



Function Insert-ResultInObject 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [Object]$inputObj,  
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [String]$resultName, 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [String]$resultVal 
)         
    if (Get-Member -InputObject $inputObj -Name $resultName) { 
        $inputObj.$resultName = $resultVal;         
    } else { 
        $inputObj | Add-Member -memberType NoteProperty -name $resultName -value $resultVal;         
    }     
    return $inputObj; 
} 
 



Function Write-HashTableInHtml 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [HashTable]$inputHash,  
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [String]$fileLabel 
) 
    $tempHash = @{}; 
    foreach($key in $inputHash.Keys){ 
         $tempHash[$key] = $inputHash[$key] -join '; '; 
    }     
    $tempObj = New-Object PSObject -Property $tempHash; 
    Generate-Report $tempObj $fileLabel $script:resultView.List; 
} 
 




Function New-Enum 
{ 
param ( 
    [parameter(Mandatory=$true)] 
    [ValidateNotNullOrEmpty()] 
    [string] $enumName, 
    [Array] $enumVals = @() 
) 
    $appdomain = [System.Threading.Thread]::GetDomain(); 
    $assembly = new-object System.Reflection.AssemblyName; 
    $assembly.Name = "EmittedEnum"; 
    $assemblyBuilder = $appdomain.DefineDynamicAssembly($assembly, ` 
        [System.Reflection.Emit.AssemblyBuilderAccess]::Save -bor [System.Reflection.Emit.AssemblyBuilderAccess]::Run); 
    $moduleBuilder = $assemblyBuilder.DefineDynamicModule("DynamicModule", "DynamicModule.mod"); 
    $enumBuilder = $moduleBuilder.DefineEnum($enumName, [System.Reflection.TypeAttributes]::Public, [System.Int32]); 
    for($i = 0; $i -lt $enumVals.Count; $i++) { 
        $null = $enumBuilder.DefineLiteral($enumVals[$i], $i); 
    } 
    $enumBuilder.CreateType() > $null | Out-Null; 
}  
 



New-Enum -EnumName RetStatus -EnumVals @("Success", "Failure", "RpcServerIsUnavailable", "AccessIsDenied",  
                                         "ZoneDoesNotExist", "OperationIsNotSupported", "RecordDoesNotExist",  
                                         "NotApplicable","ResolveDnsNameServerNotFound", "ResolveDnsNameResolutionFailed",  
                                         "ResolveDnsNameTimeoutPeriodExpired"); 
                                          



New-Enum -EnumName ValidationType -EnumVals $script:validValidationTypes; 
 



 
try { 
    
    Start-Transcript Test-EnterpriseDnsHealth.txt | Out-Null;  
     
    if ($null -eq $script:dnsServerList) {$script:dnsServerList = Get-EnterpriseDnsServerList;}     
    if ($null -eq $script:dnsServerList) { 
        throw "Unable to get DNS server information. Exiting..."; 
    } 
     
    if ($null -eq $script:zoneHostingServerList) {$script:zoneHostingServerList = Get-EnterpriseZoneHostingServerList}; 
    if ($null -eq $script:zoneHostingServerList) { 
        throw "Unable to get Zone Hosting server information. Exiting..."; 
    } 
         
    if($ValidationType -icontains $script:allValidationType) { 
        LogComment $("Validation type contains 'All'. Performing all available health checks.") $script:logLevel.Host; 
        $applicableValidationTypes = $script:validValidationTypes; 
    } else { 
        $applicableValidationTypes =  $ValidationType; 
    } 
     
    foreach ($validationSubType in $applicableValidationTypes) {  
        LogComment $("Performing health check for Validation Type: " + $validationSubType) $script:logLevel.Host; 
        Switch ($validationSubType) 
        { 
            ([ValidationType]::Domain) {          
                if($null -eq $script:domainAndHostingServersList) { 
                    $script:domainAndHostingServersList = Get-EnterpriseDomainAndHostingServersHash $script:zoneHostingServerList; 
                } 
                if ($null -ne $script:domainAndHostingServersList) {         
                    Test-RootDomainHealthAcrossAllDnsServers $script:domainAndHostingServersList $script:dnsServerList; 
                } else { 
                LogComment $("No domain found, Skipping RootDomainHealthCheckUp") $script:logLevel.Warning; 
                } 
            } 
             
            ([ValidationType]::Zone) { 
                if($null -eq $script:zoneAndHostingServersList) { 
                    $script:zoneAndHostingServersList = Get-EnterpriseZoneAndHostingServersHash $script:zoneHostingServerList; 
                } 
                if ($null -ne $script:zoneAndHostingServersList) {             
                    Test-ZoneHealthAcrossAllDnsServers $script:zoneAndHostingServersList.Keys $script:dnsServerList; 
                } else { 
                    LogComment $("No zone found, Skipping ZoneHealthCheckUp") $script:logLevel.Warning; 
                } 
            } 
             
            ([ValidationType]::ZoneAging) { 
                if($null -eq $script:zoneAndHostingServersList) { 
                    $script:zoneAndHostingServersList = Get-EnterpriseZoneAndHostingServersHash $script:zoneHostingServerList; 
                } 
                if ($null -ne $script:zoneAndHostingServersList) {                                 
                    Test-ZoneAgingHealth $script:zoneAndHostingServersList;                                
                } else { 
                    LogComment $("No zone found, Skipping ZoneAgingHealthCheckUp") $script:logLevel.Warning; 
                } 
            }            
             
            ([ValidationType]::ZoneDelegation) { 
                if($null -eq $script:zoneAndHostingServersList) { 
                    $script:zoneAndHostingServersList = Get-EnterpriseZoneAndHostingServersHash $script:zoneHostingServerList; 
                } 
                if ($null -ne $script:zoneAndHostingServersList) {                                 
                    Test-ZoneDelegationHealth $script:zoneAndHostingServersList;             
                } else { 
                    LogComment $("No zone found, Skipping ZoneDelegationHealthCheckUp") $script:logLevel.Warning; 
                } 
            } 
             
            ([ValidationType]::Forwarder) { 
                Test-ConfiguredForwarderHealth $script:dnsServerList; 
            } 
             
            ([ValidationType]::RootHints) { 
                Test-ConfiguredRootHintsHealth $script:dnsServerList; 
            } 
             
            default { 
                LogComment $($validationSubType + " isn't a valid input ValidationType, skipping the validation.") $script:logLevel.Warning; 
                LogComment $("Choose '" + $script:allValidationType + "' or one or more validation types among below:`n" + $($script:validValidationTypes | Out-String)) ` 
                    $script:logLevel.Warning; 
            } 
        } 
    } 
} catch { 
    LogComment $("Caught exception during Test-EnterpriseDnsHealth: `n" + $_.Exception) $script:logLevel.Error; 
} Finally { 
    
    Stop-Transcript | Out-Null; 
    
    $logContent = Get-Content Test-EnterpriseDnsHealth.txt; 
    $logContent > Test-EnterpriseDnsHealth.txt | Out-Null; 
}