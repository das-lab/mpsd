$global:ValidatorRoot = Split-Path $MyInvocation.MyCommand.Path

BeforeEachFeature {
    if ($GherkinOrderTests) {
        Add-Content -Path $global:GherkinOrderTests -Value "BeforeEachFeature"
    }
    New-Module -Name ValidatorTest {
        . $global:ValidatorRoot\Validator.ps1 -Verbose
    } | Import-Module -Global
}

AfterEachFeature {
    if ($GherkinOrderTests) {
        Add-Content -Path $global:GherkinOrderTests -Value "AfterEachFeature"
    }
    Remove-Module ValidatorTest
}

BeforeEachScenario {
    if ($GherkinOrderTests) {
        Add-Content -Path $global:GherkinOrderTests -Value "BeforeEachScenario"
    }
}

AfterEachScenario {
    if ($GherkinOrderTests) {
        Add-Content -Path $global:GherkinOrderTests -Value "AfterEachScenario"
    }
}

Given 'MyValidator is mocked to return True' {
    Mock MyValidator -Module ValidatorTest -MockWith { return $true }
}

When 'Someone calls something that uses MyValidator' {
    if ($GherkinOrderTests) {
        Add-Content -Path $global:GherkinOrderTests -Value "Scenario One"
    }
    Invoke-SomethingThatUsesMyValidator "false"
}

Then 'MyValidator gets called once' {
    Assert-MockCalled -Module ValidatorTest MyValidator 1
}

When 'MyValidator is called with (?<word>\w+)' {
    param($word)
    if ($GherkinOrderTests) {
        Add-Content -Path $global:GherkinOrderTests -Value "Scenario Two"
    }
    $Validation = MyValidator $word
}

