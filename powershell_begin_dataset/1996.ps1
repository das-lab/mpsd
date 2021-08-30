

Describe "Tab completion bug fix" -Tags "CI" {

    It "Issue
        $result = TabExpansion2 -inputScript "[system.manage" -cursorColumn "[system.manage".Length
        $result.CompletionMatches | Should -HaveCount 1
        $result.CompletionMatches[0].CompletionText | Should -BeExactly "System.Management"
    }

    It "Issue
        $result = TabExpansion2 -inputScript "1 -sp" -cursorColumn "1 -sp".Length
        $result.CompletionMatches | Should -HaveCount 1
        $result.CompletionMatches[0].CompletionText | Should -BeExactly "-split"
    }

    It "Issue
        $result = TabExpansion2 -inputScript "1 -a" -cursorColumn "1 -a".Length
        $result.CompletionMatches | Should -HaveCount 2
        $result.CompletionMatches[0].CompletionText | Should -BeExactly "-and"
        $result.CompletionMatches[1].CompletionText | Should -BeExactly "-as"
    }
    It "Issue
        $result = TabExpansion2 -inputScript "[pscu" -cursorColumn "[pscu".Length
        $result.CompletionMatches | Should -HaveCount 1
        $result.CompletionMatches[0].CompletionText | Should -BeExactly "pscustomobject"
    }
    It "Issue
        $cmd = "Import-Module -n"
        $result = TabExpansion2 -inputScript $cmd -cursorColumn $cmd.Length
        $result.CompletionMatches | Should -HaveCount 3
        $result.CompletionMatches[0].CompletionText | Should -BeExactly "-Name"
        $result.CompletionMatches[1].CompletionText | Should -BeExactly "-NoClobber"
        $result.CompletionMatches[2].CompletionText | Should -BeExactly "-NoOverwrite"
    }

    Context "Issue
        BeforeAll {
            $DatetimeProperties = @((Get-Date).psobject.baseobject.psobject.properties) | Sort-Object -Property Name
        }
        It "Issue
            $cmd = "Get-Date | Select-Object -ExcludeProperty "
            $result = TabExpansion2 -inputScript $cmd -cursorColumn $cmd.Length
            $result.CompletionMatches | Should -HaveCount $DatetimeProperties.Count
            $result.CompletionMatches[0].CompletionText | Should -BeExactly $DatetimeProperties[0].Name 
            $result.CompletionMatches[1].CompletionText | Should -BeExactly $DatetimeProperties[1].Name 
       }
       It "Issue
           $cmd = "Get-Date | Select-Object -ExpandProperty "
           $result = TabExpansion2 -inputScript $cmd -cursorColumn $cmd.Length
           $result.CompletionMatches | Should -HaveCount $DatetimeProperties.Count
           $result.CompletionMatches[0].CompletionText | Should -BeExactly $DatetimeProperties[0].Name 
           $result.CompletionMatches[1].CompletionText | Should -BeExactly $DatetimeProperties[1].Name 
       }
    }

    It "Issue
        $cmd = "Get-Date | Sort-Object @{"
        $result = TabExpansion2 -inputScript $cmd -cursorColumn $cmd.Length
        $result.CompletionMatches | Should -HaveCount 3
        $result.CompletionMatches[0].CompletionText | Should -BeExactly 'Expression'
        $result.CompletionMatches[1].CompletionText | Should -BeExactly 'Ascending'
        $result.CompletionMatches[2].CompletionText | Should -BeExactly 'Descending'
    }

    It "'Get-Date | Sort-Object @{Expression=<tab>' should work without completion" {
        $cmd = "Get-Date | Sort-Object @{Expression="
        $result = TabExpansion2 -inputScript $cmd -cursorColumn $cmd.Length
        $result.CompletionMatches | Should -HaveCount 0
    }

    It "Issue
        $cmd = "Get-Date | Sort-Object @{Expression=...;"
        $result = TabExpansion2 -inputScript $cmd -cursorColumn $cmd.Length
        $result.CurrentMatchIndex | Should -Be -1
        $result.ReplacementIndex | Should -Be 40
        $result.ReplacementLength | Should -Be 0
        $result.CompletionMatches[0].CompletionText | Should -BeExactly 'Expression'
        $result.CompletionMatches[1].CompletionText | Should -BeExactly 'Ascending'
        $result.CompletionMatches[2].CompletionText | Should -BeExactly 'Descending'
    }
}
