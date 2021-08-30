
[CmdletBinding()]
param ()

cls

$LocalPassword = ((manage-bde -protectors -get ($env:ProgramFiles).split('\')[0] -id ((Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume').GetKeyProtectors(3).volumeKeyprotectorID)).trim() | Where-Object { $_.Trim() -ne '' })[-1]
$BitlockerID = (((manage-bde -protectors -get ($env:ProgramFiles).split('\')[0] -id ((Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume').GetKeyProtectors(3).volumeKeyprotectorID)).trim() | Where-Object { $_.Trim() -ne '' })[-3]).split(":")[1].trim()

$ADEntries = (Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase (Get-ADComputer $env:COMPUTERNAME).DistinguishedName -Properties 'msFVE-RecoveryPassword')

$EntryCount = 0

foreach ($Item in $ADEntries) {
	If ($LocalPassword -ne $Item.'msFVE-RecoveryPassword') {
		Remove-ADObject -Identity $Item.DistinguishedName -Confirm:$false
	} else {
		$EntryCount += 1
		If ($EntryCount -gt 1) {
			Remove-ADObject -Identity $Item.DistinguishedName -Confirm:$false
		}
	}
}
$ADEntries = (Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase (Get-ADComputer $env:COMPUTERNAME).DistinguishedName -Properties 'msFVE-RecoveryPassword')

If ($LocalPassword -notin $ADEntries.'msFVE-RecoveryPassword') {
	
	$Switches = "-protectors -adbackup c: -id" + [char]32 + $BitlockerID
	Write-Host "Backing up to AD....." -NoNewline
	$ErrCode = (Start-Process -FilePath $env:windir'\system32\manage-bde.exe' -ArgumentList $Switches -PassThru -Wait).ExitCode
	If ($ErrCode -eq 0) {
		Write-Host "Success" -ForegroundColor Yellow
		$ADEntries = (Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase (Get-ADComputer $env:COMPUTERNAME).DistinguishedName -Properties 'msFVE-RecoveryPassword')
		Write-Host
		Write-Host "  Bitlocker ID:" -NoNewline
		Write-Host $BitlockerID -ForegroundColor Yellow
		Write-Host "Local Password:" -NoNewline
		Write-Host $LocalPassword -ForegroundColor Yellow
		Write-Host "   AD Password:" -NoNewline
		Write-Host $ADEntries.'msFVE-RecoveryPassword' -ForegroundColor Yellow
		If ($LocalPassword -eq $ADEntries.'msFVE-RecoveryPassword') {
			Exit 0
		}
	} elseif ($ErrCode -eq "-2147024809") {
		$Status = [string]((manage-bde.exe -status).replace(' ', '')).split(":")[16]
		If ($Status -eq "FullyDecrypted") {
			Write-Host "Failed. System is not Bitlockered"
			Exit 2
		} else {
			Write-Host "Unspecified error"
			Exit 3
		}
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
		Write-Host
		Write-Host "  Bitlocker ID:" -NoNewline
		Write-Host $BitlockerID -ForegroundColor Yellow
		Write-Host "Local Password:" -NoNewline
		Write-Host $LocalPassword -ForegroundColor Yellow
		Write-Host "   AD Password:" -NoNewline
		Write-Host $ADEntries.'msFVE-RecoveryPassword' -ForegroundColor Yellow
		Exit 1
	}
} else {
	Write-Host
	Write-Host "  Bitlocker ID:"$BitlockerID
	Write-Host "Local Password:"$LocalPassword
	Write-Host "   AD Password:"$ADEntries.'msFVE-RecoveryPassword'
	Exit 0
}
