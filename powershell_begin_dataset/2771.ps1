

if (Test-Path "$env:SystemRoot\sigcheck.exe") {

    
    $rootpath = Get-Random -Minimum 1 -Maximum 6
    switch ($rootpath) {
        1 { $rootpath = "$env:temp\" }
        2 { $rootpath = "$env:systemroot\" }
        3 { $rootpath = "$env:allusersprofile\" }
        4 { $rootpath = "$env:ProgramFiles\" }
        5 { $rootpath = "$env:ProgramData\" }
        6 { $rootpath = "$env:ProgramFiles(x86)\" }
    }
    
    Try {
        
        Push-Location
        Set-Location $rootpath

        & $env:SystemRoot\sigcheck.exe /accepteula -a -e -c -h -q -s -r 2> $null | ConvertFrom-Csv | ForEach-Object {
            $_
        }
    } Catch {
        Write-Error ("Caught: {0}" -f $_)
    } Finally {
        Pop-Location
    }

} else {
    Write-Error "Sigcheck.exe not found in $env:SystemRoot."
}