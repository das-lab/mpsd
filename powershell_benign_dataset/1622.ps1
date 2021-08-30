















function Out-Menu {
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$True,
            ValueFromPipelinebyPropertyName=$True)]
        [object[]]$Object,
        [string]$Header,
        [string]$Footer,
        [switch]$AllowCancel,
        [switch]$AllowMultiple
    )

    if ($input) {
        $Object = @($input)
    }

    if (!$Object) {
        throw 'Must provide an object.'
    }

    Write-Host ''

    do {
        $prompt = New-Object System.Text.StringBuilder
        switch ($true) {
            {[bool]$Header -and $Header -notmatch '^(?:\s+)?$'} { $null = $prompt.Append($Header); break }
            $true { $null = $prompt.Append('Choose an option') }
            $AllowCancel { $null = $prompt.Append(', or enter "c" to cancel.') }
            $AllowMultiple {$null = $prompt.Append("`nTo select multiple, enter numbers separated by a comma EX: 1, 2") }
        }
        Write-Host $prompt.ToString()
        
        $nums = $Object.Count.ToString().Length
        for ($i = 0; $i -lt $Object.Count; $i++) {
            Write-Host "$("{0:D$nums}" -f ($i+1)). $($Object[$i])"
        }

        if ($Footer) {
            Write-Host $Footer
        }

        Write-Host ''

        if ($AllowMultiple) {
            $answers = @(Read-Host).Split(',').Trim()

            if ($AllowCancel -and $answers -match 'c') {
                return
            }

            $ok = $true
            foreach ($ans in $answers) {
                if ($ans -in 1..$Object.Count) {
                    $Object[$ans-1]
                } else {
                    Write-Host 'Not an option!' -ForegroundColor Red
                    Write-Host ''
                    $ok = $false
                }
            }
        } else {
            $answer = Read-Host

            if ($AllowCancel -and $answer -eq 'c') {
                return
            }

            $ok = $true
            if ($answer -in 1..$Object.Count) {
                $Object[$answer-1]
            } else {
                Write-Host 'Not an option!' -ForegroundColor Red
                Write-Host ''
                $ok = $false
            }
        }
    } while (!$ok)
}

Set-Alias -Name Menu -Value Out-Menu
