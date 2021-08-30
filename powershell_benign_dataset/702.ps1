


function New-RscatalogItemRoleObject
{
    

    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$True)]
        [Object[]] $Policy,

        [Parameter(Mandatory=$True)]
        [String]$Path,

        [Parameter(Mandatory=$True)]
        [String]$TypeName,

        [Parameter(Mandatory=$True)]
        [Boolean]$ParentSecurity
    )
    $catalogItemRoles = @()

    $Policy | ForEach-Object {
    
        $catalogItemRole = New-Object -TypeName PSCustomObject
        $catalogItemRole | Add-Member -MemberType NoteProperty -Name Identity -Value $_.GroupUserName
        $catalogItemRole | Add-Member -MemberType NoteProperty -Name Path -Value $Path
        $catalogItemRole | Add-Member -MemberType NoteProperty -Name TypeName -Value $TypeName
        $catalogItemRole | Add-Member -MemberType NoteProperty -Name Roles -Value $_.Roles
        $catalogItemRole | Add-Member -MemberType NoteProperty -Name ParentSecurity -Value $ParentSecurity

        $catalogItemRoles += $catalogItemRole
    }

    return $catalogItemRoles
}
