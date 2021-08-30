

Describe "GetDateFormatUpdates" -Tags "Feature" {

    It "Verifies that FileDate format works" {
        $date = Get-Date
        $expectedFormat = "{0:yyyyMMdd}" -f $date
        $actualFormat = Get-Date -Date $date -Format FileDate

        $actualFormat | Should -Be $expectedFormat
    }

    It "Verifies that FileDateUniversal format works" {
        $date = (Get-Date).ToUniversalTime()
        $expectedFormat = "{0:yyyyMMddZ}" -f $date
        $actualFormat = Get-Date -Date $date -Format FileDateUniversal

        $actualFormat | Should -Be $expectedFormat
    }

    It "Verifies that FileDateTime format works" {
        $date = Get-Date
        $expectedFormat = "{0:yyyyMMddTHHmmssffff}" -f $date
        $actualFormat = Get-Date -Date $date -Format FileDateTime

        $actualFormat | Should -Be $expectedFormat
    }

    It "Verifies that FileDateTimeUniversal format works" {
        $date = (Get-Date).ToUniversalTime()
        $expectedFormat = "{0:yyyyMMddTHHmmssffffZ}" -f $date
        $actualFormat = Get-Date -Date $date -Format FileDateTimeUniversal

        $actualFormat | Should -Be $expectedFormat
    }

}

Describe "GetRandomMiscTests" -Tags "Feature" {
    It "Shouldn't overflow when using max range" {

        $hadError = $false

        
        { Get-Random -Minimum ([Int32]::MinValue) -Maximum ([Int32]::MaxValue) -ErrorAction Stop } | Should -Not -Throw
    }
}
