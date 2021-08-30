param(
    [switch]$SkipCabs,
    [switch]$ShowProgress
)


$global:ProgressPreference = 'SilentlyContinue'
if ($ShowProgress) { $ProgressPreference = 'Continue' }

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$tempDir = [System.IO.Path]::GetTempPath()


$panDocVersion = "2.7.3"
$pandocSourceURL = "https://github.com/jgm/pandoc/releases/download/$panDocVersion/pandoc-$panDocVersion-windows-x86_64.zip"

$pandocDestinationPath = New-Item (Join-Path $tempDir "pandoc") -ItemType Directory -Force
$pandocZipPath = Join-Path $pandocDestinationPath "pandoc-$panDocVersion-windows-x86_64.zip"
Invoke-WebRequest -Uri $pandocSourceURL -OutFile $pandocZipPath

Expand-Archive -Path $pandocZipPath -DestinationPath $pandocDestinationPath -Force
$pandocExePath = Join-Path (Join-Path $pandocDestinationPath "pandoc-$panDocVersion-windows-x86_64") "pandoc.exe"


$threadJob = Get-Module ThreadJob -ListAvailable
if ($null -eq $threadjob) {
    Install-Module ThreadJob -RequiredVersion 1.1.2 -Scope CurrentUser -Force
}


$ReferenceDocset = Join-Path $PSScriptRoot 'reference'


$jobs = [System.Collections.Generic.List[object]]::new()
$excludeList = 'module', 'media', 'docs-conceptual', 'mapping', 'bread', '7'
Get-ChildItem $ReferenceDocset -Directory -Exclude $excludeList | ForEach-Object -Process {
    $job = Start-ThreadJob -Name $_.Name -ArgumentList @($SkipCabs,$pandocExePath,$PSScriptRoot,$_) -ScriptBlock {
        param($SkipCabs, $pandocExePath, $WorkingDirectory, $DocSet)

        $tempDir = [System.IO.Path]::GetTempPath()
        $workingDir = Join-Path $tempDir $DocSet.Name
        $workingDir = New-Item -ItemType Directory -Path $workingDir -Force
        Set-Location $WorkingDir

        function Get-ContentWithoutHeader {
            param(
                $path
            )

            $doc = Get-Content $path -Encoding UTF8
            $start = $end = -1

            
            

            for ($x = 0; $x -lt 30; $x++) {
                if ($doc[$x] -eq '---') {
                    if ($start -eq -1) {
                        $start = $x
                    }
                    else {
                        if ($end -eq -1) {
                            $end = $x + 1
                            break
                        }
                    }
                }
            }
            if ($end -gt $start) {
                Write-Output ($doc[$end..$($doc.count)] -join "`r`n")
            }
            else {
                Write-Output ($doc -join "`r`n")
            }
        }

        $Version = $DocSet.Name
        Write-Verbose -Verbose "Version = $Version"

        $VersionFolder = $DocSet.FullName
        Write-Verbose -Verbose "VersionFolder = $VersionFolder"

        
        Get-ChildItem $VersionFolder -Directory | ForEach-Object -Process {
            $ModuleName = $_.Name
            Write-Verbose -Verbose "ModuleName = $ModuleName"

            $ModulePath = Join-Path $VersionFolder $ModuleName
            Write-Verbose -Verbose "ModulePath = $ModulePath"

            $LandingPage = Join-Path $ModulePath "$ModuleName.md"
            Write-Verbose -Verbose "LandingPage = $LandingPage"

            $MamlOutputFolder = Join-Path "$WorkingDirectory\maml" "$Version\$ModuleName"
            Write-Verbose -Verbose "MamlOutputFolder = $MamlOutputFolder"

            $CabOutputFolder = Join-Path "$WorkingDirectory\updatablehelp" "$Version\$ModuleName"
            Write-Verbose -Verbose "CabOutputFolder = $CabOutputFolder"

            if (-not (Test-Path $MamlOutputFolder)) {
                New-Item $MamlOutputFolder -ItemType Directory -Force > $null
            }

            
            $AboutFolder = Join-Path $ModulePath "About"

            if (Test-Path $AboutFolder) {
                Write-Verbose -Verbose "AboutFolder = $AboutFolder"
                Get-ChildItem "$aboutfolder/about_*.md" | ForEach-Object {
                    $aboutFileFullName = $_.FullName
                    $aboutFileOutputName = "$($_.BaseName).help.txt"
                    $aboutFileOutputFullName = Join-Path $MamlOutputFolder $aboutFileOutputName

                    $pandocArgs = @(
                        "--from=gfm",
                        "--to=plain+multiline_tables",
                        "--columns=75",
                        "--output=$aboutFileOutputFullName",
                        "--quiet"
                    )

                    Get-ContentWithoutHeader $aboutFileFullName | & $pandocExePath $pandocArgs
                }
            }

            try {
                
                
                New-ExternalHelp -Path $ModulePath -OutputPath $MamlOutputFolder -Force -WarningAction Stop -ErrorAction Stop

                
                if (-not $SkipCabs) {
                    $cabInfo = New-ExternalHelpCab -CabFilesFolder $MamlOutputFolder -LandingPagePath $LandingPage -OutputFolder $CabOutputFolder

                    
                    if ($cabInfo.Count -eq 8) { $cabInfo[-1].FullName }
                }
            }
            catch {
                Write-Error -Message "PlatyPS failure: $ModuleName -- $Version" -Exception $_
            }
        }

        Remove-Item $workingDir -Force -ErrorAction SilentlyContinue
    }
    Write-Verbose -Verbose "Started job for $($_.Name)"
    $jobs += $job
}

$null = $jobs | Wait-Job


$allErrors = [System.Collections.Generic.List[string]]::new()
foreach ($job in $jobs) {
    Write-Verbose -Verbose "$($job.Name) output:"
    if ($job.Verbose.Count -gt 0) {
        foreach ($verboseMessage in $job.Verbose) {
            Write-Verbose -Verbose $verboseMessage
        }
    }

    if ($job.State -eq "Failed") {
        $allErrors += "$($job.Name) failed due to unhandled exception"
    }

    if ($job.Error.Count -gt 0) {
        $allErrors += "$($job.Name) failed with errors:"
        $allErrors += $job.Error.ReadAll()
    }
}


if ($allErrors.Count -gt 0) {
    $allErrors
    throw "There are errors during platyPS run!`nPlease fix your markdown to comply with the schema: https://github.com/PowerShell/platyPS/blob/master/platyPS.schema.md"
}
