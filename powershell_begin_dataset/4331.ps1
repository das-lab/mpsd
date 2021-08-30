function Get-Hash

{
    [CmdletBinding()]
    Param
    (
        [string]
        $locationString
    )

    if(-not $locationString)
    {
        return ""
    }

    $sha1Object = New-Object System.Security.Cryptography.SHA1Managed
    $stringHash = $sha1Object.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($locationString));
    $stringHashInHex = [System.BitConverter]::ToString($stringHash)

    if ($stringHashInHex)
    {
        
        return $stringHashInHex.Replace('-', '')
    }

    return ""
}