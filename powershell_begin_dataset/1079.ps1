











$importCarbonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve

Describe 'Import-Carbon' {

    BeforeEach {
        $Global:Error.Clear()
        if( (Get-Module 'Carbon') )
        {
            Remove-Module 'Carbon' -Force
        }
    }
    
    AfterEach {
        if( (Get-Module 'Carbon') )
        {
            Remove-Module 'Carbon' -Force
        }
    }
    
    It 'should import' {
        & $importCarbonPath
        (Get-Command -Module 'Carbon') | Should Not BeNullOrEmpty
    }
    
    It 'should import with prefix' {
        & $importCarbonPath -Prefix 'C'
        $carbonCmds = Get-Command -Module 'Carbon'
        $carbonCmds | Should Not BeNullOrEmpty
        foreach( $cmd in $carbonCmds )
        {
            $cmd.Name | Should -Match '^.+-C.+$'
        }
    }
    
    It 'should handle drives in env path that do not exist' {
        $drive = $null
        for( $idx = [byte][char]'Z'; $idx -ge [byte][char]'A'; --$idx )
        {
            $driveLetter = [char][byte]$idx
            $drive = '{0}:\' -f $driveLetter
            if( -not (Test-Path -Path $drive) )
            {
                break
            }
        }
    
        $badPath = '{0}fubar' -f $drive
        $originalPath = $env:Path
        $env:Path = '{0};{1}' -f $env:Path,$badPath
        try
        {
            & $importCarbonPath
            $Global:Error.Count | Should Be 0
        }
        finally
        {
            $env:Path = $originalPath
        }
    }

    It 'should import fast' {
        
        $maxAvgDuration = 9.0
        if( (Test-Path -Path 'env:APPVEYOR') )
        {
            
            $maxAvgDuration = 0.8
        }
        $carbonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve
        & {
                for( $idx = 0; $idx -lt 7; ++$idx )
                {
                    $job = Start-Job -ScriptBlock {
                        $started = Get-Date
                        Import-Module -Name $using:carbonPath
                        return (Get-Date) - $started
                    }
                    $job | Wait-Job | Receive-Job 
                    $job | Remove-Job -Force
                }
            } |
            Select-Object -ExpandProperty 'TotalSeconds' |
            Sort-Object |
            
            Select-Object -Skip 1 |
            Select-Object -SkipLast 1 |
            Measure-Object -Average -Maximum -Minimum |
            ForEach-Object { 
                Write-Verbose -Message ('Import-Module Statistics') -Verbose
                Write-Verbose -Message ('========================') -Verbose
                $_ | Format-List | Out-String | Write-Verbose -Verbose
                $_
            } |
            Select-Object -ExpandProperty 'Average' |
            Should -BeLessOrEqual $maxAvgDuration
    }
}
