

param(
    [string] $SigningXmlPath = (Join-Path -Path $PSScriptRoot  -ChildPath 'signing.xml'),
    [switch] $SkipPwshExe
)


if ($SkipPwshExe) {
    
    $xmlContent = Get-Content $SigningXmlPath | Where-Object { $_ -notmatch '__INPATHROOT__\\pwsh.exe' }
} else {
    
    $xmlContent = Get-Content $signingXmlPath | Where-Object { $_ -notmatch '__INPATHROOT__\\Microsoft.PowerShell.GlobalTool.Shim.dll' }
}


$signingXml = [xml] $xmlContent





$signTypes = @{}
Get-ChildItem -Path env:/*SignType | ForEach-Object -Process {
    $signType = $_.Name.ToUpperInvariant().Replace('SIGNTYPE','')
    Write-Host "Found SigningType $signType with value $($_.value)"
    $signTypes[$signType] = $_.Value
}


$signingXml.SignConfigXML.job | ForEach-Object -Process {
    
    $_.file | ForEach-Object -Process {
        
        $signType = $_.SignType.ToUpperInvariant()
        if($signTypes.ContainsKey($signType))
        {
            $newSignType = $signTypes[$signType]
            Write-Host "Updating $($_.src) to $newSignType"
            $_.signType = $newSignType
        }
    }
}

$signingXml.Save($signingXmlPath)
