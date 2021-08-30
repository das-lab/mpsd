

Describe "Additional static method tests" -Tags "CI" {

    Context "Basic static member methods" {
        BeforeAll {
            function Get-Name { "YES" }
        }

        It "test basic static constructor" {
            class Foo {
                static [string] $Name
                static Foo() { [Foo]::Name = Get-Name }
            }

            [Foo]::Name | Should -Be "Yes"
        }

        It "test basic static method" {
            class Foo {
                static [string] GetName() { return (Get-Name) }
            }

            [Foo]::GetName() | Should -Be "Yes"
        }
    }

    Context "Class defined in different Runspace" {
        BeforeAll {
@'
class Foo
{
    static [string] $Name
    static Foo() { [Foo]::Name = Get-Name }
    
    static [string] GetName()
    {
        return (Get-AnotherName)
    }
}
'@ | Set-Content -Path $TestDrive\class.ps1 -Force

            
            function Get-Name { "Default Runspace - Name" }
            function Get-AnotherName { "Default Runspace - AnotherName" }

            
            $ps1 = [powershell]::Create()
            
            $ps2 = [powershell]::Create()

            function RunScriptInPS {
                param(
                    [powershell] $PowerShell,
                    [string] $Script,
                    [switch] $IgnoreResult
                )
                $result = $PowerShell.AddScript($Script).Invoke()
                $PowerShell.Commands.Clear()

                if (-not $IgnoreResult) {
                    return $result
                }
            }

            
            RunScriptInPS -PowerShell $ps1 -Script "function Get-Name { 'PS1 Runspace - Name' }" -IgnoreResult
            RunScriptInPS -PowerShell $ps1 -Script "function Get-AnotherName { 'PS1 Runspace - AnotherName' }" -IgnoreResult

            
            . $TestDrive\class.ps1
            
            RunScriptInPS -PowerShell $ps1 -Script ". $TestDrive\class.ps1" -IgnoreResult
        }

        AfterAll {
            
            $ps1.Dispose()
            $ps2.Dispose()
        }

        It "Static constructor should run in the triggering Runspace if the class has been defined in that Runspace" {
            
            
            
            
            [Foo]::Name | Should -BeExactly "Default Runspace - Name"

            
            
            RunScriptInPS -PowerShell $ps1 -Script "[Foo]::Name" | Should -BeExactly "Default Runspace - Name"
        }

        It "Static method use the Runspace where the call happens if the class has been defined in that Runspace" {

            
            
            [Foo]::GetName() | Should -BeExactly "Default Runspace - AnotherName"

            
            
            RunScriptInPS -PowerShell $ps1 -Script "[Foo]::GetName()" | Should -BeExactly 'PS1 Runspace - AnotherName'
        }

        It "Static method use the default SessionState if it's called in a Runspace where the class is not defined" {

            
            RunScriptInPS -PowerShell $ps2 -Script "function Get-Name { 'PS2 Runspace - Name' }" -IgnoreResult
            RunScriptInPS -PowerShell $ps2 -Script "function Get-AnotherName { 'PS2 Runspace - AnotherName' }" -IgnoreResult
            
            
            RunScriptInPS -PowerShell $ps2 -Script 'function Call-GetName([type] $type) { $type::GetName() }' -IgnoreResult

            
            
            
            
            $result = $ps2.AddCommand("Call-GetName").AddParameter("type", [Foo]).Invoke()
            $result | Should -BeExactly 'PS1 Runspace - AnotherName'
        }
    }
}
