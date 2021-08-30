function Get-PrivateData

{
    param
    (
        [System.Collections.Hashtable]
        $PrivateData
    )

    if($PrivateData.Keys.Count -eq 0)
    {
        $content = "
    PSData = @{

        
        

        
        

        
        

        
        

        
        

        
        

        
        

        
        

    } 

} 
        return $content
    }


    
    $Tags= $PrivateData["Tags"] -join "','" | Foreach-Object {"'$_'"}
    $LicenseUri = $PrivateData["LicenseUri"]| Foreach-Object {"'$_'"}
    $ProjectUri = $PrivateData["ProjectUri"] | Foreach-Object {"'$_'"}
    $IconUri = $PrivateData["IconUri"] | Foreach-Object {"'$_'"}
    $ReleaseNotesEscape = $PrivateData["ReleaseNotes"] -Replace "'","''"
    $ReleaseNotes = $ReleaseNotesEscape | Foreach-Object {"'$_'"}
    $Prerelease = $PrivateData[$script:Prerelease] | Foreach-Object {"'$_'"}
    $RequireLicenseAcceptance = $PrivateData["RequireLicenseAcceptance"]
    $ExternalModuleDependencies = $PrivateData["ExternalModuleDependencies"] -join "','" | Foreach-Object {"'$_'"}
    $DefaultProperties = @("Tags","LicenseUri","ProjectUri","IconUri","ReleaseNotes",$script:Prerelease,"ExternalModuleDependencies","RequireLicenseAcceptance")

    $ExtraProperties = @()
    foreach($key in $PrivateData.Keys)
    {
        if($DefaultProperties -notcontains $key)
        {
            $PropertyString = "
            $PropertyString += "`r`n    "
            if(($PrivateData[$key]).GetType().IsArray)
            {
                $PropertyString += $key +" = " +" @("
                $PrivateData[$key] | Foreach-Object { $PropertyString += "'" + $_ +"'" + "," }
                if($PrivateData[$key].Length -ge 1)
                {
                    
                    $PropertyString = $PropertyString -Replace ".$"
                }
                $PropertyString += ")"
            }
            else
            {
                $PropertyString += $key +" = " + "'"+$PrivateData[$key]+"'"
            }

            $ExtraProperties += ,$PropertyString
        }
    }

    $ExtraPropertiesString = ""
    $firstProperty = $true
    foreach($property in $ExtraProperties)
    {
        if($firstProperty)
        {
            $firstProperty = $false
        }
        else
        {
            $ExtraPropertiesString += "`r`n`r`n    "
        }
        $ExtraPropertiesString += $Property
    }

    $TagsLine ="
    if($Tags -ne "''")
    {
        $TagsLine = "Tags = "+$Tags
    }
    $LicenseUriLine = "
    if($LicenseUri -ne "''")
    {
        $LicenseUriLine = "LicenseUri = "+$LicenseUri
    }
    $ProjectUriLine = "
    if($ProjectUri -ne "''")
    {
        $ProjectUriLine = "ProjectUri = " +$ProjectUri
    }
    $IconUriLine = "
    if($IconUri -ne "''")
    {
        $IconUriLine = "IconUri = " +$IconUri
    }
    $ReleaseNotesLine = "
    if($ReleaseNotes -ne "''")
    {
        $ReleaseNotesLine = "ReleaseNotes = "+$ReleaseNotes
    }
    $PrereleaseLine = "
    if ($Prerelease -ne "''")
    {
        $PrereleaseLine = "Prerelease = " +$Prerelease
    }

    $RequireLicenseAcceptanceLine = "
    if($RequireLicenseAcceptance)
    {
        $RequireLicenseAcceptanceLine = "RequireLicenseAcceptance = `$true"
    }

    $ExternalModuleDependenciesLine ="
    if($ExternalModuleDependencies -ne "''")
    {
        $ExternalModuleDependenciesLine = "ExternalModuleDependencies = @($ExternalModuleDependencies)"
    }

    if(-not $ExtraPropertiesString -eq "")
    {
        $Content = "
    ExtraProperties

    PSData = @{

        
        $TagsLine

        
        $LicenseUriLine

        
        $ProjectUriLine

        
        $IconUriLine

        
        $ReleaseNotesLine

        
        $PrereleaseLine

        
        $RequireLicenseAcceptanceLine

        
        $ExternalModuleDependenciesLine

    } 

} 

        
        $Content -replace "ExtraProperties", $ExtraPropertiesString
    }
    else
    {
        $content = "
    PSData = @{

        
        $TagsLine

        
        $LicenseUriLine

        
        $ProjectUriLine

        
        $IconUriLine

        
        $ReleaseNotesLine

        
        $PrereleaseLine

        
        $RequireLicenseAcceptanceLine

        
        $ExternalModuleDependenciesLine

    } 

 } 
        return $content
    }
}