

















$seed = "98"
function getVaultName{
    return "A2APowershellTest" + $seed;
}

function getVaultRg{
    return "A2APowershellTestRg" + $seed;
}


function getVaultRgLocation{
    return "eastus"
}

function getVaultLocation{
     return "eastus"
}

function getPrimaryLocation
{
    return "westus"
}

function getRecoveryLocation{
  return getVaultLocation
}

function getPrimaryFabric{
    return  "a2aPrimaryFabric"+$seed

}

function getRecoveryFabric{
    return  "a2aRecoveryFabric"+$seed

}

function getAzureVm{
    param([string]$primaryLocation)
    
        $VMLocalAdminUser = "adminUser"
        $VMLocalAdminSecurePassword = "password"
        $password=$VMLocalAdminSecurePassword|ConvertTo-SecureString -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $password);
        New-AzVM -Name MyVm -Credential $Credential -location getPrimaryLocation
}

function getPrimaryPolicy{
    return "TestA2APolicy1" + $seed;
}

function getRecoveryPolicy{
    return "TestA2APolicy1" + $seed;
}

function getPrimaryContainer{
    return "A2APrimaryContainer"+ $seed;
}


function getRecoveryContainer{
    return "A2ARecoveryContainer"+ $seed;
}


function getPrimaryContainerMapping{
    return "A2APCM"+ $seed;
}


function getRecoveryContainerMapping{
    return "A2ARCM"+ $seed;
}

function getPrimaryNetworkMapping{
    return "A2ANetworkMapping"+ $seed;
}

function getRecoveryNetworkMapping{
    return "A2ARecoveryNetworkMapping"+ $seed;
}

function getPrimaryNetworkId{
    param([string] $location , [string] $resourceGroup)

    
}

function getRecoveryNetworkId{
    param([string] $location , [string] $resourceGroup)

    $primaryNetworkName = "recoveryNetwork"+ $location + $seed;
    $virtualNetwork = New-AzVirtualNetwork `
          -ResourceGroupName $resourceGroup `
          -Location $location `
          -Name $primaryNetworkName `
          -AddressPrefix 10.0.0.0/16
    $virtualNetwork.id
}





function WaitForJobCompletion
{ 
    param(
        [string] $JobId,
        [int] $JobQueryWaitTimeInSeconds = 20,
        [string] $Message = "NA"
        )
        $isJobLeftForProcessing = $true;
        do
        {
            $Job = Get-AzRecoveryServicesAsrJob -Name $JobId
            Write-Host $("Job Status:") -ForegroundColor Green
            $Job

            $isJobLeftForProcessing = ($Job.State -eq 'InProgress' -or $Job.State -eq 'NotStarted')
            
            if($isJobLeftForProcessing)
            {
                if($Message -ne "NA")
                {
                    Write-Host $Message -ForegroundColor Yellow
                }
                else
                {
                    Write-Host $($($Job.JobType) + " in Progress...") -ForegroundColor Yellow
                }
                Write-Host $("Waiting for: " + $JobQueryWaitTimeInSeconds.ToString + " Seconds") -ForegroundColor Yellow
                [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait($JobQueryWaitTimeInSeconds * 1000)
            }else
            {
                if( !(($job.State -eq "Succeeded") -or ($job.State -eq "CompletedWithInformation")))
                {
                    throw "Job " + $JobId + "failed."
                }
            }
        }While($isJobLeftForProcessing)
}


Function WaitForIRCompletion
{ 
    param(
        [PSObject] $affectedObjectId,
        [int] $JobQueryWaitTimeInSeconds = 10
        )
        $isProcessingLeft = $true
        $IRjobs = $null

        Write-Host $("IR in Progress...") -ForegroundColor Yellow
        do
        {
            $IRjobs = Get-AzRecoveryServicesAsrJob -TargetObjectId $affectedObjectId | Sort-Object StartTime -Descending | select -First 2 | Where-Object{$_.JobType -eq "SecondaryIrCompletion"}
            $isProcessingLeft = ($IRjobs -eq $null -or $IRjobs.Count -ne 1)

            if($isProcessingLeft)
            {
                Write-Host $("IR in Progress...") -ForegroundColor Yellow
                Write-Host $("Waiting for: " + $JobQueryWaitTimeInSeconds.ToString + " Seconds") -ForegroundColor Yellow
                [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait($JobQueryWaitTimeInSeconds * 1000)
            }
        }While($isProcessingLeft)

        Write-Host $("Finalize IR jobs:") -ForegroundColor Green
        $IRjobs
        WaitForJobCompletion -JobId $IRjobs[0].Name -JobQueryWaitTimeInSeconds $JobQueryWaitTimeInSeconds -Message $("Finalize IR in Progress...")
}
