









































function Get-ResourceGroupName
{
    return "azurermsfrg";
}

function Get-ClusterName
{
    return "azurermsfclustertest";
}

function Get-NodeTypeName
{
    return "nt1vm";
}

function Get-KeyVaultName
{
    return "azurermsfkvtest";
}

function Get-NewCertName
{
    return "AzureRMSFTestCert2"
}

function Get-SecretUrl
{
    
    return "https://azurermsfkvtest.vault.azure.net:443/secrets/AzureRMSFTestCert2/6e96bff504d54f36916489281423b8c6"
}

function Get-Thumbprint
{
    
    return "910AC565E683987971F34531A824284E3B936040"
}

function Get-CertAppSecretUrl
{
    
    return "https://azurermsfkvtest.vault.azure.net:443/secrets/AzureRMSFTestCertApp/ca4c0f7efa254d9ba0b267b8aaebb878"
}

function Get-CertAppThumbprint
{
    
    return "EE28AF31B2741B52311A00F78DFF4F46240BB4F8"
}

function Get-CACertCommonName
{
	return "azurermsfcntest.southcentralus.cloudapp.azure.com"
}

function Get-CACertIssuerThumbprint
{
	return "417e225037fbfaa4f95761d5ae729e1aea7e3a42,d4de20d05e66fc53fe1a50882c78db2852cae474"
}

function Get-CACertSecretUrl
{
	return "https://azurermsfkvtest.vault.azure.net:443/secrets/azurermsfcntest/0cd47f8218aa40e3a47e0597b8017247"
}

function Get-CertWUSecretUrl
{
	return "https://azurermsfkvtestwu.vault.azure.net/secrets/AzureRMSFTestCertWU/5250a7acbaa143fa9d493840d4de1c01"
}

function Get-DurabilityLevel
{
	return "Silver"
}

function Get-ReliabilityLevel
{
	return "Bronze"
}

function Get-NewNodeTypeName
{
	return 'nt2vm'
}

function Get-SectionName
{
	return 'NamingService'
}

function Get-ParameterName
{
	return 'MaxFileOperationTimeout'
}

function Get-ValueName
{
	return '5000'
}

function Get-RandomPwd
{
    $length = 10
    $allowedCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
    $allowedDigits = "0123456789".ToCharArray()
    $allowedSpecial = "!@
    $myRandomString = -join (Get-Random -Count $length -InputObject $allowedCharacters)
    $myRandomString += Get-Random -Count 1 -InputObject $allowedDigits
    $myRandomString += Get-Random -Count 1 -InputObject $allowedSpecial
    return  "$myRandomString"
}

function WaitForClusterReadyStateIfRecord($clusterName, $resourceGroupName)
{
	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
	{
		
		if (-not (WaitForClusterReadyState $clusterName $resourceGroupName))
		{
			Assert-True $false 'Cluster is not in Ready state. Can not continue with test.'
		}
	}
}

function WaitForClusterReadyState($clusterName, $resourceGroupName, $timeoutInSeconds = 1200)
{
    $timeoutTime = (Get-Date).AddSeconds($timeoutInSeconds)
    while (-not $clusterReady -and (Get-Date) -lt $timeoutTime) {
        $cluster = (Get-AzServiceFabricCluster -ResourceGroupName $resourceGroupName -Name $clusterName)[0]
        if ($cluster.ClusterState -eq "Ready")
        {
            return $true
            break
        }

        Write-Host "Cluster state: $($cluster.ClusterState). Waiting for Ready state before continuing."
        Start-Sleep -Seconds 15
    }

    Write-Error "WaitForClusterReadyState timed out"
    return $false
}



function Get-AppTypeName
{
    return "CalcServiceApp"
}

function Get-AppTypeV1Name
{
    return "1.0"
}

function Get-AppTypeV2Name
{
    return "1.1"
}

function Get-AppPackageV1
{
    return "https://azsfapptest.blob.core.windows.net/azsfapptest/CalcApp_1.0.sfpkg"
}

function Get-AppPackageV2
{
    return "https://azsfapptest.blob.core.windows.net/azsfapptest/CalcApp_1.1.sfpkg"
}

function Get-ServiceTypeName
{
    return "CalcServiceType"
}