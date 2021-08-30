













function Export-RunResultXml
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Blade.RunResult]
        
        $RunResult,

        [Parameter(Mandatory=$true)]
        [string]
        
        $FilePath
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        $now = Get-Date
        $bladeVersion = (Get-Module -Name 'Blade').Version
        $cultureName = (Get-Culture).Name
        $uiCultureName = (Get-UICulture).Name
        $cwd = (Get-Location).Path
        $osVersion = [Environment]::OSVersion.VersionString
        $platform = [Environment]::OSVersion.Platform
        $clrVersion = $PSVersionTable.CLRVersion
        $psVersion = $PSVersionTable.PSVersion
        $resultXml = [xml](@'
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<test-results name="" total="" errors="" failures="" not-run="0" inconclusive="0" ignored="" skipped="0" invalid="0" date="{0:yyyy-MM-dd}" time="{0:HH:mm:ss}">
  <environment blade-version="{1}" clr-version="{2}" powershell-version="{3}" os-version="{4}" platform="{5}" cwd="{6}" machine-name="{7}" user="{8}" user-domain="{9}" />
  <culture-info current-culture="{10}" current-uiculture="{11}" />
  <test-suite name="" type="BladeFixture" executed="True" asserts="0" result="" success="" time="">
    <results />
  </test-suite>
</test-results>
'@ -f $now,$bladeVersion,$clrVersion,$psVersion,$osVersion,$platform,$cwd,$env:COMPUTERNAME,$env:USERNAME,$env:USERDOMAIN,$cultureName,$uiCultureName)

    }

    process
    {
        $testResults = $resultXml.'test-results'
        $testResults.SetAttribute( 'name', $RunResult.Name )
        $testResults.SetAttribute( 'total', $RunResult.Count )
        $testResults.SetAttribute( 'errors', $RunResult.Errors.Count )
        $testResults.SetAttribute( 'failures', $RunResult.Failures.Count )
        $testResults.SetAttribute( 'ignored', $RunResult.IgnoredCount )

        $rootTestSuite = $testResults.'test-suite'
        $rootTestSuite.SetAttribute( 'name', $RunResult.Name )

        $rootResults = $rootTestSuite.ChildNodes[0]

        $totalTime = [TimeSpan]::Zero
        $allResult = 'Success'
        $allSuccess = $true

        Invoke-Command -ScriptBlock {
                $RunResult.Failures
                $RunResult.Errors
                $RunResult.Passed                                        
            } |
            Group-Object -Property 'FixtureName' |
            ForEach-Object {
                $testSuite = $resultXml.CreateElement('test-suite')
                [void]$rootResults.AppendChild( $testSuite )

                $testSuite.SetAttribute( 'type', 'BladeFixture' )
                $testSuite.SetAttribute( 'name', $_.Name )
                $testSuite.SetAttribute( 'executed', $true )
                $testSuite.SetAttribute( 'asserts', '0' )

                $duration = [TimeSpan]::Zero
                $success = $true
                $result = 'Success'
                $results = $null
                foreach( $testResult in $_.Group )
                {
                    if( -not $results )
                    {
                        $results = $resultXml.CreateElement( 'results' )
                        [void]$testSuite.AppendChild( $results )
                    }

                    $testCase = $resultXml.CreateElement('test-case')
                    [void]$results.AppendChild( $testCase )

                    $testCase.SetAttribute( 'name', $testResult.Name )
                    $testCase.SetAttribute( 'executed', 'True' )
                    $testCase.SetAttribute( 'time', $testResult.Duration.TotalSeconds )
                    $testCase.SetAttribute( 'asserts', '0' )

                    $duration += $testResult.Duration
                    $totalTime += $testResult.Duration
                    if( -not $testResult.Passed )
                    {
                        $allSuccess = $success = $false
                        $allResult = $result = 'Failure'

                        $testCase.SetAttribute( 'result', 'Failure' )
                        $testCase.SetAttribute( 'success', 'False' )

                        $failure = $resultXml.CreateElement( 'failure' )
                        [void]$testCase.AppendChild( $failure )

                        $message = $resultXml.CreateElement( 'message' )
                        [void]$failure.AppendChild( $message )
                        
                        $stackTrace = $resultXml.CreateElement( 'stack-trace' )
                        [void]$failure.AppendChild( $stackTrace )

                        if( $testResult.Error )
                        {
                            $ex = $testResult.Error.Exception
                            while( $ex.InnerException )
                            {
                                $ex = $ex.InnerException
                            }
                            $message.InnerText = $ex.Message
                            $stackTrace.InnerText = $testResult.Error.ScriptStackTrace
                        }
                        elseif( $testResult.Failure )
                        {
                            $message.InnerText = $testResult.Failure.Message
                            $stackTrace.InnerText = $testResult.Failure.PSStackTrace -join ("{0}  " -f [Environment]::NewLine)
                        }
                    }
                    else
                    {
                        $testCase.SetAttribute( 'result', 'Success' )
                        $testCase.SetAttribute( 'success', 'True' )
                    }
                }

                $testSuite.SetAttribute( 'result', $result )
                $testSuite.SetAttribute( 'success', $success )
                $testSuite.SetAttribute( 'time', $duration.TotalSeconds )

            }

        $rootTestSuite.SetAttribute( 'result', $allResult )
        $rootTestSuite.SetAttribute( 'success', $allSuccess )
        $rootTestSuite.SetAttribute( 'time', $totalTime.TotalSeconds )
    }

    end
    {
        $fileRoot = Split-Path -Parent -Path $FilePath
        if( -not (Test-Path -Path $fileRoot -PathType Container) )
        {
            New-Item -Path $fileRoot -ItemType 'Directory' | Out-String | Write-Verbose
        }
        $resultXml.Save( $FilePath )
    }

}