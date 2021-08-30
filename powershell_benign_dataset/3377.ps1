[CmdletBinding()]
Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [string]$ReleaseDate,

    [Parameter(Mandatory = $True, Position = 1)]
    [string]$ReleaseVersion,

    [Parameter(Mandatory = $False, Position = 2)]
    [string]$PathToRepo
)


function UpdateCurrentDoc([string]$PathToCurrentDoc, [string]$ModuleVersion)
{
    
    $service = (Get-Item -Path "$PathToCurrentDoc\..\..").Name

    
    $content = Get-Content $PathToCurrentDoc -Encoding UTF8

    
    $found = $False

    
    $changes = @()

    
    for ($idx = 1; $idx -lt $content.Length; $idx++)
    {
        
        
        if ($found -and $content[$idx] -like "
        {
            $found = $False
        }
        
        
        
        elseif ($found -and $changes.Length -eq 0)
        {
            $changes += "
            $changes += ""
            $changes += $content[$idx]
        }
        
        
        elseif ($found)
        {
            $changes += $content[$idx]
        }
        
        
        
        
        if ($content[$idx - 1] -eq "
        {
            $found = $True
        }
    }

    
    
    if ($changes.Length -gt 0)
    {
        
        $end = $ModuleVersion.IndexOf(".")
        $ModuleVersion = "$($ModuleVersion.Substring(0, $end)).0.0"

        
        $newContent = New-Object string[] ($content.Length + 2)

        $buffer = 0

        
        
        for ($idx = 0; $idx -lt $content.Length; $idx++)
        {
            if ($content[$idx] -eq "
            {
                $newContent[$idx] = "
                $newContent[$idx + 1] = ""
                $newContent[$idx + 2] = "
                 
                $buffer = 2
                $idx++
            }

            $newContent[$idx + $buffer] = $content[$idx]
        }

        
        $result = $newContent -join "`r`n"
        $tempFile = Get-Item $PathToCurrentDoc

        [System.IO.File]::WriteAllText($tempFile.FullName, $result, [Text.Encoding]::UTF8)
    }

    return $changes
}


function GetModuleVersion([string]$PathToModule)
{
    return (Test-ModuleManifest -Path $PathToModule).Version.ToString()
}


function UpdateARMBreakingChangeDocs([string]$PathToServices)
{
    
    $docs = Get-ChildItem -Path $PathToServices -Recurse | Where { $_.Attributes -match "Directory" } | Where { $_.Name -eq "documentation" }
    
    
    $allChanges = @()

    
    foreach ($doc in $docs)
    {
        $currentDocPath = "$($doc.FullName)\current-breaking-changes.md"
        $upcomingDocPath = "$($doc.FullName)\upcoming-breaking-changes.md"

        $Service = Get-Item -Path "$($doc.FullName)\.."

        $serviceName = $Service.Name

        if ($serviceName -eq "AzureBackup") { $serviceName = "Backup" }
        if ($serviceName -eq "AzureBatch") { $serviceName = "Batch" }

        $modulePath = "$PathToRepo\artifacts\Debug\Az.$serviceName\Az.$serviceName.psd1"

        $moduleVersion = GetModuleVersion -PathToModule $modulePath

        
        $changes = UpdateCurrentDoc -PathToCurrentDoc $currentDocPath -ModuleVersion $moduleVersion

        
        if ($changes.Length -gt 0)
        {
            $allChanges += $changes
        }
    }

    
    return $allChanges
}


function UpdateBreakingChangeDoc([string]$PathToDoc, [string[]]$ChangesToAdd)
{
    
    $content = Get-Content -Path $PathToDoc -Encoding UTF8

    
    
    $size = $content.Length + $ChangesToAdd.Length + 2

    
    $newContent = New-Object string[] $size

    
    $newContent[0] = "
    $newContent[1] = ""

    $buffer = 2

    
    for ($idx = 0; $idx -lt $ChangesToAdd.Length; $idx++)
    {
        $newContent[$idx + $buffer] = $ChangesToAdd[$idx]
    }

    $buffer += $ChangesToAdd.Length

    
    for ($idx = 0; $idx -lt $content.Length; $idx++)
    {
        $newContent[$idx + $buffer] = $content[$idx]
    }

    
    $result = $newContent -join "`r`n"
    $tempFile = Get-Item $PathToDoc

    [System.IO.File]::WriteAllText($tempFile.FullName, $result, [Text.Encoding]::UTF8)
}




if (!$PathToRepo)
{
    $PathToRepo = "$PSScriptRoot\.."
}




$ResourceManagerChanges = UpdateARMBreakingChangeDocs -PathToServices $PathToRepo\src

$allChanges = @()


if ($ResourceManagerChanges.Length -gt 0)
{
    $allChanges += $ResourceManagerChanges
}


UpdateBreakingChangeDoc -PathToDoc $PathToDoc -ChangesToAdd $allChanges