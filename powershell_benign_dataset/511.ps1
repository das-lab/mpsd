

function Get-ADPrincipalGroupMembershipRecurse{



	[CmdletBinding()]
	param(
        
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		$ADUser,

		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		$ADGroup,
        
        [Parameter(Mandatory=$false)]
        $Level = 0
    )
        
    
    
    
    Import-Module ActiveDirectory
  
    
    
    
    
    
    if($ADUser){
    
        
        $ADGroups = Get-ADPrincipalGroupMembership $ADUser | %{
            Get-ADPrincipalGroupMembershipRecurse -ADGroup $_ -Level ($Level+1)
        }
        
        
        $Levels = ($ADGroups | %{$_.Level} | measure -Maximum).Maximum + 1
        
        
        $ADGroups | %{
            
            
            $Item = New-Object –TypeName PSObject
            
            
            $Index = 1;while($Index -ne $Levels){
                
                
                if($_.Level -eq $Index){
                    $Item | Add-Member –MemberType NoteProperty –Name "Level $Index" –Value $_.Name   
                }else{
                    $Item | Add-Member –MemberType NoteProperty –Name "Level $Index" –Value ""
                }
            
                $Index += 1
            }
            
            
            $Item
        }
        
    
    }elseif($ADGroup){
    
        
        Write-Progress -Activity "Collecting Data" -Status "$($_.Name)" -PercentComplete (Get-Random -Minimum 1 -Maximum 100)
        
        
        $_ | select Name,@{L="Level";E={$Level}}
        
        
        Get-ADPrincipalGroupMembership $_ | %{
            Get-ADPrincipalGroupMembershipRecurse -ADGroup $_ -Level ($Level+1)
        }
    }
}