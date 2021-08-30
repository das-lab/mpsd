
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$OutputFile = 'WindowsUpdatesReport.csv',
	[ValidateNotNullOrEmpty()][string]$ExclusionsFile = 'Exclusions.txt',
	[switch]$Email,
	[string]$From,
	[string]$To,
	[string]$SMTPServer,
	[string]$Subject = 'Windows Updates Build Report',
	[string]$Body = "List of windows updates installed during the build process"
)

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Remove-OutputFile {

	
	[CmdletBinding()]
	param ()
	
	
	$RelativePath = Get-RelativePath
	
	$File = $RelativePath + $OutputFile
	If ((Test-Path -Path $File) -eq $true) {
		Remove-Item -Path $File -Force
	}
}

function Get-Updates {

	
	[CmdletBinding()][OutputType([array])]
	param ()
	
	$UpdateArray = @()
	
	$RelativePath = Get-RelativePath
	
	$ExclusionsFile = $RelativePath + $ExclusionsFile
	
	$Exclusions = Get-Content -Path $ExclusionsFile
	
	$FileName = Get-ChildItem -Path $env:HOMEDRIVE"\minint" -filter ztiwindowsupdate.log -recurse
	
	$FileContent = Get-Content -Path $FileName.FullName | Where-Object { ($_ -like "*INSTALL*") } | Where-Object {$_ -notlike "*Windows Defender*"} | Where-Object {$_ -notlike "*Endpoint Protection*"} | Where-Object {$_ -notlike "*Windows Malicious Software Removal Tool*"} | Where-Object {$_ -notlike "*Dell*"} | Where-Object {$_ -notlike $Exclusions}
	
	$Updates = (($FileContent -replace (" - ", "~")).split("~") | where-object { ($_ -notlike "*LOG*INSTALL*") -and ($_ -notlike "*ZTIWindowsUpdate*") -and ($_ -notlike "*-*-*-*-*") })
	foreach ($Update in $Updates) {
		
		$Object = New-Object -TypeName System.Management.Automation.PSObject
		
		$Object | Add-Member -MemberType NoteProperty -Name KBArticle -Value ($Update.split("(")[1]).split(")")[0].Trim()
		
		$Description = $Update.split("(")[0]
		$Description = $Description -replace (",", " ")
		$Object | Add-Member -MemberType NoteProperty -Name Description -Value $Description
		
		$UpdateArray += $Object
	}
	If ($UpdateArray -ne $null) {
		$UpdateArray = $UpdateArray | Sort-Object -Property KBArticle
		
		$OutputFile = $RelativePath + $OutputFile
		$UpdateArray | Export-Csv -Path $OutputFile -NoTypeInformation -NoClobber
	}
	Return $UpdateArray
}

Clear-Host

Remove-OutputFile

Get-Updates
If ($Email.IsPresent) {
	$RelativePath = Get-RelativePath
	$Attachment = $RelativePath + $OutputFile
	
	Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Attachments $Attachment
}
