Function Get-ComputerInfo
{
    

    [CmdletBinding()]
    param(
        [Parameter(Position = 0,ValueFromPipeline = $true)]
        [Alias('CN','Computer')]
        [String[]]$ComputerName = "$env:COMPUTERNAME"
    )

    Begin
    {
        $i = 0
        
        $TempErrAct = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
		
        
        $CompInfoSelProp = @(
            'Computer'
            'Domain'
            'OperatingSystem'
            'OSArchitecture'
            'BuildNumber'
            'ServicePack'
            'Manufacturer'
            'Model'
            'SerialNumber'
            'Processor'
            'LogicalProcessors'
            'PhysicalMemory'
            'OSReportedMemory'
            'PAEEnabled'
            'InstallDate'
            'LastBootUpTime'
            'UpTime'
            'RebootPending'
            'RebootPendingKey'
            'CBSRebootPending'
            'WinUpdRebootPending'
            'LogonServer'
            'PageFile'
        )
		
        
        $NetInfoSelProp = @(
            'NICName'
            'NICManufacturer'
            'DHCPEnabled'
            'MACAddress'
            'IPAddress'
            'IPSubnetMask'
            'DefaultGateway'
            'DNSServerOrder'
            'DNSSuffixSearch'
            'PhysicalAdapter'
            'Speed'
        )
		
        
        $VolInfoSelProp = @(
            'DeviceID'
            'VolumeName'
            'VolumeDirty'
            'Size'
            'FreeSpace'
            'PercentFree'
        )
    }

    Process
    {
        Foreach ($Computer in $ComputerName)
        {
            Try
            {
                If ($ComputerName.Count -gt 1)
                {
                    
                    $WriteProgParams = @{
                        Id              = 1
                        Activity        = "Processing Get-ComputerInfo For $Computer"
                        Status          = "Percent Complete: $([int]($i/($ComputerName.Count)*100))%"
                        PercentComplete = [int]($i++/($ComputerName.Count)*100)
                    }
                    Write-Progress @WriteProgParams
                }
                        
                
                       
                $WMI_PROC = Get-WmiObject -Class Win32_Processor -ComputerName $Computer                      
                $WMI_BIOS = Get-WmiObject -Class Win32_BIOS -ComputerName $Computer
                $WMI_CS = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer
                $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer                      
                $WMI_PM = Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $Computer
                $WMI_LD = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = '3'" -ComputerName $Computer                  
                $WMI_NA = Get-WmiObject -Class Win32_NetworkAdapter -ComputerName $Computer                    
                $WMI_NAC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=$true" -ComputerName $Computer
                $WMI_HOTFIX = Get-WmiObject -Class Win32_quickfixengineering -ComputerName $ComputerName
                $WMI_NETLOGIN = Get-WmiObject -Class win32_networkloginprofile -ComputerName $Computer
                $WMI_PAGEFILE = Get-WmiObject -Class Win32_PageFileUsage

                
                $RegCon = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]'LocalMachine',$Computer)
                
                
                $WinBuild = $WMI_OS.BuildNumber
                $CBSRebootPend, $RebootPending = $false, $false
                If ([INT]$WinBuild -ge 6001)
                {
                    
                    $RegSubKeysCBS  = $RegCon.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\').GetSubKeyNames()
                    $CBSRebootPend  = $RegSubKeysCBS -contains 'RebootPending'

                    
                    $OSArchitecture = $WMI_OS.OSArchitecture
                    $LogicalProcs   = $WMI_CS.NumberOfLogicalProcessors
                }
                Else
                {
                    
                    $OSArchitecture = '**Unavailable**'

                    
                    If ($WMI_PROC.Count -gt 1)
                    {
                        $LogicalProcs = $WMI_PROC.Count
                    }
                    Else
                    {
                        $LogicalProcs = 1
                    }
                }
						
                
                $RegSubKeySM      = $RegCon.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\')
                $RegValuePFRO     = $RegSubKeySM.GetValue('PendingFileRenameOperations',$false)

                
                $RegWindowsUpdate = $RegCon.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\').GetSubKeyNames()
                $WUAURebootReq    = $RegWindowsUpdate -contains 'RebootRequired'
                $RegCon.Close()
						
                
                If ($CBSRebootPend -or $RegValuePFRO -or $WUAURebootReq)
                {
                    $RebootPending = $true
                }
						
                
                [int]$Memory  = ($WMI_PM | Measure-Object -Property Capacity -Sum).Sum / 1MB
                $InstallDate  = ([WMI]'').ConvertToDateTime($WMI_OS.InstallDate)
                $LastBootTime = ([WMI]'').ConvertToDateTime($WMI_OS.LastBootUpTime)
                $UpTime       = New-TimeSpan -Start $LastBootTime -End (Get-Date)
						
                
                $PAEEnabled = $false
                If ($WMI_OS.PAEEnabled)
                {
                    $PAEEnabled = $true
                }
						
                
                New-Object PSObject -Property @{
                    Computer            = $WMI_CS.Name
                    Domain              = $WMI_CS.Domain.ToUpper()
                    OperatingSystem     = $WMI_OS.Caption
                    OSArchitecture      = $OSArchitecture
                    BuildNumber         = $WinBuild
                    ServicePack         = $WMI_OS.ServicePackMajorVersion
                    Manufacturer        = $WMI_CS.Manufacturer
                    Model               = $WMI_CS.Model
                    SerialNumber        = $WMI_BIOS.SerialNumber
                    Processor           = ($WMI_PROC | Select-Object -ExpandProperty Name -First 1)
                    LogicalProcessors   = $LogicalProcs
                    PhysicalMemory      = $Memory
                    OSReportedMemory    = [int]$($WMI_CS.TotalPhysicalMemory / 1MB)
                    PAEEnabled          = $PAEEnabled
                    InstallDate         = $InstallDate
                    LastBootUpTime      = $LastBootTime
                    UpTime              = $UpTime
                    RebootPending       = $RebootPending
                    RebootPendingKey    = $RegValuePFRO
                    CBSRebootPending    = $CBSRebootPend
                    WinUpdRebootPending = $WUAURebootReq
                    LogonServer         = $ENV:LOGONSERVER
                    PageFile            = $WMI_PAGEFILE.Caption
                } | Select-Object $CompInfoSelProp
						
                
                Write-Output 'Network Adaptors'`n
                Foreach ($NAC in $WMI_NAC)
                {
                    
                    $NetAdap = $WMI_NA | Where-Object {
                        $NAC.Index -eq $_.Index
                    }
								
                    
                    If ($WinBuild -ge 6001)
                    {
                        $PhysAdap = $NetAdap.PhysicalAdapter
                        $Speed    = '{0:0} Mbit' -f $($NetAdap.Speed / 1000000)
                    }
                    Else
                    {
                        $PhysAdap = '**Unavailable**'
                        $Speed    = '**Unavailable**'
                    }

                    
                    New-Object PSObject -Property @{
                        NICName         = $NetAdap.Name
                        NICManufacturer = $NetAdap.Manufacturer
                        DHCPEnabled     = $NAC.DHCPEnabled
                        MACAddress      = $NAC.MACAddress
                        IPAddress       = $NAC.IPAddress
                        IPSubnetMask    = $NAC.IPSubnet
                        DefaultGateway  = $NAC.DefaultIPGateway
                        DNSServerOrder  = $NAC.DNSServerSearchOrder
                        DNSSuffixSearch = $NAC.DNSDomainSuffixSearchOrder
                        PhysicalAdapter = $PhysAdap
                        Speed           = $Speed
                    } | Select-Object $NetInfoSelProp
                }
							
                
                Write-Output 'Disk Information'`n
                Foreach ($Volume in $WMI_LD)
                {
                    
                    New-Object PSObject -Property @{
                        DeviceID    = $Volume.DeviceID
                        VolumeName  = $Volume.VolumeName
                        VolumeDirty = $Volume.VolumeDirty
                        Size        = $('{0:F} GB' -f $($Volume.Size / 1GB))
                        FreeSpace   = $('{0:F} GB' -f $($Volume.FreeSpace / 1GB))
                        PercentFree = $('{0:P}' -f $($Volume.FreeSpace / $Volume.Size))
                    } | Select-Object $VolInfoSelProp
                }
                Write-Output 'Hotfix(s) Installed: '$WMI_HOTFIX.Count`n
                $WMI_HOTFIX|Select-Object -Property Description, HotfixID, InstalledOn
            }

            Catch
            {
                Write-Warning "$_"
            }
        }

    }
	
    End
    {
        
        $ErrorActionPreference = $TempErrAct
    }
}
