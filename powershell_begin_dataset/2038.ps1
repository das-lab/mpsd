


Describe "Assembly::LoadWithPartialName Validation Test" -Tags "CI" {

    $defaultErrorId = 'FileLoadException'
    $testcases = @(
        
        
        
        @{
            Name = 'system.windows.forms'
            ErrorId = $defaultErrorId
        }
        
        @{
            Name = 'System.Windows.Forms'
            ErrorId = $defaultErrorId
        }
    )

    
    

    
    

    It "Assembly::LoadWithPartialName should fail to load blacklisted assembly: <Name>" -Pending -TestCases $testcases {
        param(
            [Parameter(Mandatory)]
            [string]
            $Name,
            [Parameter(Mandatory)]
            [string]
            $ErrorId
        )

        {[System.Reflection.Assembly]::LoadWithPartialName($Name)} | Should -Throw -ErrorId $ErrorId
    }
}
