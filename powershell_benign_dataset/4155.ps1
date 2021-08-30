
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]
	$FilesFolders
)

function Grant-FolderOwnership {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$FileFolder,
		[switch]
		$Recurse
	)
	
	$Errors = $false
	If ((Test-Path $FileFolder) -eq $true) {
		$Output = "Taking ownership of " + $FileFolder + "....."
		If ($Recurse.IsPresent) {
			
			$Items = takeown.exe /F $FileFolder
			
			$Items = Get-ChildItem $FileFolder -Recurse | ForEach-Object { takeown.exe /F $_.FullName }
		} else {
			
			$Executable = takeown.exe /F $FileFolder
		}
	}
	
	[string]$CurrentUser = [Environment]::UserDomainName + "\" + [Environment]::UserName
	If ($Recurse.IsPresent) {
		
		$Item = Get-Item $FileFolder | where-object { (get-acl $_.FullName).owner -ne $CurrentUser }
		$Items = Get-ChildItem $FileFolder -Recurse | where-object { (get-acl $_.FullName).owner -ne $CurrentUser }
		
		If ((($Item -ne "") -and ($Item -ne $null)) -and (($Items -ne "") -and ($Items -ne $null))) {
			$Output += "Failed"
		} else {
			$Output += "Success"
		}
	} else {
		[string]$FolderOwner = (get-acl $FileFolder).owner
		If ($CurrentUser -ne $FolderOwner) {
			$Output += "Failed"
			$Errors = $true
		} else {
			$Output += "Success"
		}
	}
	Write-ToDisplay -Output $Output
	If ($Errors -eq $true) {
		
		Exit 5
	}
}

function Write-ToDisplay {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Output
	)
	
	$OutputSplit = (($Output.Replace(".", " ")).Replace("     ", ".")).Split(".")
	Write-Host $OutputSplit[0]"....." -NoNewline
	If ($OutputSplit[1] -like "*Success*") {
		Write-Host $OutputSplit[1] -ForegroundColor Yellow
	} elseif ($OutputSplit[1] -like "*Fail*") {
		Write-Host $OutputSplit[1] -ForegroundColor Red
	}
}

Grant-FolderOwnership -FileFolder $FilesFolders
