


param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$sourceFolder
)


$savedProgressPreference = $global:ProgressPreference
$global:ProgressPreference = 'SilentlyContinue'

$tempDir = [System.IO.Path]::GetTempPath()


$panDocVersion = "2.7.3"
$pandocSourceURL = "https://github.com/jgm/pandoc/releases/download/$panDocVersion/pandoc-$panDocVersion-windows-x86_64.zip"

$docToolsPath = New-Item (Join-Path $tempDir "doctools") -ItemType Directory -Force
$pandocZipPath = Join-Path $docToolsPath "pandoc-$panDocVersion-windows-x86_64.zip"
Write-Verbose "Downloading Pandoc..."
Invoke-WebRequest -Uri $pandocSourceURL -OutFile $pandocZipPath

Expand-Archive -Path $pandocZipPath -DestinationPath $docToolsPath -Force
$pandocExePath = Join-Path $docToolsPath "pandoc-$panDocVersion-windows-x86_64\pandoc.exe"

$platyPSversion = "0.14.0"
Write-Verbose "Downloading platyPS..."
Save-Module -Name platyPS -Repository PSGallery -Force -Path $docToolsPath -RequiredVersion $platyPSversion
Import-Module -FullyQualifiedName $docToolsPath\platyPS\$platyPSversion\platyPS.psd1

$DocSet = Get-Item $sourceFolder
$WorkingDirectory = $PWD

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
        Write-Output ($doc[$end..$($doc.count)] -join ([Environment]::Newline))
    }
    else {
        Write-Output ($doc -join "`r`n")
    }
}

$Version = $DocSet.Name
Write-Verbose "Version = $Version"

$VersionFolder = $DocSet.FullName
Write-Verbose "VersionFolder = $VersionFolder"


Get-ChildItem $VersionFolder -Directory | ForEach-Object -Process {
    $ModuleName = $_.Name
    Write-Verbose "ModuleName = $ModuleName"

    $ModulePath = Join-Path $VersionFolder $ModuleName
    Write-Verbose "ModulePath = $ModulePath"

    $LandingPage = Join-Path $ModulePath "$ModuleName.md"
    Write-Verbose "LandingPage = $LandingPage"

    $MamlOutputFolder = Join-Path "$WorkingDirectory\maml" "$Version\$ModuleName"
    Write-Verbose "MamlOutputFolder = $MamlOutputFolder"

    $CabOutputFolder = Join-Path "$WorkingDirectory\updatablehelp" "$Version\$ModuleName"
    Write-Verbose "CabOutputFolder = $CabOutputFolder"

    if (-not (Test-Path $MamlOutputFolder)) {
        New-Item $MamlOutputFolder -ItemType Directory -Force > $null
    }

    
    $AboutFolder = Join-Path $ModulePath "About"

    if (Test-Path $AboutFolder) {
        Write-Verbose "AboutFolder = $AboutFolder"
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

        
        $cabInfo = New-ExternalHelpCab -CabFilesFolder $MamlOutputFolder -LandingPagePath $LandingPage -OutputFolder $CabOutputFolder

        
        if ($cabInfo.Count -eq 8) { $cabInfo[-1].FullName }
    }
    catch {
        Write-Error -Message "PlatyPS failure: $ModuleName -- $Version" -Exception $_
    }
}

$global:ProgressPreference = $savedProgressPreference