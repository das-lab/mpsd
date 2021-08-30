


$Error.Clear()
$ErrorActionPreference = "SilentlyContinue"


$office_versions = @("15.0", 
				"14.0", 
				"11.0", 
				"10.0", 
				"9.0" 
				)


$user_SIDs = gwmi win32_userprofile | select sid


Foreach ($user_SID in $user_SIDs.sid){

	
	Foreach ($version in $office_versions){

		
		$key_base = "\HKEY_USERS\" + $user_SID + "\software\microsoft\office\" + $version +"\" 

		
		If (test-path -Path registry::$key_base) {

			
			$office_key_ring = Get-ChildItem -Path Registry::$key_base 

			
			ForEach ($office_key in $office_key_ring){
				$office_app_key = $office_key.name + "\user mru"

				
				if (test-path -Path Registry::$office_app_key) {

					
					Get-ChildItem -Path Registry::$office_app_key -Recurse; 
				}
			}
		}
	}
}

if ($Error) {
	
    Write-Error "Get-OfficeMRU Error on $env:COMPUTERNAME"
    Write-Error $Error
	$Error.Clear()
}
Write-Debug "Exiting $($MyInvocation.MyCommand)" 