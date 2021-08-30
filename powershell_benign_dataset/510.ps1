

function Sync-ADGroupMember{



	[CmdletBinding()]
	param(
    
		[Parameter(Mandatory=$true)]
		$ADGroup,
        
        [Parameter(Mandatory=$true)]
        [Array]
		$Member,
        
        [Parameter(Mandatory=$false)]
        [ScriptBlock]
		$LogScriptBlock,
        
        [switch]
        $OnlyAdd,
        
        [switch]
        $OnlyRemove
        
	)
    
    
	
	
    Import-Module activedirectory
    
 	
	
	
    $ADGroup | %{
    
        if($_.PsObject.TypeNames -notcontains "Microsoft.ActiveDirectory.Management.ADGroup"){
            $ADGroupItem = Get-ADGroup $_
        }else{
            $ADGroupItem = $_
        }
        
        if($Member[0].PsObject.TypeNames -notcontains "Microsoft.ActiveDirectory.Management.ADObject"){
            $Member = $($Member | %{
                Get-ADObject -Filter 'Name -eq $_' | 
                select -First 1 | %{
                    if($_.ObjectClass -eq "user"){
                        Get-ADUser $_.DistinguishedName
                    }elseif($_.ObjectClass -eq "group"){
                        Get-ADGroup $_.DistinguishedName
                    }
                }
            })
        }

        $IsMember = $(Get-ADGroupMember $ADGroupItem)
        if($IsMember){
            Compare-Object -ReferenceObject $IsMember -DifferenceObject $Member -Property Name, DistinguishedName | %{
            
                if($_.SideIndicator -eq "<=" -and -not $OnlyAdd){
                    
                    $Message = "Remove ADGroupMember: $($_.Name) from ADGroup: $($ADGroupItem.Name)"
                    Invoke-Command -ScriptBlock $LogScriptBlock
                    Remove-ADGroupMember -Identity $ADGroupItem -Members $_.DistinguishedName -Confirm:$false
                
                }elseif($_.SideIndicator -eq "=>" -and -not $OnlyRemove){
                
                    $Message = "Add ADGroupMember: $($_.Name) to ADGroup: $($ADGroupItem.Name)"
                    Invoke-Command -ScriptBlock $LogScriptBlock
                    Add-ADGroupMember -Identity $ADGroupItem -Members $_.DistinguishedName -Confirm:$false
                }
            }
        }elseif($Member){
            $Member | %{
            
                $Message = "Add ADGroupMember: $($_.Name) to ADGroup: $($ADGroupItem.Name)"
                Invoke-Command -ScriptBlock $LogScriptBlock
                Add-ADGroupMember -Identity $ADGroupItem -Members $_  -Confirm:$false
            }
        }       
    }
}