

param(
    [Parameter(HelpMessage="Artifact folder to find compliance files in.")]
    [string[]]
    $ArtifactFolder,
    [Parameter(HelpMessage="VSTS Variable to set path to complinance Files.")]
    [string]
    $VSTSVariableName
)

$compliancePath = $null
foreach($folder in $ArtifactFolder)
{
    
    Write-Host "ArtifactFolder: $folder"
    $filename = Join-Path -Path $folder -ChildPath 'symbols.zip'

    $parentName = Split-Path -Path $folder -Leaf

    
    
    
    if ($parentName -match 'x64' -or $parentName -match 'amd64')
    {
        $name = 'x64'
    }
    elseif ($parentName -match 'x86') {
        $name = 'x86'
    }
    elseif ($parentName -match 'fxdependent') {
        $name = 'fxd'
    }
    else
    {
        throw "$parentName could not be classified as x86 or x64"
    }

    
    if (!(Test-Path $filename))
    {
        throw "symbols.zip for $VSTSVariableName does not exist"
    }

    
    if (!$compliancePath)
    {
        $parent = Split-Path -Path $folder
        $compliancePath = Join-Path -Path $parent -ChildPath 'compliance'
    }

    
    $unzipPath = Join-Path -Path $compliancePath -ChildPath $name
    Write-Host "Symbols-zip: $filename ; unzipPath: $unzipPath"
    Expand-Archive -Path $fileName -DestinationPath $unzipPath
}


Write-Host "
