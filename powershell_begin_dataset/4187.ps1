






Clear-Host


$app = ,@()
Set-Variable -Name Count -Scope Global -Value 1 -Force
Set-Variable -Name OS -Scope Global -Force
Set-Variable -Name RelativePath -Scope Global -Force

Function RenameWindow ($Title) {

	
	Set-Variable -Name a -Scope Local -Force
	
	$a = (Get-Host).UI.RawUI
	$a.WindowTitle = $Title
	
	
	Remove-Variable -Name a -Scope Local -Force
}

Function AppInstalled($Description) {

	
	Set-Variable -Name AppName -Scope Local -Force
	Set-Variable -Name AppLocal -Scope Local -Force
	Set-Variable -Name Desc -Scope Local -Force
	Set-Variable -Name Output -Scope Local -Force
	
	$object = New-Object -TypeName PSObject
	
	$Desc = [char]34+"description like"+[char]32+[char]39+[char]37+$Description+[char]37+[char]39+[char]34
	$Output = wmic product where $Desc get Description
	$Output | ForEach-Object {
		$_ = $_.Trim()
    		if(($_ -ne "Description")-and($_ -ne "")){
     	   	$AppName = $_
    		}
	}
	$AppLocal = New-Object System.Object
	$AppLocal | Add-Member -type NoteProperty -name Application -value $Description
	If ($AppName -ne $null) {
		
		$AppLocal | Add-Member -type NoteProperty -name Status -value "Installed"
		
	} else {
		
		$AppLocal | Add-Member -type NoteProperty -name Status -value "Not Installed"
	}
	$Global:app += $AppLocal
	$AppLocal | Select Application
	$Global:Count++

	
	Remove-Variable -Name AppName -Scope Local -Force
	Remove-Variable -Name AppLocal -Scope Local -Force
	Remove-Variable -Name Desc -Scope Local -Force
	Remove-Variable -Name Output -Scope Local -Force
	
}

cls
Write-Host "Processing Applications"
Write-Host
RenameWindow "Check Build Installs"
AppInstalled "Dell Client System Update"
AppInstalled "Adobe Reader"
AppInstalled "Microsoft Lync"
AppInstalled "Remote Desktop"
AppInstalled "Interactive Admin"
AppInstalled "RunAs Admin"
AppInstalled "Windows Backup"
cls
Write-Host "Installation Report"
Write-Host
$app | Format-Table


$app.Clear()
Remove-Variable -Name Count -Scope Global -Force
Remove-Variable -Name OS -Scope Global -Force
Remove-Variable -Name RelativePath -Scope Global -Force
