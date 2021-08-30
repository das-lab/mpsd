











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-ServiceConfiguration' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should load all service configuration' {
        Get-Service | 
            
            Where-Object { $_.Name -notlike 'Carbon*' } |
            Get-ServiceConfiguration | 
            Format-List -Property *
        $Global:Error.Count | Should -Be 0
    }

    It 'should write an error if the service doesn''t exist' {
        $info = Get-CServiceConfiguration -Name 'YOLOyolo' -ErrorAction SilentlyContinue
        $info | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'Cannot\ find\ any\ service'
    }

    It 'should ignore missing service' {
        $info = Get-CServiceConfiguration -Name 'FUBARsnafu' -ErrorAction Ignore
        $info | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
    }
    
    It 'should load extended type data' {
        $services = Get-Service | Where-Object { $_.Name -notlike 'Carbon*' }
        $memberNames = $null
            
        foreach( $service in $services )
        {
            $info = Get-CServiceConfiguration -Name $service.Name
            if( -not $memberNames )
            {
                $memberNames = 
                    $info | 
                    Get-Member -MemberType 'Property' | 
                    Select-Object -ExpandProperty 'Name'
            }

            foreach( $memberName in $memberNames )
            {
                $info.$memberName | Should -Be $service.$memberName
            }
        }
        $Global:Error.Count | Should -Be 0
    }
}
