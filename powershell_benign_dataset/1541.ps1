
function Get-MrGeoInformation {



    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ipaddress[]]$IPAddress
    )

    PROCESS {

        $Results = foreach ($IP in $IPAddress) {
            Write-Verbose -Message "Attempting to retrieving Geolocation information for IP Address: '$IP'"
            Invoke-RestMethod -Uri "http://ip-api.com/json/$IP" -TimeoutSec 30
            
            
            Start-Sleep -Milliseconds 410
        }

        foreach ($Result in $Results) {
            [pscustomobject]@{
                AutonomousSystem = $Result.as
                City = $Result.city
                Country = $Result.country
                CountryCode = $Result.countryCode
                ISP = $Result.isp
                Latitude = $Result.lat
                Longitude = $Result.lon
                Organization = $Result.org
                IPAddress = $Result.query
                Region = $Result.region
                RegionName = $Result.regionName
                Status = $Result.status
                TimeZone = $Result.timezone
                ZipCode = $Result.zip
                PSTypeName = 'Mr.GeoInfo'
            }

        }       

    }

}