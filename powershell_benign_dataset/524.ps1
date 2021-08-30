

function Get-SPObjectPermissions{



	param(
		[Parameter(Mandatory=$false)]
		[string]$Identity,
		
		[switch]$IncludeChildItems,

		[switch]$Recursive,
        
        [switch]$OnlyLists,
        
        [switch]$OnlyWebsites,
        
        [switch]$ByUsers
	)
    
    
    
    
    if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
    Import-Module ActiveDirectory

    
    
    
    function Get-SPObjectPermissionMemberType{
    
        param(
            [Parameter(Mandatory=$true)]
            $RoleAssignment
        )
        
        
        if($RoleAssignment.Member.IsDomainGroup){
            $MemberType = "ADGroup"                        
        }elseif(($RoleAssignment.Member.LoginName).StartsWith("SHAREPOINT\")){
            $MemberType = "SPUser"  
        }elseif($RoleAssignment.Member.UserToken -ne $null){
            $MemberType = "ADUser"                                          
        }else{
            $MemberType = "SPGroup"
        }
        
        $MemberType
    }


    function Get-SPObjectPermissionMember{
    
        param(
            [Parameter(Mandatory=$true)]
            $RoleAssignment
        )
        
        $Member =  $RoleAssignment.Member.UserLogin -replace ".*\\",""
        if($Member -eq ""){
            $Member =  $RoleAssignment.Member.LoginName
        }
        
        $Member
    }
    
    
    function Get-SPReportItemByUsers{
    
        param(
            [Parameter(Mandatory=$true)]
            $SPReportItem
        )
        
        if($SPReportItem.MemberType -eq "ADGroup"){
            $ADUsers = Get-ADGroupMember -Identity $SPReportItem.Member -Recursive | Get-ADUser -Properties DisplayName | where{$_.Enabled}
                
        }elseif($SPPermission.MemberType -eq "ADUser"){
            $ADUsers = Get-ADUser -Identity $SPReportItem.Member | where{$_.Enabled}
            
        }else{
            $ADUsers = $Null
        }
            
        if($ADUsers){
            foreach($ADUser in $ADUsers){
                
                
                $SPReportItemByUsers = $SPReportItem.PsObject.Copy()
            
                $SPReportItemByUsers | Add-Member -MemberType NoteProperty -Name "UserName" -Value $ADUser.Name -Force
                $SPReportItemByUsers | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $ADUser.DisplayName -Force
                $SPReportItemByUsers | Add-Member -MemberType NoteProperty -Name "UserPrincipalName" -Value $ADUser.UserPrincipalName -Force
                
                $SPReportItemByUsers
            }
        }
        
    }
    
    function New-ObjectSPReportItem{
        param(
            $Name,
            $Url,
            $Member,
            $MemberType,
            $Permission,
            $Type
        )
        New-Object PSObject -Property @{
            Name = $Name
            Url = $Url
            Member = $Member
            MemberType = $MemberType
            Permission = $Permission
            Type = $Type
        }
    }

    
    
    
    
    
    $SPWebs = @()
    
    
    if($Identity){
    
        
        $SPUrl = (Get-SPUrl $Identity).Url
        
        $SPWeb = Get-SPWeb $SPUrl
        
        if($IncludeChildItems -and -not $Recursive){
        
            $SPWebs += $SPWeb
            $SPWebs += $SPWeb.webs            
        
        }elseif($Recursive -and -not $IncludeChildItems){
        
            $SPWebs += $SPWeb.Site.AllWebs | where{$_.Url.Startswith($SPWeb.Url)}
            
        }else{
        
            $SPWebs += $SPWeb
        }  
              
     }else{
    
        $SPWebs += Get-SPsite -Limit All | Get-SPWeb -Limit All -ErrorAction SilentlyContinue

    }
           
    
    foreach ($SPWeb in $SPWebs){

        Write-Progress -Activity "Read permissions" -status $SPWeb -percentComplete ([int]([array]::IndexOf($SPWebs, $SPWeb)/$SPWebs.Count*100))
            
        if(($SPWeb.permissions -ne $null) -and  ($SPWeb.HasUniqueRoleAssignments) -and -not $OnlyLists){  
                
            foreach ($RoleAssignment in $SPWeb.RoleAssignments){
            
                
                $Member = Get-SPObjectPermissionMember -RoleAssignment $RoleAssignment
                $MemberType = Get-SPObjectPermissionMemberType -RoleAssignment $RoleAssignment

                
                $Permission = $RoleAssignment.roledefinitionbindings[0].Name
                
                
                $SPReportItem = New-ObjectSPReportItem -Name $SPWeb.Title -Url $SPWeb.url -Member $Member -MemberType $MemberType -Permission $Permission -Type "Website" 
                
                
                if($ByUsers){Get-SPReportItemByUsers -SPReportItem $SPReportItem}else{$SPReportItem}            
            }        
        }
        
        
        if(-not $OnlyWebsites){  
                      
            foreach ($SPlist in $SPWeb.lists){
                
                if (($SPlist.permissions -ne $null) -and ($SPlist.HasUniqueRoleAssignments)){  
                      
                    foreach ($RoleAssignment in $SPlist.RoleAssignments){
                    
                        
                        [Uri]$SPWebUrl = $SPWeb.url
                        $SPListUrl = $SPWebUrl.Scheme + "://" + $SPWebUrl.Host + $SPlist.DefaultViewUrl -replace "/([^/]*)\.(aspx)",""
                                                    
                        
                        $Member = Get-SPObjectPermissionMember -RoleAssignment $RoleAssignment
                        $MemberType = Get-SPObjectPermissionMemberType -RoleAssignment $RoleAssignment
                                               
                        
                        $Permission = $RoleAssignment.roledefinitionbindings[0].Name   
                                                 
                        
                        $SPReportItem = New-ObjectSPReportItem -Name ($SPWeb.Title + " - " + $SPlist.Title) -Url $SPListUrl -Member $Member -MemberType $MemberType -Permission $Permission -Type "List"
                        
                        
                        if($ByUsers){Get-SPReportItemByUsers -SPReportItem $SPReportItem}else{$SPReportItem}  
                    }
                }
            }
        }                
    }
}