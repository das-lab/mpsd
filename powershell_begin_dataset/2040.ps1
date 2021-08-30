

Describe "Credential tests" -Tags "CI" {
    It "Explicit cast for an empty credential returns null" {
         
         [PSCredential]::Empty.GetNetworkCredential() | Should -BeNullOrEmpty
    }
}
