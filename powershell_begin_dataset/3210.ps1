















[CmdletBinding()]
param(
    [switch]$Install,

    [ValidateSet("Debug", "Release")]
    [string]$Configuration = (property Configuration Release),

    [ValidateSet("net461", "netcoreapp2.1")]
    [string]$Framework
)

Import-Module "$PSScriptRoot/tools/helper.psm1"


$targetDir = "bin/$Configuration/PSReadLine"

if (-not $Framework)
{
    $Framework = if ($PSVersionTable.PSEdition -eq "Core") { "netcoreapp2.1" } else { "net461" }
}

Write-Verbose "Building for '$Framework'" -Verbose

function ConvertTo-CRLF([string] $text) {
    $text.Replace("`r`n","`n").Replace("`n","`r`n")
}

$buildMamlParams = @{
    Inputs  = { Get-ChildItem docs/*.md }
    Outputs = "$targetDir/en-US/Microsoft.PowerShell.PSReadLine2.dll-help.xml"
}


task BuildMamlHelp @buildMamlParams {
    platyPS\New-ExternalHelp docs -Force -OutputPath $targetDir/en-US/Microsoft.PowerShell.PSReadLine2.dll-help.xml
}

$buildAboutTopicParams = @{
    Inputs = {
         Get-ChildItem docs/about_PSReadLine.help.txt
         "PSReadLine/bin/$Configuration/$Framework/Microsoft.PowerShell.PSReadLine2.dll"
         "$PSScriptRoot/tools/GenerateFunctionHelp.ps1"
         "$PSScriptRoot/tools/CheckHelp.ps1"
    }
    Outputs = "$targetDir/en-US/about_PSReadLine.help.txt"
}


task BuildAboutTopic @buildAboutTopicParams {
    
    
    $psExePath = Get-PSExePath

    $generatedFunctionHelpFile = New-TemporaryFile
    & $psExePath -NoProfile -NonInteractive -File $PSScriptRoot/tools/GenerateFunctionHelp.ps1 $Configuration $generatedFunctionHelpFile.FullName
    assert ($LASTEXITCODE -eq 0) "Generating function help failed"

    $functionDescriptions = Get-Content -Raw $generatedFunctionHelpFile
    $aboutTopic = Get-Content -Raw $PSScriptRoot/docs/about_PSReadLine.help.txt
    $newAboutTopic = $aboutTopic -replace '{{FUNCTION_DESCRIPTIONS}}', $functionDescriptions
    $newAboutTopic = $newAboutTopic -replace "`r`n","`n"
    $newAboutTopic | Out-File -FilePath $targetDir\en-US\about_PSReadLine.help.txt -NoNewline -Encoding ascii

    & $psExePath -NoProfile -NonInteractive -File $PSScriptRoot/tools/CheckHelp.ps1 $Configuration
    assert ($LASTEXITCODE -eq 0) "Checking help and function signatures failed"
}

$binaryModuleParams = @{
    Inputs  = { Get-ChildItem PSReadLine/*.cs, PSReadLine/PSReadLine.csproj, PSReadLine/PSReadLineResources.resx }
    Outputs = "PSReadLine/bin/$Configuration/$Framework/Microsoft.PowerShell.PSReadLine2.dll"
}

$xUnitTestParams = @{
    Inputs = { Get-ChildItem test/*.cs, test/*.json, test/PSReadLine.Tests.csproj }
    Outputs = "test/bin/$Configuration/$Framework/PSReadLine.Tests.dll"
}

$mockPSConsoleParams = @{
    Inputs = { Get-ChildItem MockPSConsole/*.cs, MockPSConsole/Program.manifest, MockPSConsole/MockPSConsole.csproj }
    Outputs = "MockPSConsole/bin/$Configuration/$Framework/MockPSConsole.dll"
}


task BuildMainModule @binaryModuleParams {
    exec { dotnet publish -f $Framework -c $Configuration PSReadLine }
}


task BuildXUnitTests @xUnitTestParams {
    exec { dotnet publish -f $Framework -c $Configuration test }
}


task BuildMockPSConsole @mockPSConsoleParams {
    exec { dotnet publish -f $Framework -c $Configuration MockPSConsole }
}


task GenerateCatalog {
    exec {
        Remove-Item -ea Ignore $PSScriptRoot/bin/$Configuration/PSReadLine/PSReadLine.cat
        $null = New-FileCatalog -CatalogFilePath $PSScriptRoot/bin/$Configuration/PSReadLine/PSReadLine.cat `
                                -Path $PSScriptRoot/bin/$Configuration/PSReadLine `
                                -CatalogVersion 2.0
    }
}


task RunTests BuildMainModule, BuildXUnitTests, { Start-TestRun -Configuration $Configuration -Framework $Framework }


task LayoutModule BuildMainModule, BuildMamlHelp, {
    $extraFiles =
        'PSReadLine/Changes.txt',
        'PSReadLine/License.txt',
        'PSReadLine/SamplePSReadLineProfile.ps1',
        'PSReadLine/PSReadLine.format.ps1xml',
        'PSReadLine/PSReadLine.psm1'

    foreach ($file in $extraFiles)
    {
        
        $content = Get-Content -Path $file -Raw
        Set-Content -Path (Join-Path $targetDir (Split-Path $file -Leaf)) -Value (ConvertTo-CRLF $content) -Force
    }

    $binPath = "PSReadLine/bin/$Configuration/$Framework/publish"
    Copy-Item $binPath/Microsoft.PowerShell.PSReadLine2.dll $targetDir

    if (Test-Path $binPath/System.Runtime.InteropServices.RuntimeInformation.dll)
    {
        Copy-Item $binPath/System.Runtime.InteropServices.RuntimeInformation.dll $targetDir
    }
    else
    {
        Write-Warning "Build using $Framework is not sufficient to be downlevel compatible"
    }

    
    $version = (Get-ChildItem -Path $targetDir/Microsoft.PowerShell.PSReadLine2.dll).VersionInfo.FileVersion
    $moduleManifestContent = ConvertTo-CRLF (Get-Content -Path 'PSReadLine/PSReadLine.psd1' -Raw)

    $getContentArgs = @{
        Raw = $true;
        Path = "./bin/$Configuration/PSReadLine/Microsoft.PowerShell.PSReadLine2.dll"
    }
    if ($PSVersionTable.PSEdition -eq 'Core')
    {
        $getContentArgs += @{AsByteStream = $true}
    }
    else
    {
        $getContentArgs += @{Encoding = "Byte"}
    }
    $b = Get-Content @getContentArgs
    $a = [System.Reflection.Assembly]::Load($b)
    $semVer = ($a.GetCustomAttributes([System.Reflection.AssemblyInformationalVersionAttribute], $false)).InformationalVersion

    if ($semVer -match "(.*)-(.*)")
    {
        
        if ($matches[1] -ne $version) { throw "AssemblyFileVersion mismatch with AssemblyInformationalVersion" }
        $prerelease = $matches[2]

        
        $moduleManifestContent = [regex]::Replace($moduleManifestContent, "}", "PrivateData = @{ PSData = @{ Prerelease = '$prerelease' } }$([System.Environment]::Newline)}")
    }

    $moduleManifestContent = [regex]::Replace($moduleManifestContent, "ModuleVersion = '.*'", "ModuleVersion = '$version'")
    $moduleManifestContent | Set-Content -Path $targetDir/PSReadLine.psd1

    
    foreach ($file in (Get-ChildItem -Recurse -File $targetDir))
    {
        $file.IsReadOnly = $false
    }
}, BuildAboutTopic


task ZipRelease LayoutModule, {
    Compress-Archive -Force -LiteralPath $targetDir -DestinationPath "bin/$Configuration/PSReadLine.zip"
}


task Install LayoutModule, {

    function Install($InstallDir) {
        if (!(Test-Path -Path $InstallDir))
        {
            New-Item -ItemType Directory -Force $InstallDir
        }

        try
        {
            if (Test-Path -Path $InstallDir\PSReadLine)
            {
                Remove-Item -Recurse -Force $InstallDir\PSReadLine -ErrorAction Stop
            }
            Copy-Item -Recurse $targetDir $InstallDir
        }
        catch
        {
            Write-Error -Message "Can't install, module is probably in use."
        }
    }

    Install "$HOME\Documents\WindowsPowerShell\Modules"
    Install "$HOME\Documents\PowerShell\Modules"
}


task Publish -If ($Configuration -eq 'Release') {

    $binDir = "$PSScriptRoot/bin/Release/PSReadLine"

    
    Get-ChildItem -Recurse $binDir -Include "*.dll","*.ps*1" | Get-AuthenticodeSignature | ForEach-Object {
        if ($_.Status -ne 'Valid') {
            throw "$($_.Path) is not signed"
        }
        if ($_.SignerCertificate.Subject -notmatch 'CN=Microsoft Corporation.*') {
            throw "$($_.Path) is not signed with a Microsoft signature"
        }
    }

    
    Get-ChildItem -Recurse $binDir -Include "*.ps*1" | Get-AuthenticodeSignature | ForEach-Object {
        $lines = (Get-Content $_.Path | Measure-Object).Count
        $fileBytes = [System.IO.File]::ReadAllBytes($_.Path)
        $toMatch = ($fileBytes | ForEach-Object { "{0:X2}" -f $_ }) -join ';'
        $crlf = ([regex]::Matches($toMatch, ";0D;0A") | Measure-Object).Count

        if ($lines -ne $crlf) {
            throw "$($_.Path) appears to have mixed newlines"
        }
    }

    $manifest = Import-PowerShellDataFile $binDir/PSReadLine.psd1

    $version = $manifest.ModuleVersion
    if ($null -ne $manifest.PrivateData)
    {
        $psdata = $manifest.PrivateData['PSData']
        if ($null -ne $psdata)
        {
            $prerelease = $psdata['Prerelease']
            if ($null -ne $prerelease)
            {
                $version = $version + '-' + $prerelease
            }
        }
    }

    $yes = Read-Host "Publish version $version (y/n)"

    if ($yes -ne 'y') { throw "Publish aborted" }

    $nugetApiKey = Read-Host -AsSecureString "Nuget api key for PSGallery"

    $publishParams = @{
        Path = $binDir
        NuGetApiKey = [PSCredential]::new("user", $nugetApiKey).GetNetworkCredential().Password
        Repository = "PSGallery"
        ReleaseNotes = (Get-Content -Raw $binDir/Changes.txt)
        ProjectUri = 'https://github.com/PowerShell/PSReadLine'
    }

    Publish-Module @publishParams
}


task Clean {
    git clean -fdx
}


task . LayoutModule, RunTests
