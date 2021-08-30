Function Get-SCSMUserManager
{
    Param (
        $input_affectedUser_id
    )

    
    $managerOfAffectedUser_obj = $null

    
    $affectedUser_obj = get-scsmobject -id $input_affectedUser_id
    $userManagesUser_relclass_id = '4a807c65-6a1f-15b2-bdf3-e967e58c254a'
    $managerOfAffectedUser_relobjs = Get-SCSMRelationshipObject -ByTarget $affectedUser_obj | Where-Object{ $_.relationshipId -eq $userManagesUser_relclass_id }

    
    
    

    If ($managerOfAffectedUser_relobjs -ne $null)
    {
        ForEach ($managerOfAffectedUser_relobj in $managerOfAffectedUser_relobjs)
        {
            If ($managerOfAffectedUser_relobj.IsDeleted -eq $True)
            {
                
                
            }
            Else
            {
                
                $managerOfAffectedUser_id = $managerofaffecteduser_relobj.SourceObject.Id.Guid
                $managerOfAffectedUser_obj = get-scsmobject -id $managerofaffecteduser_id
            }
        }
    }
    Else
    {
        
        $managerOfAffectedUser_obj = $null
    }
    $managerOfAffectedUser_obj
}