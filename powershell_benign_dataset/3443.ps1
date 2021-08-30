

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [String]$BuildArtifactsPath,
    [Parameter(Mandatory=$True, Position=1)]
    [String]$PSVersion,
    [Parameter(Mandatory=$True, Position=2)]
    [String]$CodePlexUsername,
    [Parameter(Mandatory=$True, Position=3)]
    [String]$CodePlexFork,
    [Parameter(Mandatory=$True, Position=4)]
    [String]$ReleaseDate,
    [Parameter(Mandatory=$True, Position=5)]
    [String]$PathToShared
)


function Get-ProductCode
{
    param(
        [Parameter(Mandatory=$True)]
        [System.IO.FileInfo]$Path
    )

    try
    {
        
        $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
        $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0))
        $Query = "SELECT Value FROM Property WHERE Property = 'ProductCode'"
        $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
        $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
        $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
 
        
        $MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
        $View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)           
        $MSIDatabase = $null
        $View = $null
 
        
        return $Value
    } 
    catch
    {
        Write-Warning -Message $_.Exception.Message ; break
    }
}





Rename-Item "$BuildArtifactsPath\signed\AzurePowerShell.msi" "azure-powershell.$PSVersion.msi"


$msiFile = Get-Item "$BuildArtifactsPath\signed\azure-powershell.$PSVersion.msi"
$ProductCode = ([string](Get-ProductCode $msiFile)).Trim()






$fork = "https://git01.codeplex.com/forks/$CodePlexUsername/$CodePlexFork"
git clone $fork $CodePlexFork

cd $CodePlexFork


$date = Get-Date -Format u
$branch = $date.Substring(0, $date.Length - 4).Replace(":", "-").Replace(" ", "T");
git checkout -b $branch





cd "Src\azuresdk\AzurePS"


$content = Get-Content "DH_AzurePS.xml"


$newContentLength = $content.Length + 3
$newContent = New-Object string[] $newContentLength

$VSFeedSeen = $False
$PSGetSeen = $False
$buffer = 0

for ($idx = 0; $idx -lt $content.Length; $idx++)
{
    
    if ($content[$idx] -like "*VSFeed*")
    {
        $VSFeedSeen = $True
    }

    
    if ($content[$idx] -like "*PowerShellGet*")
    {
        $PSGetSeen = $True
    }

    
    
    if ($VSFeedSeen -and $content[$idx] -like "*</or>*")
    {
        $newContent[$idx] =     "      <discoveryHint>"
        $newContent[$idx + 1] = "        <msiProductCode>$ProductCode</msiProductCode>"
        $newContent[$idx + 2] = "      </discoveryHint>"        

        
        $buffer = 3

        
        $VSFeedSeen = $False
    }

    
    if ($PSGetSeen -and $content[$idx] -like "*msiProductCode*")
    {
        $content[$idx] = "   <msiProductCode>$ProductCode</msiProductCode>"

        
        $PSGetSeen = $False
    }

    $newContent[$idx + $buffer] = $content[$idx]
}


$result = $newContent -join "`r`n"
$tempFile = Get-Item "DH_AzurePS.xml"

[System.IO.File]::WriteAllText($tempFile.FullName, $result)






$content = Get-Content "WebProductList_AzurePS.xml"

$PSGetSeen = $false

for ($idx = 0; $idx -lt $content.Length; $idx++)
{
    
    if ($content[$idx] -contains "  <productId>WindowsAzurePowershellGet</productId>")
    {
        $PSGetSeen = $true
    }

    
    if ($PSGetSeen)
    {
        if ($content[$idx] -like "*<version>*")
        {
            $content[$idx] = "  <version>$PSVersion</version>"
        }

        if ($content[$idx] -like "*<published>*")
        {
            $content[$idx] = "  <published>$($ReleaseDate)T12:00:00Z</published>"
        }

        if ($content[$idx] -like "*<updated>*")
        {
            $content[$idx] = "  <updated>$($ReleaseDate)T12:00:00Z</updated>"
        }

        if ($content[$idx] -like "*<trackingURL>*")
        {
            $content[$idx] = "        <trackingURL>http://www.microsoft.com/web/handlers/webpi.ashx?command=incrementproddownloadcount&amp;prodid=WindowsAzurePowershell&amp;version=$PSVersion&amp;prodlang=en</trackingURL>"
        }

        if ($content[$idx] -like "*</entry>*")
        {
            $PSGetSeen = $False
        }
    }

}


$result = $content -join "`r`n"
$tempFile = Get-Item "WebProductList_AzurePS.xml"

[System.IO.File]::WriteAllText($tempFile.FullName, $result)






$entryName = "$($ReleaseDate.Replace("-", "_"))_PowerShell"


if (Test-Path "$PathToShared\$entryName")
{
    $id = 1
    
    
    while (Test-Path "$PathToShared\$($entryName)_RC$id")
    {
        $id++
    }

    
    Rename-Item "$PathToShared\$entryName" "$($entryName)_RC$id"
}


New-Item "$PathToShared\$entryName" -Type Directory > $null
New-Item "$PathToShared\$entryName\pkgs" -Type Directory > $null


Copy-Item "$PathToShared\PSReleaseDrop\*" "$PathToShared\$entryName" -Recurse


Copy-Item $msiFile.FullName "$PathToShared\$entryName"
Copy-Item "$BuildArtifactsPath\artifacts\*.nupkg" "$PathToShared\$entryName\pkgs"





cd ../../../Tools

.\Build.cmd

cd ../bin

Copy-Item .\* $PathToShared\$entryName





cd ..

git add .

git commit -m "Update DH_AzurePS.xml and WebProductList_AzurePS.xml"

git push origin $branch