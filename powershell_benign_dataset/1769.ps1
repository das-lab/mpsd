












Import-Module HelpersSecurity

try
{
    $defaultParamValues = $PSDefaultParameterValues.Clone()
    $PSDefaultParameterValues["it:Skip"] = !$IsWindows

    Describe "Local script debugger is disabled in system lock down mode" -Tags 'CI','RequireAdminOnWindows' {

        BeforeAll {

            
            $debuggerTestTypeDef = @'
            using System;
            using System.Management.Automation;
            using System.Management.Automation.Runspaces;

            namespace TestRunner
            {
                public class DebuggerTester
                {
                    private Runspace _runspace;

                    public int DebuggerStopHitCount
                    {
                        private set;
                        get;
                    }

                    public DebuggerTester(Runspace runspace)
                    {
                        if (runspace.Debugger == null)
                        {
                            throw new PSArgumentException("The provided runspace script debugger cannot be null for test.");
                        }

                        _runspace = runspace;
                        _runspace.Debugger.DebuggerStop += (sender, args) =>
                        {
                            DebuggerStopHitCount += 1;
                        };
                    }
                }
            }
'@

            $script = @'
            "Hello"
            Wait-Debugger
            "Goodbye"
'@
            $scriptFilePath = Join-Path $TestDrive TScript.ps1
            $script > $scriptFilePath

            
            Add-Type -TypeDefinition $debuggerTestTypeDef

            
            $TestCasesDisableDebugger = @(
                @{
                    testName = 'Verifies that Set-PSBreakpoint Line is disabled on locked down system'
                    scriptText = 'Set-PSBreakpoint -Script {0} -Line 1' -f $scriptFilePath
                },
                @{
                    testName = 'Verifies that Set-PSBreakpoint Statement is disabled on locked down system'
                    scriptText = 'Set-PSBreakpoint -Script {0} -Line 1 -Column 1' -f $scriptFilePath
                },
                @{
                    testName = 'Verifies that Set-PSBreakpoint Command is disabled on locked down system'
                    scriptText = 'Set-PSBreakpoint -Command {0}' -f $scriptFilePath
                },
                @{
                    testName = 'Verifies that Set-PSBreakpoint Variable is disabled on locked down system'
                    scriptText = 'Set-PSBreakpoint -Variable HelloVar'
                }
            )
        }

        AfterAll {

            if (($script:moduleDirectory -ne $null) -and (Test-Path $script:moduleDirectory))
            {
                try { Remove-Item -Path $moduleDirectory -Recurse -Force -ErrorAction SilentlyContinue } catch { }
            }
        }

        It "<testName>" -TestCases $TestCasesDisableDebugger {

            param ($scriptText)

            try 
            {
                Invoke-LanguageModeTestingSupportCmdlet -SetLockdownMode

                
                [powershell] $ps = [powershell]::Create([System.Management.Automation.RunspaceMode]::NewRunspace);
                $ps.AddScript($scriptText).Invoke()
                $expectedError = $ps.Streams.Error[0]
            }
            finally
            {
                Invoke-LanguageModeTestingSupportCmdlet -RevertLockdownMode -EnableFullLanguageMode
                if ($ps -ne $null) { $ps.Dispose() }
            }

            $expectedError.FullyQualifiedErrorId | Should Be 'NotSupported,Microsoft.PowerShell.Commands.SetPSBreakpointCommand'
        }

        It "Verifies that Wait-Debugger is disabled on locked down system" {

            try
            {
                Invoke-LanguageModeTestingSupportCmdlet -SetLockdownMode

                
                [runspace] $runspace = [runspacefactory]::CreateRunspace()
                $runspace.Open()

                
                $debuggerTester = [TestRunner.DebuggerTester]::new($runspace)

                
                [powershell] $ps = [powershell]::Create()
                $ps.Runspace = $runspace
                $null = $ps.AddScript('"Hello"; Wait-Debugger; "Goodbye"').Invoke()
            }
            finally
            {
                Invoke-LanguageModeTestingSupportCmdlet -RevertLockdownMode -EnableFullLanguageMode
                if ($runspace -ne $null) { $runspace.Dispose() }
                if ($ps -ne $null) { $ps.Dispose() }
            }

            
            $debuggerTester.DebuggerStopHitCount | Should Be 0
        }
    }
}
finally
{
    if ($null -ne $defaultParamValues)
    {
        $Global:PSDefaultParameterValues = $defaultParamValues
    }
}
