function Context {
    
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Alias('Tags')]
        [string[]] $Tag = @(),

        [Parameter(Position = 1)]
        [ScriptBlock] $Fixture
    )
    if ($Fixture -eq $null) {
        if ($Name.Contains("`n")) {
            throw "Test fixture name has multiple lines and no test fixture is provided. (Have you provided a name for the test group?)"
        }
        else {
            throw 'No test fixture is provided. (Have you put the open curly brace on the next line?)'
        }
    }
    if ($null -eq (& $SafeCommands['Get-Variable'] -Name Pester -ValueOnly -ErrorAction $script:IgnoreErrorPreference)) {
        
        $sessionState = Set-SessionStateHint -PassThru -Hint "Caller - Captured in Context" -SessionState $PSCmdlet.SessionState
        $Pester = New-PesterState -Path (& $SafeCommands['Resolve-Path'] .) -TestNameFilter $null -TagFilter @() -SessionState SessionState
        $script:mockTable = @{}
    }

    DescribeImpl @PSBoundParameters -CommandUsed 'Context' -Pester $Pester -DescribeOutputBlock ${function:Write-Describe} -TestOutputBlock ${function:Write-PesterResult} -NoTestRegistry:('Windows' -ne (GetPesterOs))
}
