

function Report-FileSystemPermissions{



    param(
        [parameter(Mandatory=$true)]
        [String]$Path, 
        
        [parameter(Mandatory=$true)]
        [int]$Levels
    )



    
    
    

    $FileSystemPermissionReport = @()

    $FSfolders = Get-ChildItemRecurse -Path $Path -Levels $Levels -OnlyDirectories

    foreach ($FSfolder in $FSfolders)
    {

        Write-Progress -Activity "Anlayse access rights" -status $FSfolder.FullName -percentComplete ([int]([array]::IndexOf($FSfolders, $FSfolder)/$FSfolders.Count*100))
        
        
        $Acls = Get-Acl -Path $FSfolder.Fullname

        foreach($Acl in $Acls.Access){

            if($Acl.IsInherited -eq $false){
                
                $Member = $Acl.IdentityReference  -replace ".*?\\","" 
        
                $FileSystemPermissionReport += New-ObjectSPReportItem -Name $FSfolder.Name -Url $FSfolder.FullName -Member $Member -Permission $Acl.FileSystemRights   -Type "Directory"

            }else{
                break
            }
        }
    }

    return $FileSystemPermissionReport
    
}