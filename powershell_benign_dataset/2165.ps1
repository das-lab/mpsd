
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, ParameterSetName="AppName", HelpMessage="Specify the app name to search for within the App Store.")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z\s]*$")]
    [string]$AppName,

    [parameter(Mandatory=$true, ParameterSetName="Url", HelpMessage="Specify the URL pointing to the app in the App Store.")]
    [ValidateNotNullOrEmpty()]
    [string]$URL,

    [parameter(Mandatory=$true, ParameterSetName="AppName", HelpMessage="Path to a folder where the app image will be downloaded to.")]
    [parameter(Mandatory=$true, ParameterSetName="Url")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+")]
    [ValidateScript({
	    
	    if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
		    Throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
	    }
	    else {
		    
		    if (Test-Path -Path $_ -PathType Container) {
				    return $true
		    }
		    else {
			    Throw "Unable to locate part of or the whole specified path, specify a valid path"
		    }
	    }
    })]
    [string]$Path
)
Process {
    
    $StoreAppName = ($AppName -replace " ", "+").ToLower()

    switch ($PSCmdlet.ParameterSetName) {
        "AppName" {
            
            $SearchURL = "https://itunes.apple.com/search?term=$($StoreAppName)&entity=software&limit=1"
            $SearchWebRequest = Invoke-WebRequest -Uri $SearchURL
            $AppLink = (ConvertFrom-Json -InputObject $SearchWebRequest).Results | Select-Object -ExpandProperty trackViewUrl
        }
        "Url" {
            $AppLink = $URL
        }
    }

    
    if ($AppLink -ne $null) {
        $WebRequest = Invoke-WebRequest -Uri $AppLink
        $AppIcon = $WebRequest.Images | Where-Object { ($_.Width -eq 175) -and ($_.Class -like "artwork") }
        if ($AppIcon -ne $null) {
            
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($AppIcon."src-swap", "$($Path)\$($AppIcon.alt).jpg")
            $AppImage = [PSCustomObject]@{
                ImageName = $AppIcon.alt
                ImagePath = "$($Path)\$($AppIcon.alt).jpg"
            }
            Write-Output -InputObject $AppImage
        }
    }
    else {
        Write-Warning -Message "Unable to determine app link for specified app: $($AppName)"
    }
}
End {
    
    $WebClient.Dispose()
}