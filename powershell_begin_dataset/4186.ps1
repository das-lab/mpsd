







Set-Variable -Name File -Scope Local -Force

Function DeclareGlobalMemory {

	Set-Variable -Name Files -Scope Global -Force
	Set-Variable -Name RelativePath -Scope Global -Force

}

Function GlobalMemoryCleanup {

	Remove-Variable -Name Files -Scope Global -Force
	Remove-Variable -Name RelativePath -Scope Global -Force

}

Function RenameWindow ($Title) {

	
	Set-Variable -Name a -Scope Local -Force
	
	$a = (Get-Host).UI.RawUI
	$a.WindowTitle = $Title
	
	
	Remove-Variable -Name a -Scope Local -Force
}

Function GetRelativePath {
	$Global:RelativePath=(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"
}

Function GetFiles {

	$Global:Files = Get-ChildItem -Path $Global:RelativePath

}

Function CreateTempFolder ($FolderName) {
	
	$FolderName = "c:\temp\"+$FolderName
	New-Item -Path $FolderName -ItemType Directory -Force
	
}

Function RemoveTempFolder ($FolderName) {
	
	$FolderName = "c:\temp\"+$FolderName
	Remove-Item -Path $FolderName -Recurse -Force
	
}

Function ExtractCAB ($Name) {

	
	Set-Variable -Name arguments -Scope Local -Force
	Set-Variable -Name Dest -Scope Local -Force
	Set-Variable -Name Source -Scope Local -Force
	
	$Source = $Global:RelativePath+$Name
	$Dest = "c:\temp\"+$Name.Substring(0,$Name.Length-4)
	$arguments = "–F:*"+[char]32+$Source+[char]32+$Dest
	Start-Process -FilePath "expand.exe" -ArgumentList $arguments -Wait -PassThru

	
	Remove-Variable -Name arguments -Scope Local -Force
	Remove-Variable -Name Dest -Scope Local -Force
	Remove-Variable -Name Source -Scope Local -Force
}
















Function ApplyWindowsUpdate ($Name) {

	
	Set-Variable -Name App -Scope Local -Force
	Set-Variable -Name arguments -Scope Local -Force
	Set-Variable -Name index -Scope Local -Force
	Set-Variable -Name Result -Scope Local -Force
	
	$App = $Name
	$index = $App.IndexOf("-KB")+1
	$App = $App.Substring(0,$App.Length-4)
	$App = $App.Substring($index)
	Write-Host "Installing"$App"....." -NoNewline
	$arguments = $Global:RelativePath+$Name+[char]32+"/quiet /norestart"
	$Result = (Start-Process -FilePath "wusa.exe" -ArgumentList $arguments -Wait -PassThru).ExitCode
	If ($Result -eq "3010") {
		Write-Host "Succeeded" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$Result -ForegroundColor Red
	}

	
	Remove-Variable -Name App -Scope Local -Force
	Remove-Variable -Name arguments -Scope Local -Force
	Remove-Variable -Name index -Scope Local -Force
	Remove-Variable -Name Result -Scope Local -Force

}

cls
RenameWindow "Windows Updates"
DeclareGlobalMemory
GetRelativePath
GetFiles
foreach ($File in $Files) {
	if (($File.Attributes -ne "Directory") -and ($File.Name -like "*.msu")) {
		ApplyWindowsUpdate $File.Name
	}
}
GlobalMemoryCleanup


Remove-Variable -Name File -Scope Local -Force
