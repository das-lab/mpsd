

function Disable-UserAccessControl{



	[CmdletBinding()]
	param(
        
	)
    
	
	
	
	
	Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
	if(Get-ItemProperty -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system" -Name "EnableLUA"  -ErrorAction SilentlyContinue){
		Set-ItemProperty "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system" -Name "EnableLUA" -Value 00000000
    }
	Write-Host "User Access Control (UAC) has been disabled. Reboot required."
}