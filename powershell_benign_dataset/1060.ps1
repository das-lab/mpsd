











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe "Carbon Website" {

    $tags = Get-Content -Raw -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\tags.json' -Resolve) | ConvertFrom-Json
    $taggedCommands = @{ }
    $tags | ForEach-Object { $taggedCommands[$_.Name] = $_.Name }

    It 'should have tags for all functions' {

        $missingCommandNames = Get-Command -Module 'Carbon' | 
                                    Where-Object { $_.CommandType -ne [Management.Automation.CommandTypes]::Alias } |
                                    Select-Object -ExpandProperty 'Name' | 
                                    Where-Object { -not $taggedCommands.ContainsKey($_) }

        if( $missingCommandNames )
        {
        @"
The following commands are missing from tags.json:

 * $($missingCommandNames -join ('{0} * ' -f [Environment]::NewLine))

"@ | Should BeNullOrEmpty
        }
    }

    It 'should have tags for all DSC resources' {
        $missingDscResources = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\DscResources' -Resolve) -Directory |
                            Select-Object -ExpandProperty 'Name' |
                            Where-Object { -not $taggedCommands.ContainsKey($_) }

        ,$missingDscResources | Should BeNullOrEmpty
    }
}
