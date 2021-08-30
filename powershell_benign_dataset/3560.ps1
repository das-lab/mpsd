















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

