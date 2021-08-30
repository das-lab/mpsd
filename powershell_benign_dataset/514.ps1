

function Set-SPADGroupPermission{



	param(
		[Parameter(Mandatory=$true)]
		$Identity,
		
		[Parameter(Mandatory=$true)]
		[string]$ADGroup,

		[Parameter(Mandatory=$true)]
		[string]$Role,
        
        [Parameter(Mandatory=$false)]
		[string[]]$Exclude,
        
        [switch]$Recursive,
        
        [switch]$IncludeLists,
        
        [switch]$Overwrite
	)

	
	
	
	if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
    Import-Module ActiveDirectory

	
	
	
 
	
    $SPWeb = Get-SPweb $(Get-SPUrl $Identity).Url
    
    
    $SPSite =  $SPWeb.Site
    
    
	$SPRootWeb = $SPSite.RootWeb
    
	
	$SPRole = $SPWeb.RoleDefinitions | where{$_.Name -eq $Role -or $_.ID -eq $Role}
    
    
    $ADGroup = "$((Get-ADDomain).Name)" + "`\" + $(Get-ADGroup $ADGroup).Name
    
	
    $SPGroup = $SPRootWeb.EnsureUser($ADGroup)
    
    
    if($SPGroup -eq $Null){throw "Group not found!"}
    
	$SPRoleAssignment = new-object Microsoft.SharePoint.SPRoleAssignment($SPGroup)
	$SPRoleAssignment.RoleDefinitionBindings.Add($SPRole)
    
    $("Grant $($SPRole.Name) access for $ADGroup on $($SPWeb.Title) with options:$(if($Recursive){" Recursive"})$(if($IncludeLists){" IncludeLists"})$(if($Overwrite){" Overwrite"})")
    
	
	if($Recursive){
    
        $SPWebs = Get-SPWebs $SPWeb | where{$Exclude -notcontains $_.Url} 
        
        
        foreach($SPWeb in $SPWebs){
        
            Write-Progress -Activity "Update role assignment for $ADGroup" -status $SPWeb.title -percentComplete ([int]([array]::IndexOf(([array]$SPWebs), $SPWeb)/([array]$SPWebs).count*100))
        
            if($SPWeb.HasUniqueRoleAssignments){
                if($OverWrite){
                    $SPweb.RoleAssignments.Remove($SPGroup)
                }
    			$SPWeb.RoleAssignments.Add($SPRoleAssignment)
    		}
            
            
            if($IncludeLists){
                
                
                $SPLists = Get-SPLists $SPWeb
                
                foreach($SPList in $SPLists){
                    if($SPList.HasUniqueRoleAssignments){ 
                        if($OverWrite){
                            $SPList.RoleAssignments.Remove($SPGroup)
                        }   			
        				$SPList.RoleAssignments.Add($SPRoleAssignment)
        			}                                     
                }            
            }        
        }       
    }else{
     
        
        if($SPWebsite.HasUniqueRoleAssignments){
            if($OverWrite){
                $SPweb.RoleAssignments.Remove($SPGroup)
            }
			$SPWebsite.RoleAssignments.Add($SPRoleAssignment)
		}
            
        
        if($IncludeLists){
            
            
            $SPLists = Get-SPLists $SPWebsite
            
            foreach($SPList in $SPLists){
                if($SPList.HasUniqueRoleAssignments){ 
                    if($OverWrite){
                        $SPList.RoleAssignments.Remove($SPGroup)
                    }   			
    				$SPList.RoleAssignments.Add($SPRoleAssignment)
    			}                                     
            }            
        }
    }
}