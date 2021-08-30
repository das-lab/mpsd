

function Get-ActiveDirectoryUserGroups{



    param(
        [parameter(Mandatory=$true)]
        [string[]]$Users
    )   

	
	
	
	Import-Module Quest.ActiveRoles.ArsPowerShellSnapIn
	
	
	
	
	function New-ObjectADUserGroup{
		param(
			$UserName,
			$UserDN,
			$UserSamAccountName,
			$GroupName,
			$GroupDN,
			$GroupSamAccountName
		)
		New-Object PSObject -Property @{
			UserName = $UserName
			UserDN = $UserDN
			UserSamAccountName = $UserSamAccountName
			GroupName = $GroupName
			GroupDN = $GroupDN
			GroupSamAccountName  = $GroupSamAccountName
		}
	}
	
	
	
	
	foreach($User in $Users){
	   
        
        $ADusers = Get-QADUser $User -Properties Name,DN,SamAccountName,MemberOf | Select-Object Name,DN,SamAccountName,MemberOf

        
        foreach($ADUser in $ADusers){
            
			
			$ADUserGroups = Get-QADMemberOf $ADUser.SamAccountName -Indirect
            			
            
			foreach($ADUserGroup in $ADUserGroups){ 
				
                Write-Progress -Activity "Collecting data" -status $ADUserGroup.Name -percentComplete ([int]([array]::IndexOf($ADUserGroups, $ADUserGroup)/$ADUserGroups.Count*100))

                New-ObjectADUserGroup -UserName $ADUser.Name -UserDN $ADUser.DN -UserSamAccountName $ADUser.SamAccountName -GroupName $ADUserGroup.Name -GroupDN $ADUserGroup.DN -GroupSamAccountName $ADUserGroup.SamAccountName
              
			} 
		}
	}    
}