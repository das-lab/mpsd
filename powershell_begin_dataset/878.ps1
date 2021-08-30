function new-hdinsightwithscriptaction {
    
    $ErrorActionPreference = "Stop"

    
    $context = Get-AzContext
    if ($context -eq $null) 
    {
        Connect-AzAccount
    }
    $context

    
    
    

    
    $resourceGroupName = Read-Host -Prompt "Enter the resource group name"
    $location = Read-Host -Prompt "Enter the Azure region to create resources in"

    
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    $defaultStorageAccountName = Read-Host -Prompt "Enter the name of the storage account"

    
    New-AzStorageAccount `
        -ResourceGroupName $resourceGroupName `
        -Name $defaultStorageAccountName `
        -Type Standard_LRS `
        -Location $location
    $defaultStorageAccountKey = (Get-AzStorageAccountKey `
                                    -ResourceGroupName $resourceGroupName `
                                    -Name $defaultStorageAccountName)[0].Value
    $defaultStorageContext = New-AzStorageContext `
                                    -StorageAccountName $defaultStorageAccountName `
                                    -StorageAccountKey $defaultStorageAccountKey

    
    $clusterName = Read-Host -Prompt "Enter the name of the HDInsight cluster"
    
    $httpCredential = Get-Credential -Message "Enter Cluster login credentials" -UserName "admin"
    
    $sshCredential = Get-Credential -Message "Enter SSH user credentials"

    
    $clusterSizeInNodes = "4"
    $clusterVersion = "3.5"
    $clusterType = "Hadoop"
    $clusterOS = "Linux"
    
    $defaultBlobContainerName = $clusterName

    
    New-AzStorageContainer `
        -Name $clusterName -Context $defaultStorageContext

    
    $config = New-AzHDInsightClusterConfig
    
    $scriptActionUri="https://hdiconfigactions.blob.core.windows.net/linuxgiraphconfigactionv01/giraph-installer-v01.sh"
    
    $config = Add-AzHDInsightScriptAction `
        -Config $config `
        -Name "Install Giraph" `
        -NodeType HeadNode `
        -Uri $scriptActionUri
    
    
    $config = Add-AzHDInsightScriptAction `
        -Config $config `
        -Name "Install Giraph" `
        -NodeType WorkerNode `
        -Uri $scriptActionUri

    
    New-AzHDInsightCluster `
        -Config $config `
        -ResourceGroupName $resourceGroupName `
        -ClusterName $clusterName `
        -Location $location `
        -ClusterSizeInNodes $clusterSizeInNodes `
        -ClusterType $clusterType `
        -OSType $clusterOS `
        -Version $clusterVersion `
        -HttpCredential $httpCredential `
        -DefaultStorageAccountName "$defaultStorageAccountName.blob.core.windows.net" `
        -DefaultStorageAccountKey $defaultStorageAccountKey `
        -DefaultStorageContainer $containerName `
        -SshCredential $sshCredential
}

function use-scriptactionwithcluster {
        
    $ErrorActionPreference = "Stop"

    
    $context = Get-AzContext
    if ($context -eq $null) 
    {
        Connect-AzAccount
    }
    $context

    
    $clusterName = Read-Host -Prompt "Enter the name of the HDInsight cluster"
    $scriptActionName = Read-Host -Prompt "Enter the name of the script action"
    $scriptActionUri = Read-Host -Prompt "Enter the URI of the script action"
    
    $nodeTypes = "headnode", "workernode"

    
    Submit-AzHDInsightScriptAction -ClusterName $clusterName `
        -Name $scriptActionName `
        -Uri $scriptActionUri `
        -NodeTypes $nodeTypes `
        -PersistOnSuccess
}



function get-scriptactionhistory {
    
    Get-AzHDInsightScriptActionHistory -ClusterName mycluster

    
    Get-AzHDInsightScriptActionHistory -ClusterName mycluster `
        -ScriptExecutionId 635920937765978529

    
    
    
    Set-AzHDInsightPersistedScriptAction -ClusterName mycluster `
        -ScriptExecutionId 635920937765978529

    
    
    
    Remove-AzHDInsightPersistedScriptAction -ClusterName mycluster `
        -Name "Install Giraph"
}