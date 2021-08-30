$scripts = Get-ChildItem -Path $PSScriptRoot -Recurse -Filter *.ps1 | 
                Where-Object FullName -NotMatch '.Tests.'

[regex]$regex = "(^[A-Z\-]+-)"

Describe -Tag 'Help' 'Help' {

    foreach ($script in $scripts) {

        Context "[$($script.BaseName)] Validate Comment Based Help" {

            
            if ($script.Name -Match $regex) {
                $name = $script.BaseName.Replace($Matches[0], '')
            } elseif ($script.Name -match 'O365-') {
                $name = $script.BaseName.Replace($Matches[0], '')
            } elseif ($script.Name -match 'Function_Template.ps1') {
                $name = 'Get-Something' 
            } else {
                $name = $script.BaseName
            }

            
            if ((Get-Content -Path $script.FullName -TotalCount 1) -match 'function') {
                
                
                . $($script.FullName)

                $functionHelp = Get-Help $name -Full

                It 'Contains Description' {
                    $functionHelp.Description | Should Not BeNullOrEmpty
                }
                
                It 'Contains Synopsis' {
                    $functionHelp.Synopsis | Should Not BeNullOrEmpty
                }

                It 'Contains Examples' {
                    $functionHelp.Examples | Should Not BeNullOrEmpty
                }

                It 'Contains Parameters' {
                    $functionHelp.Parameters | Should Not BeNullOrEmpty
                }
            } else {
                It "[$($script.BaseName)] is not a function and skipped" {
                } -Skip
            }
        }
    }
}

