function New-ClusterWithConfig {
    
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
    
    $sshCredentials = Get-Credential -Message "Enter SSH user credentials"

    
    $clusterSizeInNodes = "4"
    $clusterVersion = "3.6"
    $clusterType = "Hadoop"
    $clusterOS = "Linux"
    
    $defaultBlobContainerName = $clusterName

    
    New-AzStorageContainer `
        -Name $clusterName -Context $defaultStorageContext


    $additionalStorageAccountName = Read-Host -Prompt "Enter the name of the additional storage account"

    
    New-AzStorageAccount -ResourceGroupName $resourceGroupName `
        -StorageAccountName $additionalStorageAccountName `
        -Location $location `
        -Type Standard_LRS
    
    
    $additionalStorageAccountKey = (Get-AzStorageAccountKey -Name $additionalStorageAccountName -ResourceGroupName $resourceGroupName)[0].Value

    
    
    
    $config = New-AzHDInsightClusterConfig `
        -ClusterType "RServer" `
        -EdgeNodeSize "Standard_D12_v2"

    
    $rserverConfig = @{"rstudio"="true"}
    $config = $config | Add-AzHDInsightConfigValues `
        -RServer $rserverConfig `
        -Spark2Defaults $spark2Config

    
    Add-AzHDInsightStorage -Config $config -StorageAccountName "$additionalStorageAccountName.blob.core.windows.net" -StorageAccountKey $additionalStorageAccountKey

    
    New-AzHDInsightCluster `
        -ClusterName $clusterName `
        -ResourceGroupName $resourceGroupName `
        -HttpCredential $httpCredential `
        -Location $location `
        -DefaultStorageAccountName "$defaultStorageAccountName.blob.core.windows.net" `
        -DefaultStorageAccountKey $defaultStorageAccountKey `
        -DefaultStorageContainer $defaultStorageContainerName  `
        -ClusterSizeInNodes $clusterSizeInNodes `
        -OSType $clusterOS `
        -Version $clusterVersion `
        -SshCredential $sshCredentials `
        -Config $config

}
