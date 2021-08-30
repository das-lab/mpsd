Set-StrictMode -Version Latest

InModuleScope Pester {
    Describe "New-PesterState" {
        Context "TestNameFilter parameter is set" {
            $p = new-pesterstate -TestNameFilter "filter"

            it "sets the TestNameFilter property" {
                $p.TestNameFilter | should -be "filter"
            }

        }
        Context "TagFilter parameter is set" {
            $p = new-pesterstate -TagFilter "tag", "tag2"

            it "sets the TestNameFilter property" {
                $p.TagFilter | should -be ("tag", "tag2")
            }
        }

        Context "ExcludeTagFilter parameter is set" {
            $p = new-pesterstate -ExcludeTagFilter "tag3", "tag"

            it "sets the ExcludeTagFilter property" {
                $p.ExcludeTagFilter | should -be ("tag3", "tag")
            }
        }

        Context "TagFilter and ExcludeTagFilter parameter are set" {
            $p = new-pesterstate -TagFilter "tag", "tag2" -ExcludeTagFilter "tag3"

            it "sets the TestNameFilter property" {
                $p.TagFilter | should -be ("tag", "tag2")
            }

            it "sets the ExcludeTagFilter property" {
                $p.ExcludeTagFilter | should -be ("tag3")
            }
        }
        Context "TestNameFilter and TagFilter parameter is set" {
            $p = new-pesterstate -TagFilter "tag", "tag2" -testnamefilter "filter"

            it "sets the TagFilter property" {
                $p.TagFilter | should -be ("tag", "tag2")
            }

            it "sets the TestNameFilter property" {
                $p.TestNameFilter | should -be "Filter"
            }
        }

        Context "ScritpBlockFilter is set" {
            it "sets the ScriptBlockFilter property" {
                $o = New-PesterOption -ScriptBlockFilter @(@{Path = "C:\Tests"; Line = 293})
                $p = New-PesterState -PesterOption $o
                $p.ScriptBlockFilter | Should -Not -BeNullOrEmpty
                $p.ScriptBlockFilter[0].Path | Should -Be "C:\Tests"
                $p.ScriptBlockFilter[0].Line | Should -Be 293
            }
        }
    }

    Describe "Pester state object" {
        $p = New-PesterState

        Context "entering describe" {
            It "enters describe" {
                $p.EnterTestGroup("describeName", "describe")
                $p.CurrentTestGroup.Name | Should -Be "describeName"
                $p.CurrentTestGroup.Hint | Should -Be "describe"
            }
        }
        Context "leaving describe" {
            It "leaves describe" {
                $p.LeaveTestGroup("describeName", "describe")
                $p.CurrentTestGroup.Name | Should -Not -Be "describeName"
                $p.CurrentTestGroup.Hint | Should -Not -Be "describe"
            }
        }

        context "adding test result" {
            $p.EnterTestGroup('Describe', 'Describe')

            
            
            
            
            
            
            
            
            it "times test accurately within 10 milliseconds" {

                
                $p.EnterTest()

                
                $Time = Measure-Command -Expression {
                    Start-Sleep -Milliseconds 100
                }

                
                $p.LeaveTest()

                
                $p.AddTestResult("result", "Passed", $null)

                
                $result = $p.TestResult[-1]

                
                
                $result.time.TotalMilliseconds | Should -BeGreaterOrEqual ($Time.Milliseconds - 10)
                $result.time.TotalMilliseconds | Should -BeLessOrEqual ($Time.Milliseconds + 10)
            }

            
            

            
            

            
            

            
            

            
            

            
            

            
            

            
            

            
            

            
            
            

            
            

            
            
            
            
            

            it "accurately increments total testsuite time within 10 milliseconds" {
                
                $TotalTimeStart = $p.time;

                
                $p.EnterTestGroup('My Test Group', 'Script')

                
                $Time = Measure-Command -Expression {

                    
                    $p.EnterTestGroup('My Describe 1', 'Describe')

                    
                    Start-Sleep -Milliseconds 100

                    
                    $p.EnterTest()

                    
                    Start-Sleep -Milliseconds 100

                    
                    $p.LeaveTest()

                    
                    $p.AddTestResult("result", "Passed", $null)

                    
                    Start-Sleep -Milliseconds 100

                    
                    $p.LeaveTestGroup('My Describe 1', 'Describe')
                }

                
                $p.LeaveTestGroup('My Test Group', 'Script')

                
                
                $TimeRecorded = $p.time - $TotalTimeStart

                
                
                $TimeRecorded.Milliseconds | Should -BeGreaterOrEqual ($Time.Milliseconds - 10)
                $TimeRecorded.Milliseconds | Should -BeLessOrEqual ($Time.Milliseconds + 10)
            }

            

            it "adds passed test" {
                $p.AddTestResult("result", "Passed", 100)
                $result = $p.TestResult[-1]
                $result.Name | should -be "result"
                $result.passed | should -be $true
                $result.Result | Should -be "Passed"
                $result.time.ticks | should -be 100
            }
            it "adds failed test" {
                try {
                    throw 'message'
                }
                catch {
                    $e = $_
                }
                $p.AddTestResult("result", "Failed", 100, "fail", "stack", "suite name", @{param = 'eters'}, $e)
                $result = $p.TestResult[-1]
                $result.Name | should -be "result"
                $result.passed | should -be $false
                $result.Result | Should -be "Failed"
                $result.time.ticks | should -be 100
                $result.FailureMessage | should -be "fail"
                $result.StackTrace | should -be "stack"
                $result.ParameterizedSuiteName | should -be "suite name"
                $result.Parameters['param'] | should -be 'eters'
                $result.ErrorRecord.Exception.Message | should -be 'message'
            }

            it "adds skipped test" {
                $p.AddTestResult("result", "Skipped", 100)
                $result = $p.TestResult[-1]
                $result.Name | should -be "result"
                $result.passed | should -be $true
                $result.Result | Should -be "Skipped"
                $result.time.ticks | should -be 100
            }

            it "adds Pending test" {
                $p.AddTestResult("result", "Pending", 100)
                $result = $p.TestResult[-1]
                $result.Name | should -be "result"
                $result.passed | should -be $true
                $result.Result | Should -be "Pending"
                $result.time.ticks | should -be 100
            }

            $p.LeaveTestGroup('Describe', 'Describe')
        }

        Context "Path and TestNameFilter parameter is set" {
            $strict = New-PesterState -Strict

            It "Keeps Passed state" {
                $strict.AddTestResult("test", "Passed")
                $result = $strict.TestResult[-1]

                $result.passed | should -be $true
                $result.Result | Should -be "Passed"
            }

            It "Keeps Failed state" {
                $strict.AddTestResult("test", "Failed")
                $result = $strict.TestResult[-1]

                $result.passed | should -be $false
                $result.Result | Should -be "Failed"
            }

            It "Changes Pending state to Failed" {
                $strict.AddTestResult("test", "Pending")
                $result = $strict.TestResult[-1]

                $result.passed | should -be $false
                $result.Result | Should -be "Failed"
            }

            It "Changes Skipped state to Failed" {
                $strict.AddTestResult("test", "Skipped")
                $result = $strict.TestResult[-1]

                $result.passed | should -be $false
                $result.Result | Should -be "Failed"
            }

            It "Changes Inconclusive state to Failed" {
                $strict.AddTestResult("test", "Inconclusive")
                $result = $strict.TestResult[-1]

                $result.passed | should -be $false
                $result.Result | Should -be "Failed"
            }
        }

        Context 'Status counts in Strict mode' {
            It "increases Passed count" {
                $state = New-PesterState -Strict
                $state.AddTestResult("test", "Passed")

                $state.PassedCount | Should -Be 1
            }

            It "increases Failed count" {
                $state = New-PesterState -Strict
                $state.AddTestResult("test", "Failed")

                $state.FailedCount | Should -Be 1
            }

            It "increases Failed count instead of Pending" {
                $state = New-PesterState -Strict
                $state.AddTestResult("test", "Pending")

                $state.FailedCount | Should -Be 1
                $state.PendingCount | Should -Be 0
            }

            It "increases Failed count instead of Skipped" {
                $state = New-PesterState -Strict
                $state.AddTestResult("test", "Skipped")

                $state.FailedCount | Should -Be 1
                $state.SkippedCount | Should -Be 0
            }

            It "increases Failed count instead of Inconclusive" {
                $state = New-PesterState -Strict
                $state.AddTestResult("test", "Inconclusive")

                $state.FailedCount | Should -Be 1
                $state.InconclusiveCount | Should -Be 0
            }
        }
    }
}
