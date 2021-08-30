

Describe "Wait-Event" -Tags "CI" {

    Context "Validate Wait-Event is waiting for events" {
	It "Should time out when it does not receive a FakeEvent" {
	    
$stopwatch = [System.Diagnostics.Stopwatch]::startNew()


Wait-Event -Timeout 1 -SourceIdentifier "FakeEvent"
$stopwatch.Stop()
$stopwatch.ElapsedMilliseconds | Should -BeGreaterThan 500
$stopwatch.ElapsedMilliseconds | Should -BeLessThan 1500
}
}
}
