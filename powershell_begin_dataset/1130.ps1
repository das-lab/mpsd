











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldGetPerformanceCounters
{
    $categories = [Diagnostics.PerformanceCounterCategory]::GetCategories() 
    foreach( $category in $categories )
    {
        $countersExpected = @( $category.GetCounters("") )
        $countersActual = @( Get-PerformanceCounter -CategoryName $category.CategoryName )
        Assert-Equal $countersExpected.Length $countersActual.Length
    }
    
}

function Test-ShouldGetNoPerformanceCountersForNonExistentCategory
{
    $counters = Get-PerformanceCounter -CategoryName 'IDoNotExist'
    Assert-Null $counters
}

