









function Get-MACVendor
{
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='MAC-Address or the first 6 digits of it')]
        [ValidateScript({
                if($_ -match "^(([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})|([0-9A-Fa-f]{2}){6})|([0-9A-Fa-f]{2}[:-]){2}([0-9A-Fa-f]{2})|([0-9A-Fa-f]{2}){3}$")
                {
                    return $true
                }
                else 
                {
                    throw "Enter a valid MAC-Address (like 00:00:00:00:00:00 or 00-00-00-00-00-00)!"    
                }
        })]
        [String[]]$MACAddress
    )

    Begin{
        
        $CSV_MACVendorList_Path = "$PSScriptRoot\Resources\IEEE_Standards_Registration_Authority.csv"        

        if([System.IO.File]::Exists($CSV_MACVendorList_Path))
        {
            $MAC_VendorList = Import-Csv -Path $CSV_MACVendorList_Path | Select-Object -Property "Assignment", "Organization Name"
        }
        else {
            throw [System.IO.FileNotFoundException] "No CSV-File to assign vendor with MAC-Address found!"
        }
    }

    Process{
        foreach($MACAddress2 in $MACAddress)
        {
            $Vendor = [String]::Empty

            
            $MAC_VendorSearch = $MACAddress2.Replace("-","").Replace(":","").Substring(0,6)

            foreach($ListEntry in $MAC_VendorList)
            {
                if($ListEntry.Assignment -eq $MAC_VendorSearch)
                {
                    $Vendor = $ListEntry."Organization Name"
                    
                    [pscustomobject] @{
                        MACAddress = $MACAddress2
                        Vendor = $Vendor
                    }
                }
            }                            
        }
    }

    End{

    }
}