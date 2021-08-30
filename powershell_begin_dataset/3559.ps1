















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
