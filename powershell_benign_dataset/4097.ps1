
[CmdletBinding()]
param ()

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

Function Install-Fonts {
      	
	
	Param ([String]$SourceDirectory,
		[String]$FontType)
	
	$FontType = "*." + $FontType
	$sa = new-object -comobject shell.application
	$Fonts = $sa.NameSpace(0x14)
	$Files = Get-ChildItem $SourceDirectory -Filter $FontType
	For ($i = 0; $i -lt $Files.Count; $i++) {
		$FontName = $Files[$i].Name.ToString().Trim()
		Write-Host "Installing"$FontName"....." -NoNewline
		$File = $Env:windir + "\Fonts\" + $Files[$i].Name
		If ((Test-Path $File) -eq $false) {
			$Fonts.CopyHere($Files[$i].FullName)
			If ((Test-Path $File) -eq $true) {
				Write-Host "Installed" -ForegroundColor Yellow
			} else {
				Write-Host "Failed" -ForegroundColor Red
				Exit 1
			}
		} else {
			Write-Host "Already Installed" -ForegroundColor Yellow
		}
	}
}

Clear-Host
$RelativePath = Get-RelativePath
$Success = Install-Fonts -SourceDirectory $RelativePath -FontType "ttf"
