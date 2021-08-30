


function Get-RsCatalogItemRole
{
    

    [CmdletBinding()]
    param
    (
        [string]
        $Identity,

        [string]
        $Path = "/",

        [switch]
        $Recurse,

        [string]
        $ReportServerUri,

        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy
    )

    Begin
    {

        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

    }

    Process
    {

        $inheritParent = $true
        $catalogItemRoles = @()

        
        $parentPolicy = $Proxy.GetPolicies($Path, [ref]$inheritParent)

        
        if($Identity) {
            $parentPolicy = $parentPolicy | Where-Object { $_.GroupUserName -eq $Identity }
        }

        $parentType = $Proxy.GetItemType($Path)

        $catalogItemRoles += New-RsCatalogItemRoleObject -Policy $parentPolicy -Path $Path -TypeName $parentType -ParentSecurity $inheritParent


        if($Recurse -and $parentType -eq "Folder") {

            $GetRsFolderContentParam = @{
                Proxy = $Proxy
                RsFolder = $Path
                Recurse = $Recurse
                ErrorAction = 'Stop'
            }

            try
            {
                $items = Get-RsFolderContent @GetRsFolderContentParam
            }
            catch
            {
                throw (New-Object System.Exception("Failed to retrieve items in '$RsFolder': $($_.Exception.Message)", $_.Exception))
            }

            foreach($item in $items)
            {
                $childPolicies = $Proxy.GetPolicies($item.path, [ref]$inheritParent)

                
                if($Identity) {
                    $childPolicies = $childPolicies | Where-Object { $_.GroupUserName -eq $Identity }
                }

                foreach($childPolicy in $childPolicies)
                {
                    $catalogItemRoles +=  New-RsCatalogItemRoleObject -Policy $childPolicy -Path $item.Path -TypeName $item.TypeName -ParentSecurity $inheritParent
                }


            }
        }

        return $catalogItemRoles
    }
}
