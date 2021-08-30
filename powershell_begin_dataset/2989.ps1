Set-StrictMode -Version Latest

Describe 'Clean handling of break and continue' {
    
    

    Context 'Break' {
        break
    }

    Context 'Continue' {
        continue
    }

    It 'Did not abort the whole test run' { $null = $null }
}
