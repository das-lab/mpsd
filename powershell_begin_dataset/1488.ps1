
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,Position=0)]
    [string[]]
    
    $Path,

    [string]
    
    $Name,

    [string[]]
    
    $Test,

    [string]
    
    $XmlLogPath,
    
    [Switch]
    
    $PassThru,
    
    [Switch]
    
    $Recurse
)


Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-Blade.ps1' -Resolve)

function Get-FunctionsInFile($testScript)
{
    Write-Debug -Message "Loading test script '$testScript'."
    $testScriptContent = Get-Content "$testScript"
    if( -not $testScriptContent )
    {
        return @()
    }

    $errors = [Management.Automation.PSParseError[]] @()
    $tokens = [System.Management.Automation.PsParser]::Tokenize( $testScriptContent, [ref] $errors )
    if( $errors -ne $null -and $errors.Count -gt 0 )
    {
        Write-Error "Found $($errors.count) error(s) parsing '$testScript'."
        return
    }
    
    Write-Debug -Message "Found $($tokens.Count) tokens in '$testScript'."
    
    $functions = New-Object System.Collections.ArrayList
    $atFunction = $false
    for( $idx = 0; $idx -lt $tokens.Count; ++$idx )
    {
        $token = $tokens[$idx]
        if( $token.Type -eq 'Keyword'-and $token.Content -eq 'Function' )
        {
            $atFunction = $true
        }
        
        if( $atFunction -and $token.Type -eq 'CommandArgument' -and $token.Content -ne '' )
        {
            Write-Debug -Message "Found function '$($token.Content).'"
            [void] $functions.Add( $token.Content )
            $atFunction = $false
        }
    }
    
    return $functions.ToArray()
}

function Invoke-Test
{
    
    [CmdletBinding()]
    param(
        $fixture, 
        $function
    )

    Set-StrictMode -Version 'Latest'

    [Blade.TestResult]$testInfo = New-Object 'Blade.TestResult' $fixture,$function

    $Error.Clear()

    $testPassed = $false
    try
    {
        if( Test-path function:Start-Test )
        {
            . Start-Test | ForEach-Object { $testInfo.Output.Add( $_ ) }
        }
        elseif( Test-Path function:SetUp )
        {
            Write-Warning ('The SetUp function is obsolete and will be removed in a future version of Blade. Please use Start-Test instead.')
            . SetUp | ForEach-Object { $testInfo.Output.Add( $_ ) }
        }
        
        if( Test-Path function:$function )
        {
            . $function | ForEach-Object { $testInfo.Output.Add( $_ ) }
        }
        $testPassed = $true
    }
    catch [Blade.AssertionException]
    {
        $ex = $_.Exception
        $testInfo.Completed( $ex )
    }
    catch
    {
        $testInfo.Completed( $_ )
    }
    finally
    {
        $tearDownResult = New-Object 'Blade.TestResult' $fixture,$function
        $tearDownFailed = $false
        try
        {
            if( Test-Path function:Stop-Test )
            {
                . Stop-Test | ForEach-Object { $tearDownResult.Output.Add( $_ ) }
            }
            elseif( Test-Path -Path function:TearDown )
            {
                Write-Warning ('The TearDown function is obsolete and will be removed in a future version of Blade. Please use Start-Test instead.')
                . TearDown | ForEach-Object { $tearDownResult.Output.Add( $_ ) }
            }
            $tearDownResult.Completed()
        }
        catch
        {
            $tearDownResult.Completed( $_ )
            $tearDownFailed = $true
        }
        finally
        {
            if( $testPassed )
            {
                $testInfo.Completed()
            }

            $flag = '! '
            $result = 'FAILED'
            if( $testInfo.Passed )
            {
                $flag = '  '
                $result = 'Passed'
            }
            Write-Verbose -Message ('  {0}{1} in {2:mm\:ss\.fff}  [{3}]' -f $flag,$result,$testInfo.Duration,$function)
            $testInfo
            if( $tearDownFailed )
            {
                $tearDownResult
            }
        }

        $Error.Clear()
    }

}

$getChildItemParams = @{ }
if( $Recurse )
{
    $getChildItemParams.Recurse = $true
}

$testScripts = @( Get-ChildItem $Path Test-*.ps1 @getChildItemParams )
if( $testScripts -eq $null )
{
    $testScripts = @()
}

$Error.Clear()
$testsIgnored = 0
$TestScript = $null
$TestDir = $null

$results = $null

$testScripts | 
    ForEach-Object {
        $testCase = $_
        $TestScript = (Resolve-Path $testCase.FullName).Path
        $TestDir = Split-Path -Parent $testCase.FullName 
        
        $testModuleName =  [System.IO.Path]::GetFileNameWithoutExtension($testCase)

        $functions = Get-FunctionsInFile $testCase.FullName |
                        Where-Object { $_ -match '^(Test|Ignore)-(.*)$' } |
                        Where-Object { 
                            if( $PSBoundParameters.ContainsKey('Test') )
                            {
                                return $Test | Where-Object { $Matches[2] -like $_ } 
                            }

                            if( $Matches[1] -eq 'Ignore' )
                            {
                                Write-Warning ("Skipping ignored test '{0}'." -f $_)
                                $testsIgnored++
                                return $false
                            }

                            return $true
                        }
        if( -not $functions )
        {
            return
        }

        @('Start-TestFixture','Start-Test','Setup','TearDown','Stop-Test','Stop-TestFixture') |
            ForEach-Object { Join-Path -Path 'function:' -ChildPath $_ } |
            Where-Object { Test-Path -Path $_ } |
            Remove-Item
        
        Write-Verbose -Message ('[{0}]' -f $testCase.Name)

        . $testCase.FullName

        try
        {
            if( Test-Path -Path 'function:Start-TestFixture' )
            {
                . Start-TestFixture | Out-String | Write-Debug
            }

            foreach( $function in $functions )
            {

                if( -not (Test-Path -Path function:$function) )
                {
                    continue
                }
                
                Invoke-Test $testModuleName $function 
            }

            if( Test-Path -Path function:Stop-TestFixture )
            {
                try
                {
                    . Stop-TestFixture | Out-String | Write-Debug
                }
                catch
                {
                    Write-Error ("An error occured tearing down test fixture '{0}': {1}" -f $testCase.Name,$_)
                    $result = New-Object 'Blade.TestResult' $testModuleName,'Stop-TestFixture'
                    $result.Finished( $_ )
                }                
            }
        }
        finally
        {
            foreach( $function in $functions )
            {
                if( $function -and (Test-Path function:$function) )
                {
                    Remove-Item function:\$function
                }
            }
        }        
    } | 
    Tee-Object -Variable 'results' |
    Where-Object { $PassThru -or -not $_.Passed } 

$Global:LastBladeResult = New-Object 'Blade.RunResult' $Name,([Blade.TestResult[]]$results), $testsIgnored
if( $LastBladeResult.Errors -or $LastBladeResult.Failures )
{
    Write-Error $LastBladeResult.ToString()
}

if( $XmlLogPath )
{
    $LastBladeResult | Export-RunResultXml -FilePath $XmlLogPath
}

$LastBladeResult | Format-Table | Out-Host
