


try {
    $defaultParamValues = $PSdefaultParameterValues.Clone()
    $PSDefaultParameterValues["it:skip"] = ![System.Management.Automation.Platform]::IsWindowsDesktop

    Describe 'Basic COM Tests' -Tags "CI" {
        BeforeAll {
            $null = New-Item -Path $TESTDRIVE/file1 -ItemType File
            $null = New-Item -Path $TESTDRIVE/file2 -ItemType File
            $null = New-Item -Path $TESTDRIVE/file3 -ItemType File
        }

        It "Should enumerate files from a folder" {
            $shell = New-Object -ComObject "Shell.Application"
            $folder = $shell.Namespace("$TESTDRIVE")
            $items = $folder.Items()

            
            $items.Count | Should -Be 3
            $items | Measure-Object | ForEach-Object Count | Should -Be $items.Count

            $names = $items | ForEach-Object { $_.Name }
            $names -join "," | Should -Be "file1,file2,file3"
        }

        It "Should enumerate IEnumVariant interface object without exception" {
            $shell = New-Object -ComObject "Shell.Application"
            $folder = $shell.Namespace("$TESTDRIVE")
            $items = $folder.Items()

            
            $enumVariant = $items._NewEnum()
            $items.Count | Should -Be 3
            $enumVariant | Measure-Object | ForEach-Object Count | Should -Be $items.Count
        }

        It "Should enumerate drives" {
            $fileSystem = New-Object -ComObject scripting.filesystemobject
            $drives = $fileSystem.Drives

            
            $drives | Measure-Object | ForEach-Object Count | Should -Be $drives.Count
            
            
            $element = $drives | Select-Object -First 1
            [System.Object]::ReferenceEquals($element, $drives) | Should -BeFalse
            $element | Should -Be $drives.Item($element.DriveLetter)
        }

        It "ToString() should return method paramter names" {
            $shell = New-Object -ComObject "Shell.Application"
            $fullSignature = $shell.AddToRecent.ToString()

            $fullSignature | Should -BeExactly "void AddToRecent (Variant varFile, string bstrCategory)"
        }

    }

    Describe 'GetMember/SetMember/InvokeMember binders should have more restricted rule for COM object' -Tags "CI" {
        BeforeAll {
            if ([System.Management.Automation.Platform]::IsWindowsDesktop) {
                $null = New-Item -Path $TESTDRIVE/bar -ItemType Directory -Force

                $shell = New-Object -ComObject "Shell.Application"
                $folder = $shell.Namespace("$TESTDRIVE")
                $item = $folder.Items().Item(0)
                $item = [psobject]::AsPSObject($item)

                
                $str = Add-Member -InputObject "abc" -MemberType NoteProperty -Name Name -Value "Hello" -PassThru
                $str = Add-Member -InputObject $str -MemberType ScriptMethod -Name Windows -Value { "Windows" } -PassThru
            }
        }

        It "GetMember binder should differentiate PSObject that wraps COM object from other PSObjects" {
            
            $entry1 = ($item, "bar")
            $entry2 = ($str, "Hello")

            foreach ($pair in ($entry1, $entry2, $entry2, $entry1, $entry1, $entry2)) {
                $pair[0].Name | Should -Be $pair[1]
            }
        }

        It "SetMember binder should differentiate PSObject that wraps COM object from other PSObjects" {
            
            $entry1 = ($item, "foo")
            $entry2 = ($str, "World")

            foreach ($pair in ($entry1, $entry2)) {
                $pair[0].Name = $pair[1]
                $pair[0].Name | Should -Be $pair[1]
            }
        }

        It "InvokeMember binder should differentiate PSObject that wraps COM object from other PSObjects" {
            
            $shell | ForEach-Object { $_.Windows() } > $null

            
            $str.Windows() | Should -Be "Windows"
        }
    }

} finally {
    $global:PSdefaultParameterValues = $defaultParamValues
}
