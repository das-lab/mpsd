

$path = 'C:\temp\'

$a1 = New-Object System.Collections.ArrayList
$a2 = New-Object System.Collections.ArrayList
$a3 = New-Object System.Collections.ArrayList
$a4 = New-Object System.Collections.ArrayList
$a5 = New-Object System.Collections.ArrayList

$null = 1..3 | % {
    $a1.Add(
        (Measure-Command {
            
            Get-ChildItem $path -File -Recurse
        }).Ticks
    )
    $a2.Add(
        (Measure-Command {
            
            Get-Files $path -Method EnumerateFiles -File -Recurse
        }).Ticks
    )
    $a3.Add(
        (Measure-Command {
            
            Get-Files $path -Method Dir -File -Recurse
        }).Ticks
    )
    $a4.Add(
        (Measure-Command {
            
            Get-Files $path -Method Robocopy -File -Recurse
        }).Ticks
    )
    $a5.Add(
        (Measure-Command {
            
            Get-Files $path -Method AlphaFS -File -Recurse
        }).Ticks
    )
}

($a1 | measure -Sum).sum
($a2 | measure -Sum).sum
($a3 | measure -Sum).sum
($a4 | measure -Sum).sum
($a5 | measure -Sum).sum
