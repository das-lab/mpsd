function Complete
{
	[CmdletBinding()]
	param (
		[string]
		$Expression
	)
	process
	{
		[System.Management.Automation.CommandCompletion]::CompleteInput(
			$Expression,
			$Expression.Length,
			$null
		).CompletionMatches
	}
}

Describe 'Completion tests: input' {
	It 'can complete input from Get-ChildItem' {
		Complete 'Get-ChildItem | Select-PSFObject ' | Should -All { $_.CompletionText -match '^Attributes$|^BaseName$|^CreationTime$|^CreationTimeUtc$|^Directory$|^DirectoryName$|^Exists$|^Extension$|^FullName$|^IsReadOnly$|^LastAccessTime$|^LastAccessTimeUtc$|^LastWriteTime$|^LastWriteTimeUtc$|^Length$|^Name$|^Parent$|^PSChildName$|^PSDrive$|^PSIsContainer$|^PSParentPath$|^PSPath$|^PSProvider$|^Root$|^VersionInfo$' }
		(Complete 'Get-ChildItem | Select-PSFObject ').Count | Should -Be 25
	}
	
	
}