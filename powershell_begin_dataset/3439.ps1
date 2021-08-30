
    
    
    
    
    
    
    
    
    
    


function Get-TestFolders([string] $srcPath, [string[]] $projectList) {
    
    $specialPaths = @{
        
        'Storage'           = 'Storage.Management.Test\ScenarioTests';
        
        
        'Accounts'           = 'Accounts.Test'
    }

    $resourceManagerPath = $srcPath
    $resourceManagerFolders = Get-ChildItem -Path $resourceManagerPath -ErrorAction Stop
    $testFolderPairs = New-Object System.Collections.ArrayList
    foreach ($folder in $resourceManagerFolders) {
        $folderName = $folder.Name
        if (-not ($projectList.Contains($folderName))) { 
            continue
        }

        $testFolderPathPrefix = "$resourceManagerPath\$folderName"
        $testFolderPathSuffix = "$folderName.Test\ScenarioTests"
        if ($specialPaths.ContainsKey($folderName)) {
            $testFolderPathSuffix = $specialPaths.Get_Item($folder.Name)
        }
        $testFolderPath = Join-Path $testFolderPathPrefix $testFolderPathSuffix

        if (Test-Path $testFolderPath) {
            $null = $testFolderPairs.Add(@{Name = $folder.Name; Path = $testFolderPath})
        } else {
            Write-Verbose "Folder '$testFolderPath' doesn't exist!"
        }
    }
    $testFolderPairs
}

function Filter-TestFiles([string] $path) { Get-ChildItem -Path $path -ErrorAction Stop | Where-Object {$_.Name -match "^(?!Run).*Tests\.ps1$"} }