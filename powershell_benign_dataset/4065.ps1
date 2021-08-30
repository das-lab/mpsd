
[CmdletBinding()]
param
(
		[string]$Source = 't:\',
		[string]$Destination = 'x:\DCU',
		[string]$XMLFile
)

function Copy-Folder {

	
	[CmdletBinding()]
	param
	(
			[string]$SourceFolder,
			[string]$DestinationFolder,
			[ValidateSet($true, $false)][boolean]$Subfolders = $false,
			[ValidateSet($true, $false)][boolean]$Mirror = $false
	)
	
	$Executable = $env:windir + "\system32\Robocopy.exe"
	$Switches = $SourceFolder + [char]32 + $DestinationFolder + [char]32 + "/eta"
	If ($Subfolders -eq $true) {
		$Switches = $Switches + [char]32 + "/e"
	}
	If ($Mirror -eq $true) {
		$Switches = $Switches + [char]32 + "/mir"
	}
	Write-Host "Copying "$SourceFolder"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 1)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
	}
}

function Update-BIOS {

	
	[CmdletBinding()]
	param ()
	
	$Executable = $Destination + "\dcu-cli.exe"
	If ($XMLFile -eq "") {
		$Switches = " "
	} else {
		$XMLFile = $Destination + "\" + $XMLFile
		$Switches = "/policy" + [char]32 + $XMLFile
	}
	
	Write-Host "Updating BIOS....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If ($ErrCode -eq 0) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
	}
}


Copy-Folder -SourceFolder $Source -DestinationFolder $Destination -Subfolders $true -Mirror $true

Copy-Item -Path $Destination"\msi.dll" -Destination "x:\windows\system32" -Force

Update-BIOS
