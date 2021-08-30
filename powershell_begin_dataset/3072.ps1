






















$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $here\Get-Planet.ps1










Describe 'Get-Planet' {

    
    
    
    
    
    It 'Given no parameters, it lists all 8 planets' {
        
        

        
        
        $allPlanets = Get-Planet

        
        
        $allPlanets.Count | Should -Be 8

        
        
        
    }

    
    
    Context "Filtering by Name" {

        
        
        


        
        
        
        
        
        
        


        

        
        
        
        It "Given valid -Name '<Filter>', it returns '<Expected>'" -TestCases @(

            
            
            
            
            
            @{ Filter = 'Earth'; Expected = 'Earth' }
            @{ Filter = 'ne*'  ; Expected = 'Neptune' }
            @{ Filter = 'ur*'  ; Expected = 'Uranus' }
            @{ Filter = 'm*'   ; Expected = 'Mercury', 'Mars' }
        ) {

            
            
            param ($Filter, $Expected)

            
            $planets = Get-Planet -Name $Filter
            
            
            $planets | Select -ExpandProperty Name | Should -Be $Expected

            
            
            
        }

        
        
        
        
        
        
        It "Given invalid parameter -Name 'Alpha Centauri', it returns `$null" {
            $planets = Get-Planet -Name 'Alpha Centauri'
            $planets | Should -Be $null
        }
    }
}





























