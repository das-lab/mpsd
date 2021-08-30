


$Object = [pscustomobject]@{
    Number1 = '1'
    Number2 = '2'
}

$object.PSObject.TypeNames.Insert(0,'Number.Information')

$DefaultDisplaySet = 'Number1'

$DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$DefaultDisplaySet)

$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplayPropertySet)

$Object | Add-Member MemberSet PSStandardMembers $PSStandardMembers