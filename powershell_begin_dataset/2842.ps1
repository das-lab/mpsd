
function Test-ModuleVersion {
    [CmdletBinding()]
    param (
        [string]$currentVersion,
        [string]$minimumVersion,
        [string]$maximumVersion,
        [string]$lessThanVersion
    )

    begin {
    }

    process {
        $result = $true

        
        if("$minimumVersion$maximumVersion$lessthanVersion" -eq ''){
            return $true
        }

        
        
        
        if(![string]::IsNullOrEmpty($currentVersion)) {
            if($currentVersion.ToString().Length -eq 1) {
                [version]$currentVersion = "$currentVersion.0"
            } else {
                [version]$currentVersion = $currentVersion
            }
        }

        if(![string]::IsNullOrEmpty($minimumVersion)) {
            if($minimumVersion.ToString().Length -eq 1){
                [version]$minimumVersion = "$minimumVersion.0"
            } else {
                [version]$minimumVersion = $minimumVersion
            }

            if($currentVersion.CompareTo($minimumVersion) -lt 0){
                $result = $false
            }
        }

        if(![string]::IsNullOrEmpty($maximumVersion)) {
            if($maximumVersion.ToString().Length -eq 1) {
                [version]$maximumVersion = "$maximumVersion.0"
            } else {
                [version]$maximumVersion = $maximumVersion
            }

            if ($currentVersion.CompareTo($maximumVersion) -gt 0) {
                $result = $false
            }
        }

        if(![string]::IsNullOrEmpty($lessThanVersion)) {
            if($lessThanVersion.ToString().Length -eq 1) {
                [version]$lessThanVersion = "$lessThanVersion.0"
            } else {
                [version]$lessThanVersion = $lessThanVersion
            }

            if($currentVersion.CompareTo($lessThanVersion) -ge 0) {
                $result = $false
            }
        }

        Write-Output $result
    }

    end {
    }
}
