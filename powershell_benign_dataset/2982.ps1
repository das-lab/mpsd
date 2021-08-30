function BeforeEachFeature {
    
    [CmdletBinding(DefaultParameterSetName = "All")]
    param(

        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = "Tags")]
        [String[]]$Tags = @(),

        [Parameter(Mandatory = $True, Position = 1, ParameterSetName = "Tags")]
        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = "All")]
        [ScriptBlock]$Script
    )

    
    if ($PSCmdlet.ParameterSetName -eq "Tags") {
        ${Script:GherkinHooks}.BeforeEachFeature += @( @{ Tags = $Tags; Script = $Script } )
    }
    else {
        ${Script:GherkinHooks}.BeforeEachFeature += @( @{ Tags = @(); Script = $Script } )
    }
}

function AfterEachFeature {
    
    [CmdletBinding(DefaultParameterSetName = "All")]
    param(

        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = "Tags")]
        [String[]]$Tags = @(),

        [Parameter(Mandatory = $True, Position = 1, ParameterSetName = "Tags")]
        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = "All")]
        [ScriptBlock]$Script
    )

    
    if ($PSCmdlet.ParameterSetName -eq "Tags") {
        ${Script:GherkinHooks}.AfterEachFeature += @( @{ Tags = $Tags; Script = $Script } )
    }
    else {
        ${Script:GherkinHooks}.AfterEachFeature += @( @{ Tags = @(); Script = $Script } )
    }
}

function BeforeEachScenario {
    
    [CmdletBinding(DefaultParameterSetName = "All")]
    param(

        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = "Tags")]
        [String[]]$Tags = @(),

        [Parameter(Mandatory = $True, Position = 1, ParameterSetName = "Tags")]
        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = "All")]
        [ScriptBlock]$Script
    )

    
    if ($PSCmdlet.ParameterSetName -eq "Tags") {
        ${Script:GherkinHooks}.BeforeEachScenario += @( @{ Tags = $Tags; Script = $Script } )
    }
    else {
        ${Script:GherkinHooks}.BeforeEachScenario += @( @{ Tags = @(); Script = $Script } )
    }
}

function AfterEachScenario {
    
    [CmdletBinding(DefaultParameterSetName = "All")]
    param(
        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = "Tags")]
        [String[]]$Tags = @(),

        [Parameter(Mandatory = $True, Position = 1, ParameterSetName = "Tags")]
        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = "All")]
        [ScriptBlock]$Script
    )

    
    if ($PSCmdlet.ParameterSetName -eq "Tags") {
        ${Script:GherkinHooks}.AfterEachScenario += @( @{ Tags = $Tags; Script = $Script } )
    }
    else {
        ${Script:GherkinHooks}.AfterEachScenario += @( @{ Tags = @(); Script = $Script } )
    }
}
