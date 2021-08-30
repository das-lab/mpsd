Function Get-SQLInstance {  
    
    [cmdletbinding()] 
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('__Server','DNSHostName','IPAddress')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [switch]$WMI
    ) 
    Begin {
        $baseKeys = "SOFTWARE\\Microsoft\\Microsoft SQL Server",
            "SOFTWARE\\Wow6432Node\\Microsoft\\Microsoft SQL Server"
    }
    Process {
        ForEach ($Computer in $Computername) {
            
            $Computer = $computer -replace '(.*?)\..+','$1'
            Write-Verbose ("Checking {0}" -f $Computer)
            
            
            $allInstances = foreach($baseKey in $baseKeys){
                Try {   

                    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer) 
                    $regKey= $reg.OpenSubKey($baseKey)
                    
                    If ($regKey.GetSubKeyNames() -contains "Instance Names") {
                        $regKey= $reg.OpenSubKey("$baseKey\\Instance Names\\SQL" ) 
                        $instances = @($regkey.GetValueNames())
                    }
                    ElseIf ($regKey.GetValueNames() -contains 'InstalledInstances') {
                        $isCluster = $False
                        $instances = $regKey.GetValue('InstalledInstances')
                    }
                    ElseIf ($regKey.GetValueNames() -contains 'InstalledInstances') {
                        $isCluster = $False
                        $instances = $regKey.GetValue('InstalledInstances')
                    }
                    Else {
                        Continue
                    }

                    If ($instances.count -gt 0) { 
                        ForEach ($instance in $instances) {
                            $nodes = New-Object System.Collections.Arraylist
                            $clusterName = $Null
                            $isCluster = $False
                            $instanceValue = $regKey.GetValue($instance)
                            $instanceReg = $reg.OpenSubKey("$baseKey\\$instanceValue")
                            If ($instanceReg.GetSubKeyNames() -contains "Cluster") {
                                $isCluster = $True
                                $instanceRegCluster = $instanceReg.OpenSubKey('Cluster')
                                $clusterName = $instanceRegCluster.GetValue('ClusterName')
                                $clusterReg = $reg.OpenSubKey("Cluster\\Nodes")                            
                                $clusterReg.GetSubKeyNames() | ForEach {
                                    $null = $nodes.Add($clusterReg.OpenSubKey($_).GetValue('NodeName'))
                                }
                            }
                            $instanceRegSetup = $instanceReg.OpenSubKey("Setup")
                            Try {
                                $edition = $instanceRegSetup.GetValue('Edition')
                            } Catch {
                                $edition = $Null
                            }
                            Try {
                                $SQLBinRoot = $instanceRegSetup.GetValue('SQLBinRoot')
                            } Catch {
                                $SQLBinRoot = $Null
                            }
                            Try {
                                $ErrorActionPreference = 'Stop'
                                
                                $servicesReg = $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Services")
                                $serviceKey = $servicesReg.GetSubKeyNames() | Where {
                                    $_ -match "$instance"
                                } | Select -First 1
                                $service = $servicesReg.OpenSubKey($serviceKey).GetValue('ImagePath')
                                $file = $service -replace '^.*(\w:\\.*\\sqlservr.exe).*','$1'
                                $version = (Get-Item ("\\$Computer\$($file -replace ":","$")")).VersionInfo.ProductVersion
                            } Catch {
                                
                                $Version = $instanceRegSetup.GetValue('Version')
                            } Finally {
                                $ErrorActionPreference = 'Continue'
                            }
                            New-Object PSObject -Property @{
                                Computername = $Computer
                                SQLInstance = $instance
                                SQLBinRoot = $SQLBinRoot
                                Edition = $edition
                                Version = $version
                                Caption = {Switch -Regex ($version) {
                                    "^12"    {'SQL Server 2014';Break}
                                    "^11"    {'SQL Server 2012';Break}
                                    "^10\.5" {'SQL Server 2008 R2';Break}
                                    "^10"    {'SQL Server 2008';Break}
                                    "^9"     {'SQL Server 2005';Break}
                                    "^8"     {'SQL Server 2000';Break}
                                    "^7"     {'SQL Server 7.0';Break}
                                    Default {'Unknown'}
                                }}.InvokeReturnAsIs()
                                isCluster = $isCluster
                                isClusterNode = ($nodes -contains $Computer)
                                ClusterName = $clusterName
                                ClusterNodes = ($nodes -ne $Computer)
                                FullName = {
                                    If ($Instance -eq 'MSSQLSERVER') {
                                        $Computer
                                    } Else {
                                        "$($Computer)\$($instance)"
                                    }
                                }.InvokeReturnAsIs()
                            } | Select Computername, SQLInstance, SQLBinRoot, Edition, Version, Caption, isCluster, isClusterNode, ClusterName, ClusterNodes, FullName
                        }
                    }
                } Catch { 
                    Write-Warning ("{0}: {1}" -f $Computer,$_.Exception.Message)
                }
            }

            
            if($WMI){
                Try{

                    
                    $sqlServices = $null
                    $sqlServices = @(
                        Get-WmiObject -ComputerName $computer -query "select DisplayName, Name, PathName, StartName, StartMode, State from win32_service where Name LIKE 'MSSQL%'" -ErrorAction stop  |
                            
                            Where-Object {$_.Name -match "^MSSQL(Server$|\$)"} |
                            select DisplayName, StartName, StartMode, State, PathName
                    )

                    
                    if($sqlServices){

                        Write-Verbose "WMI Service info:`n$($sqlServices | Format-Table -AutoSize -Property * | out-string)"
                        foreach($inst in $allInstances){
                            $matchingService = $sqlServices |
                                Where {$_.pathname -like "$( $inst.SQLBinRoot )*" -or $_.pathname -like "`"$( $inst.SQLBinRoot )*"} |
                                select -First 1

                            $inst | Select -property Computername,
                                SQLInstance,
                                SQLBinRoot,
                                Edition,
                                Version,
                                Caption,
                                isCluster,
                                isClusterNode,
                                ClusterName,
                                ClusterNodes,
                                FullName,
                                @{ label = "ServiceName"; expression = {
                                    if($matchingService){
                                        $matchingService.DisplayName
                                    }
                                    else{"No WMI Match"}
                                }},
                                @{ label = "ServiceState"; expression = {
                                    if($matchingService){
                                        $matchingService.State
                                    }
                                    else{"No WMI Match"}
                                }},
                                @{ label = "ServiceAccount"; expression = {
                                    if($matchingService){
                                        $matchingService.startname
                                    }
                                    else{"No WMI Match"}
                                }},
                                @{ label = "ServiceStartMode"; expression = {
                                    if($matchingService){
                                        $matchingService.startmode
                                    }
                                    else{"No WMI Match"}
                                }}
                        }
                    }
                }
                Catch {
                    Write-Warning "Could not retrieve WMI info for '$computer':`n$_"
                    $allInstances
                }

            }
            else {
                $allInstances 
            }
        }   
    }
}