Then 'MyValidator should return (?<expected>\w+)' {
    param($expected)
    $expected = $expected -eq "true"
    $Validation | Should -Be $expected
}
function Get-BrowserInformation {

    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0)]
        [String[]]
        [ValidateSet('Chrome','IE','FireFox', 'All')]
        $Browser = 'All',

        [Parameter(Position = 1)]
        [String[]]
        [ValidateSet('History','Bookmarks','All')]
        $DataType = 'All',

        [Parameter(Position = 2)]
        [String]
        $UserName = '',

        [Parameter(Position = 3)]
        [String]
        $Search = ''
    )



    function ConvertFrom-Json20([object] $item){
        
        Add-Type -AssemblyName System.Web.Extensions
        $ps_js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        return ,$ps_js.DeserializeObject($item)
        
    }

    function Get-ChromeHistory {
        $Path = "$Env:systemdrive\Users\$UserName\AppData\Local\Google\Chrome\User Data\Default\History"
        if (-not (Test-Path -Path $Path)) {
            Write-Verbose "[!] Could not find Chrome History for username: $UserName"
        }
        $Regex = '(htt(p|s))://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'
        $Value = Get-Content -Path "$Env:systemdrive\Users\$UserName\AppData\Local\Google\Chrome\User Data\Default\History"|Select-String -AllMatches $regex |% {($_.Matches).Value} |Sort -Unique
        $Value | ForEach-Object {
            $Key = $_
            if ($Key -match $Search){
                New-Object -TypeName PSObject -Property @{
                    User = $UserName
                    Browser = 'Chrome'
                    DataType = 'History'
                    Data = $_
                }
            }
        }        
    }

    function Get-ChromeBookmarks {
    $Path = "$Env:systemdrive\Users\$UserName\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
    if (-not (Test-Path -Path $Path)) {
        Write-Verbose "[!] Could not find FireFox Bookmarks for username: $UserName"
    }   else {
            $Json = Get-Content $Path
            $Output = ConvertFrom-Json20($Json)
            $Jsonobject = $Output.roots.bookmark_bar.children
            $Jsonobject.url |Sort -Unique | ForEach-Object {
                if ($_ -match $Search) {
                    New-Object -TypeName PSObject -Property @{
                        User = $UserName
                        Browser = 'Firefox'
                        DataType = 'Bookmark'
                        Data = $_
                    }
                }
            }
        }
    }

    function Get-InternetExplorerHistory {
        

        $Null = New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS
        $Paths = Get-ChildItem 'HKU:\' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+$' }

        ForEach($Path in $Paths) {

            $User = ([System.Security.Principal.SecurityIdentifier] $Path.PSChildName).Translate( [System.Security.Principal.NTAccount]) | Select -ExpandProperty Value

            $Path = $Path | Select-Object -ExpandProperty PSPath

            $UserPath = "$Path\Software\Microsoft\Internet Explorer\TypedURLs"
            if (-not (Test-Path -Path $UserPath)) {
                Write-Verbose "[!] Could not find IE History for SID: $Path"
            }
            else {
                Get-Item -Path $UserPath -ErrorAction SilentlyContinue | ForEach-Object {
                    $Key = $_
                    $Key.GetValueNames() | ForEach-Object {
                        $Value = $Key.GetValue($_)
                        if ($Value -match $Search) {
                            New-Object -TypeName PSObject -Property @{
                                User = $UserName
                                Browser = 'IE'
                                DataType = 'History'
                                Data = $Value
                            }
                        }
                    }
                }
            }
        }
    }

    function Get-InternetExplorerBookmarks {
        $URLs = Get-ChildItem -Path "$Env:systemdrive\Users\" -Filter "*.url" -Recurse -ErrorAction SilentlyContinue
        ForEach ($URL in $URLs) {
            if ($URL.FullName -match 'Favorites') {
                $User = $URL.FullName.split('\')[2]
                Get-Content -Path $URL.FullName | ForEach-Object {
                    try {
                        if ($_.StartsWith('URL')) {
                            
                            $URL = $_.Substring($_.IndexOf('=') + 1)

                            if($URL -match $Search) {
                                New-Object -TypeName PSObject -Property @{
                                    User = $User
                                    Browser = 'IE'
                                    DataType = 'Bookmark'
                                    Data = $URL
                                }
                            }
                        }
                    }
                    catch {
                        Write-Verbose "Error parsing url: $_"
                    }
                }
            }
        }
    }

    function Get-FireFoxHistory {
        $Path = "$Env:systemdrive\Users\$UserName\AppData\Roaming\Mozilla\Firefox\Profiles\"
        if (-not (Test-Path -Path $Path)) {
            Write-Verbose "[!] Could not find FireFox History for username: $UserName"
        }
        else {
            $Profiles = Get-ChildItem -Path "$Path\*.default\" -ErrorAction SilentlyContinue
            $Regex = '(htt(p|s))://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'
            $Value = Get-Content $Profiles\places.sqlite | Select-String -Pattern $Regex -AllMatches |Select-Object -ExpandProperty Matches |Sort -Unique
            $Value.Value |ForEach-Object {
                if ($_ -match $Search) {
                    ForEach-Object {
                    New-Object -TypeName PSObject -Property @{
                        User = $UserName
                        Browser = 'Firefox'
                        DataType = 'History'
                        Data = $_
                        }    
                    }
                }
            }
        }
    }

    if (!$UserName) {
        $UserName = "$ENV:USERNAME"
    }

    if(($Browser -Contains 'All') -or ($Browser -Contains 'Chrome')) {
        if (($DataType -Contains 'All') -or ($DataType -Contains 'History')) {
            Get-ChromeHistory
        }
        if (($DataType -Contains 'All') -or ($DataType -Contains 'Bookmarks')) {
            Get-ChromeBookmarks
        }
    }

    if(($Browser -Contains 'All') -or ($Browser -Contains 'IE')) {
        if (($DataType -Contains 'All') -or ($DataType -Contains 'History')) {
            Get-InternetExplorerHistory
        }
        if (($DataType -Contains 'All') -or ($DataType -Contains 'Bookmarks')) {
            Get-InternetExplorerBookmarks
        }
    }

    if(($Browser -Contains 'All') -or ($Browser -Contains 'FireFox')) {
        if (($DataType -Contains 'All') -or ($DataType -Contains 'History')) {
            Get-FireFoxHistory
        }
    }
}