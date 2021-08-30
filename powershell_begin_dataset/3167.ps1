




param(
    [switch]$Finalize,
    [switch]$Test,
    [string]$ProjectRoot = $ENV:APPVEYOR_BUILD_FOLDER
)


    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"

    $Address = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"
    Set-Location $ProjectRoot

    $Verbose = @{}
    if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
    {
        $Verbose.add("Verbose",$True)
    }
   

    if($Test)
    {
        "`n`tSTATUS: Testing with PowerShell $PSVersion`n"
    
        Import-Module Pester

        Invoke-Pester @Verbose -Path "$ProjectRoot\Tests" -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile" -PassThru |
            Export-Clixml -Path "$ProjectRoot\PesterResults_PS$PSVersion`_$Timestamp.xml"
        
        If($env:APPVEYOR_JOB_ID)
        {
            (New-Object 'System.Net.WebClient').UploadFile( $Address, "$ProjectRoot\$TestFile" )
        }
    }


    If($Finalize)
    {
        
            $AllFiles = Get-ChildItem -Path $ProjectRoot\PesterResults*.xml | Select -ExpandProperty FullName
            "`n`tSTATUS: Finalizing results`n"
            "COLLATING FILES:`n$($AllFiles | Out-String)"

        
            $Results = @( Get-ChildItem -Path "$ProjectRoot\PesterResults_PS*.xml" | Import-Clixml )
            
            $FailedCount = $Results |
                Select -ExpandProperty FailedCount |
                Measure-Object -Sum |
                Select -ExpandProperty Sum
    
            if ($FailedCount -gt 0) {

                $FailedItems = $Results |
                    Select -ExpandProperty TestResult |
                    Where {$_.Passed -notlike $True}

                "FAILED TESTS SUMMARY:`n"
                $FailedItems | ForEach-Object {
                    $Item = $_
                    [pscustomobject]@{
                        Describe = $Item.Describe
                        Context = $Item.Context
                        Name = "It $($Item.Name)"
                        Result = $Item.Result
                    }
                } |
                    Sort Describe, Context, Name, Result |
                    Format-List

                throw "$FailedCount tests failed."
            }
    }