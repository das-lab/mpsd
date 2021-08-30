




param(
    [string]$EditorServicesRepoPath = $null
)




$script:PackageJson = Get-Content -Raw $PSScriptRoot/package.json | ConvertFrom-Json
$script:IsPreviewExtension = $script:PackageJson.name -like "*preview*" -or $script:PackageJson.displayName -like "*preview*"
Write-Host "`n



task ResolveEditorServicesPath -Before CleanEditorServices, BuildEditorServices, TestEditorServices, Package {

    $script:psesRepoPath = `
        if ($EditorServicesRepoPath) {
            $EditorServicesRepoPath
        }
        else {
            "$PSScriptRoot/../PowerShellEditorServices/"
        }

    if (!(Test-Path $script:psesRepoPath)) {
        
        Write-Warning "`nThe PowerShellEditorServices repo cannot be found at path $script:psesRepoPath`n"
        $script:psesRepoPath = $null
    }
    else {
        $script:psesRepoPath = Resolve-Path $script:psesRepoPath
        $script:psesBuildScriptPath = Resolve-Path "$script:psesRepoPath/PowerShellEditorServices.build.ps1"
    }
}

task UploadArtifacts {
    if ($env:TF_BUILD) {
        
        Copy-Item -Path PowerShell-insiders.vsix `
            -Destination "$env:BUILD_ARTIFACTSTAGINGDIRECTORY/$($script:PackageJson.name)-$($script:PackageJson.version)-$env:SYSTEM_PHASENAME.vsix"
    }
}




task Restore RestoreNodeModules -If { -not (Test-Path "$PSScriptRoot/node_modules") }

task RestoreNodeModules {

    Write-Host "`n

    
    
    $logLevelParam = if ($env:TF_BUILD) { "--loglevel=error" } else { "" }
    exec { & npm install $logLevelParam }
}




task Clean {
    Write-Host "`n
    Remove-Item .\modules\* -Exclude "README.md" -Recurse -Force -ErrorAction Ignore
    Remove-Item .\out -Recurse -Force -ErrorAction Ignore
    Remove-Item -Force -Recurse node_modules -ErrorAction Ignore
}

task CleanEditorServices {
    if ($script:psesBuildScriptPath) {
        Write-Host "`n
        Invoke-Build Clean $script:psesBuildScriptPath
    }
}

task CleanAll CleanEditorServices, Clean




task Build Restore, {
    Write-Host "`n
    exec { & npm run compile }
}

task BuildEditorServices {
    
    if ($script:psesBuildScriptPath) {
        Write-Host "`n
        Invoke-Build Build $script:psesBuildScriptPath
    }
}

task BuildAll BuildEditorServices, Build




task Test Build, {
    if (!$global:IsLinux) {
        Write-Host "`n
        exec { & npm run test }
    }
    else {
        Write-Warning "Skipping extension tests on Linux platform because vscode does not support it."
    }
}

task TestEditorServices {
    if ($script:psesBuildScriptPath) {
        Write-Host "`n
        Invoke-Build Test $script:psesBuildScriptPath
    }
}

task TestAll TestEditorServices, Test





task UpdateReadme -If { $script:IsPreviewExtension } {
    
    $newReadmeTop = '

> 
> 
> 
    $readmePath = (Join-Path $PSScriptRoot README.md)

    $readmeContent = Get-Content -Path $readmePath
    if (!($readmeContent -match "This is the PREVIEW version of the PowerShell extension")) {
        $readmeContent[0] = $newReadmeTop
        $readmeContent | Set-Content $readmePath -Encoding utf8
    }
}

task UpdatePackageJson {
    if ($script:IsPreviewExtension) {
        $script:PackageJson.name = "powershell-preview"
        $script:PackageJson.displayName = "PowerShell Preview"
        $script:PackageJson.description = "(Preview) Develop PowerShell scripts in Visual Studio Code!"
        $script:PackageJson.preview = $true
    } else {
        $script:PackageJson.name = "powershell"
        $script:PackageJson.displayName = "PowerShell"
        $script:PackageJson.description = "Develop PowerShell scripts in Visual Studio Code!"
        $script:PackageJson.preview = $false
    }

    $currentVersion = [version](($script:PackageJson.version -split "-")[0])
    $currentDate = Get-Date

    $revision = if ($currentDate.Month -eq $currentVersion.Minor) {
        $currentVersion.Build + 1
    } else {
        0
    }

    $script:PackageJson.version = "$($currentDate.ToString('yyyy.M')).$revision"

    if ($env:TF_BUILD) {
        $script:PackageJson.version += "-CI.$env:BUILD_BUILDID"
    }

    $Utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines(
        (Resolve-Path "$PSScriptRoot/package.json").Path,
        ($script:PackageJson | ConvertTo-Json -Depth 100),
        $Utf8NoBomEncoding)
}

task Package UpdateReadme, {

    if ($script:psesBuildScriptPath) {
        Write-Host "`n
        Copy-Item -Recurse -Force ..\PowerShellEditorServices\module\* .\modules
    } elseif (Test-Path .\PowerShellEditorServices) {
        Write-Host "`n
        Move-Item -Force .\PowerShellEditorServices\* .\modules
        Remove-Item -Force .\PowerShellEditorServices
    } else {
        throw "Unable to find PowerShell EditorServices"
    }

    Write-Host "`n
    exec { & node ./node_modules/vsce/out/vsce package }

    
    Move-Item -Force .\$($script:PackageJson.name)-$($script:PackageJson.version).vsix .\PowerShell-insiders.vsix

    if ($env:TF_BUILD) {
        Copy-Item -Verbose -Recurse "./PowerShell-insiders.vsix" "$env:BUILD_ARTIFACTSTAGINGDIRECTORY/PowerShell-insiders.vsix"
        Copy-Item -Verbose -Recurse "./scripts/Install-VSCode.ps1" "$env:BUILD_ARTIFACTSTAGINGDIRECTORY/Install-VSCode.ps1"
    }
}




task Release Clean, Build, Package

task . CleanAll, BuildAll, Test, UpdatePackageJson, Package, UploadArtifacts
