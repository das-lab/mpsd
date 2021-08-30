function Connect-SPOContext{

    

    param(
        [string]$Url
    )
    
    [Reflection.Assembly]::LoadFile((Get-ChildItem -Path $PSlib.Path -Filter "ClaimsAuth.dll" -Recurse).Fullname)
    $Global:SPOContext = New-Object SPOContext((Get-SPUrl $Url).Url)
    $Global:SPOContext
}

function Get-SPOWeb{

    $SPOWeb = $Global:SPOContext.Web
    $Global:SPOContext.Load($SPOWeb)
    $Global:SPOContext.ExecuteQuery()
    Return $SPOWeb
}



function Get-SPOList{

    param(
        $SPOContext,
        $ListName
    )

    $SPOWeb = Get-SPOWeb $SPOContext
    if($SPOWeb -ne $null){
        $SPOLists = $web.Lists
        $SPOContext.Load($SPOLists)
        $SPOLists.ExecuteQuery()
        $SPOList = $SPOLists | where {$_.Title -eq $ListName}
        return $SPOLists
    }
}