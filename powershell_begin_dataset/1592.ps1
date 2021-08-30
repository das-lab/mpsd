



function Get-Header {
    param (
        [string]$path,
        [int]$bits = 4
    )
    
    $path = Resolve-FullPath $path

    try {
        
        $HeaderAsHexString = New-Object System.Text.StringBuilder
        [Byte[]](Get-Content -Path $path -TotalCount $bits -Encoding Byte -ea Stop) | % {
            if (("{0:X}" -f $_).length -eq 1) {
                $null = $HeaderAsHexString.Append('0{0:X}' -f $_)
            } else {
                $null = $HeaderAsHexString.Append('{0:X}' -f $_)
            }
        }

        $HeaderAsHexString.ToString()
    } catch {}
}
