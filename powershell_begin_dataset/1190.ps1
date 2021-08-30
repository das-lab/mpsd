











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-NoDocumentationMissing
{
    param(
        [string[]]
        $CommandName
    )

    Set-StrictMode -Version 'Latest'

    $CommandName | Should -BeNullOrEmpty -Because ("The following commands are missing all or part of their documentation:`n`t{0}" -f ($CommandName  -join "`n`t"))
}

filter Where-HelpIncomplete
{
    param(
        [Parameter(ValueFromPipeline=$true)]
        [Management.Automation.CommandInfo]
        $Command
    )

    Set-StrictMode -Version 'Latest'

    $_ | 
        
        Where-Object { 
            $help = $_ | Get-Help 
            if( $help -is [String] )
            {
                return $true
            }

            if( -not (($help | Get-Member 'synopsis') -and ($help | Get-Member 'description') -and ($help | Get-Member 'examples')) )
            {
                return $true
            }

            return -not ($help.synopsis -and $help.description -and $help.examples)
        } 
}

Describe 'Documentation' {
    It 'all functions should have documentation' {
    	$commandsMissingDocumentation = Get-Command -Module Carbon | 
                                            Where-HelpIncomplete |  
                                            Select-Object -ExpandProperty Name | 
                                            Sort-Object
        Assert-NoDocumentationMissing $commandsMissingDocumentation
    }
    
    It 'all dsc resources should have documentation' {
        $dscRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\DscResources' -Resolve
        $resourcesMissingDocs = @()
        
        foreach( $resourceRoot in (Get-ChildItem -Path $dscRoot -Directory -Filter 'Carbon_*') )
        {
            Import-Module -Name $resourceRoot.FullName
            $moduleName = $resourceRoot.Name
            try
            {
                $resourcesMissingDocs += Get-Command -Name 'Set-TargetResource' -Module $moduleName | 
                                            Where-HelpIncomplete | 
                                            Select-Object -ExpandProperty Module | 
                                            Select-Object -ExpandProperty Name | 
                                            Sort-Object
            }
            finally
            {
                Remove-Module $moduleName
            }
        }
    
        Assert-NoDocumentationMissing $resourcesMissingDocs
    }
    
}
