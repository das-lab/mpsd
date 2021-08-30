$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$httpUserPassword = $ENV:HttpPassword
$location = $ENV:Location


$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$loginCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword
$sshCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sshuser", $securePassword


function Get-Credential { 
    Param(
        [string]$Name
    )
    
    if($Name -eq "admin") {
        return $loginCreds
    } else {
        return $sshCreds
    }
}


$names="dasher","dancer","prancer","vixen","comet","cupid","donder","blitzen"
$baseName=Get-Random $names
$mills=Get-Date -Format ms

$resourceGroupName = $baseName + "rg" + $mills
$clusterName = $baseName + "hdi" + $mills
$storageAccountName = $basename + "store" + $mills

write-host "Creating new resource group named: $resourceGroupName"
Describe "hdinsight-hadoop-create-linux-clusters-azure-powershell" {
    It "Creates a Linux-based cluster using PowerShell" {
        
        Mock Read-Host { $resourceGroupName } -ParameterFilter {
            $Prompt -eq "Enter the resource group name"
        }
        Mock Read-Host { $location } -ParameterFilter {
            $Prompt -eq "Enter the Azure region to create resources in"
        }
        Mock Read-Host { $storageAccountName } -ParameterFilter {
            $Prompt -eq "Enter the name of the storage account"
        }
        Mock Read-Host { $clusterName } -ParameterFilter {
            $Prompt -eq "Enter the name of the HDInsight cluster"
        }

        
        $clusterInfo = New-Cluster
        
        
        $clusterInfo[-1].ClusterState | Should be "Running"
        $clusterInfo[-1].Name | Should be $clusterName
    }
}


write-host "Please remember that YOU must manually delete the $resourceGroupName resource group created by this test!!!"
