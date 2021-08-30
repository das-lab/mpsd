



$a1 = New-Object System.Collections.ArrayList
$a2 = New-Object System.Collections.ArrayList
$a3 = New-Object System.Collections.ArrayList

1..5 | % {
    $null = $a1.Add($(Measure-Command {
        $StringBuilder = New-Object System.Text.StringBuilder
        1..10000 | % {
            $null = $stringBuilder.Append($_)
        }
        $OutputString = $StringBuilder.ToString()
        rv StringBuilder
        rv OutputString
    }).TotalSeconds)

    $null = $a2.Add($(Measure-Command {
        $OutputString = ''
        1..10000 | % {
            $OutputString += $_
        }
        rv OutputString
    }).TotalSeconds)

    $null = $a3.Add($(Measure-Command {
        $OutputString = -join@(1..10000 | % {
            $_
        })
        rv OutputString
    }).TotalSeconds)
}

@"
Method,Time
StringBuilder,                $($a1 | measure -Sum | % {$_.sum.tostring('000.000')})
string +=,                    $($a2 | measure -Sum | % {$_.sum.tostring('000.000')})
string -join@(for(...){...}), $($a3 | measure -Sum | % {$_.sum.tostring('000.000')})
"@ | ConvertFrom-Csv | sort time | ft -AutoSize


