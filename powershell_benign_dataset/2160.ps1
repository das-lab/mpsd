
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Select desired architecture to install Visual C++ applications on. You can specify both x86 and x64 as a string array.")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("x86","x64")]
    [string[]]$Architecture = "x86, x64",
    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation.")]
    [switch]$ShowProgress = $true
)
Process {
    
    function Install-ApplicationExectuable {
        param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("x86","x64")]
            [string]$ApplicationArchitecture,
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$CurrentWorkingDirectory
        )
        if ($Script:PSBoundParameters["ShowProgress"]) {
            $ProgressCount = 0
        }
        
        $ApplicationExecutableFolders = Get-ChildItem -LiteralPath $CurrentWorkingDirectory -Filter "*$($ApplicationArchitecture)*" | Select-Object -ExpandProperty FullName
        
        if ($ApplicationExecutableFolders -ne $null) {
            $ApplicationExecutableFolderCount = ($ApplicationExecutableFolders | Measure-Object).Count
            foreach ($ApplicationExecutableFolder in $ApplicationExecutableFolders) {
                $CurrentApplicationPath = Get-ChildItem -LiteralPath $ApplicationExecutableFolder | Select-Object -ExpandProperty FullName
                
                if (($CurrentApplicationPath | Measure-Object).Count -eq 1) {
                    
                    if (($CurrentApplicationPath -ne $null) -and ([System.IO.Path]::GetExtension((Split-Path -Path $CurrentApplicationPath -Leaf)) -like ".exe")) {
                        $CurrentFileDescription = (Get-Item -LiteralPath $CurrentApplicationPath | Select-Object -Property VersionInfo).VersionInfo.FileDescription
                        if ($Script:PSBoundParameters["ShowProgress"]) {
                            $ProgressCount++
                            Write-Progress -Activity "Installing Microsoft Visual C++ Redistributables ($($ApplicationArchitecture))" -Id 1 -Status "$($ProgressCount) / $($ApplicationExecutableFolderCount)" -CurrentOperation "Installing: $($CurrentFileDescription)" -PercentComplete (($ProgressCount / $ApplicationExecutableFolderCount) * 100)
                        }
                        Write-Verbose -Message "Installing: $($CurrentFileDescription)"
                        
                        $ReturnValue = Start-Process -FilePath $CurrentApplicationPath -ArgumentList "/q /norestart" -Wait -PassThru
                        if (($ReturnValue.ExitCode -eq 0) -or ($ReturnValue.ExitCode -eq 3010)) {
                            Write-Verbose -Message "Successfully installed: $($CurrentFileDescription)"
                        }
                        else {
                            Write-Verbose -Message "Failed to install: $($CurrentFileDescription)"
                        }
                    }
                    else {
                        Write-Warning -Message "Unsupported file extension found in folder: $($ApplicationExecutableFolder)"
                    }
                }
                else {
                    Write-Warning -Message "Skipping folder due to unsupported number of files in: $($ApplicationExecutableFolder)"
                }
            }
            if ($Script:PSBoundParameters["ShowProgress"]) {
                Write-Progress -Activity "Installing Microsoft Visual C++ Redistributables ($($ApplicationArchitecture))" -Id 1 -Completed -Status "Completed"
            }
        }
    }

    
    foreach ($Arch in $Architecture) {
        Install-ApplicationExectuable -ApplicationArchitecture $Arch -CurrentWorkingDirectory (Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) -ChildPath "\Source")
    }
}
