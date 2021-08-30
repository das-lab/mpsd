function Get-NestedMember
{

    [CmdletBinding()]
    PARAM(
    [String[]]$GroupName,
    [String]$RelationShipPath,
    [Int]$MaxDepth
    )
    TRY{
        $FunctionName = (Get-Variable -Name MyInvocation -Scope 0 -ValueOnly).MyCommand

        Write-Verbose -Message "[$FunctionName] Check if ActiveDirectory Module is available"
        if(-not(Get-Module Activedirectory -ErrorAction Stop))
        {
            Write-Verbose -Message "[$FunctionName] Loading ActiveDirectory Module"
            Import-Module ActiveDirectory -ErrorAction Stop
        }

        
        $DepthCount = 1
        FOREACH ($Group in $GroupName)
        {
            Write-Verbose -Message "[$FunctionName] Group '$Group'"

            
            $GroupObject = Get-ADGroup -Identity $Group -ErrorAction Stop

            IF($GroupObject)
            {
                Write-Verbose -Message "[$FunctionName] Group '$Group' - Retrieving members"

                
                $GroupObject | Get-ADGroupMember -ErrorAction Stop | ForEach-Object -Process {

                    
                    $ParentGroup = $GroupObject.Name


                    
                    IF($RelationShipPath -notlike ".\ $($GroupObject.samaccountname) \*")
                    {
                        if($PSBoundParameters["RelationShipPath"]) {

                            $RelationShipPath = "$RelationShipPath \ $($GroupObject.samaccountname)"

                        }
                        Else{$RelationShipPath = ".\ $($GroupObject.samaccountname)"}

                        Write-Verbose -Message "[$FunctionName] Group '$Group' - Name:$($_.name) | ObjectClass:$($_.ObjectClass)"
                        $CurrentObject = $_
                        switch ($_.ObjectClass)
                        {
                            "group" {
                                
                                $CurrentObject | Select-Object Name,SamAccountName,ObjectClass,DistinguishedName,@{Label="ParentGroup";Expression={$ParentGroup}}, @{Label="RelationShipPath";Expression={$RelationShipPath}}

                                if (-not($DepthCount -lt $MaxDepth)){
                                    
                                    Get-NestedMember -GroupName $CurrentObject.Name -RelationShipPath $RelationShipPath
                                    $DepthCount++
                                }
                            }
                            default { $CurrentObject | Select-Object Name,SamAccountName,ObjectClass,DistinguishedName, @{Label="ParentGroup";Expression={$ParentGroup}},@{Label="RelationShipPath";Expression={$RelationShipPath}}}
                        }
                    }
                    ELSE {Write-Warning -Message "[$FunctionName] Circular group membership detected with $($GroupObject.samaccountname)"}
                }
            }
            ELSE {
                Write-Warning -Message "[$FunctionName] Can't find the group $Group"
            }
        }
    }
    CATCH{
        $PSCmdlet.ThrowTerminatingError($_)
    }
}