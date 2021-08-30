
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify which Store to search within")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("iTunes","GooglePlay")]
    [string]$Store,
    [parameter(Mandatory=$true, HelpMessage="Specify the app name to search for within the Store")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z\s]*$")]
    [string]$AppName,
    [parameter(Mandatory=$false, HelpMessage="Limit search results to the specified number (only valid for iTunes Store)")]
    [ValidateNotNullOrEmpty()]
    [string]$Limit = "1"
)
Begin {
    
    switch ($Store) {
        "iTunes" { 
            $StoreAppName = ($AppName -replace " ", "+").ToLower()
            $SearchURL = "https://itunes.apple.com/search?"
            $URL = $SearchURL + "term=$($StoreAppName)" + "&entity=software&limit=$($Limit)"
        }
        "GooglePlay" {
            $StoreAppName = ($AppName -replace " ", "%20").ToLower()
            $SearchURL = "https://play.google.com/store/search?"
            $URL = $SearchURL + "q=$($StoreAppName)&c=apps&hl=en"
        }
    }
}
Process {
    
    switch ($Store) {
        "iTunes" { 
            $WebRequest = Invoke-WebRequest -Uri $URL
            $WebRequestObject = ConvertFrom-Json -InputObject $WebRequest
            if ($WebRequestObject.Results -ne $null) {
                foreach ($Object in $WebRequestObject.Results) {
                    $PSObject = [PSCustomObject]@{
                        "AppName" = $Object.trackCensoredName
                        "StoreLink" = $Object.trackViewUrl
                    }
                    Write-Output -InputObject $PSObject
                }
            }
        }
        "GooglePlay" {
            $WebRequest = Invoke-WebRequest -Uri $URL
            $WebRequestObject = $WebRequest.Links | Where-Object { $_.innerText -like "*$($AppName)*" }
            if ($WebRequestObject -ne $null) {
                foreach ($Object in $WebRequestObject) {
                    $PSObject = [PSCustomObject]@{
                        "AppName" = $Object.innerText
                        "StoreLink" = "https://play.google.com" + $Object.href
                    }
                    Write-Output -InputObject $PSObject
                }
            }
        }
    }
}