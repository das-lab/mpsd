
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [string]$ReleaseDate,

    [Parameter(Mandatory = $True, Position = 1)]
    [string]$ReleaseVersion,

    [Parameter(Mandatory = $False, Position = 2)]
    [string]$PathToRepo
)


function UpdateServiceChangeLog([string]$PathToChangeLog, [string]$ModuleVersion)
{    
    
    $content = Get-Content $PathToChangeLog -Encoding UTF8
    
    $newContent = New-Object string[] ($content.Length + 2)
    
    $buffer = 0

    
    
    $found = $False

    
    $changeLogContent = @()

    for ($idx = 0; $idx -lt $content.Length; $idx++)
    {
        
        
        if (($content[$idx] -ne $null) -and ($content[$idx].StartsWith("
        {
            $content[$idx] = "
            $found = $True

            $newContent[$idx] = "
            $newContent[$idx + 1] = ""
            $buffer = 2
        }
        
        elseif ($content[$idx] -like "
        {
            $found = $False
        }
        
        
        elseif ($found)
        {
            $changeLogContent += $content[$idx]
        }
        
        
        $newContent[$idx + $buffer] = $content[$idx]
    }

    
    $result = $newContent -join "`r`n"
    $tempFile = Get-Item $PathToChangeLog

    [System.IO.File]::WriteAllText($tempFile.FullName, $result, [Text.Encoding]::UTF8)

    
    
    if ($found)
    {
        $changeLogContent += ""
    }

    
    return $changeLogContent
}


function UpdateModule([string]$PathToModule, [string[]]$ChangeLogContent)
{
    $releaseNotes = @()

    if ($ChangeLogContent.Length -le 1)
    {
        $releaseNotes += "Updated for common code changes"
    }
    else
    {
        $releaseNotes += $ChangeLogContent
    }


    Update-ModuleManifest -Path $PathToModule -ReleaseNotes $releaseNotes
}


function UpdateChangeLog([string]$PathToChangeLog, [string[]]$ServiceChangeLog)
{
    
    $content = Get-Content $PathToChangeLog -Encoding UTF8

    
    $size = $content.Length + $ServiceChangeLog.Length

    
    $newContent = New-Object string[] $size

    
    for ($idx = 0; $idx -lt $ServiceChangeLog.Length; $idx++)
    {
        $newContent[$idx] = $ServiceChangeLog[$idx]
    }

    
    $buffer = $ServiceChangeLog.Length

    
    for ($idx = 0; $idx -lt $content.Length; $idx++)
    {
        $newContent[$idx + $buffer] = $content[$idx]
    }

    
    $result = $newContent -join "`r`n"
    $tempFile = Get-Item $PathToChangeLog

    [System.IO.File]::WriteAllText($tempFile.FullName, $result, [Text.Encoding]::UTF8)
}


function GetModuleVersion([string]$PathToModule)
{
    $file = Get-Item $PathToModule
    Import-LocalizedData -BindingVariable ModuleMetadata -BaseDirectory $file.DirectoryName -FileName $file.Name
    return $ModuleMetadata.ModuleVersion.ToString()
}


function UpdateARMLogs([string]$PathToServices)
{
    
    $logs = Get-ChildItem -Path $PathToServices -Filter ChangeLog.md -Recurse

    
    $result = @()

    
    $result += "

    
    
    foreach ($log in $logs)
    {
        
        $Service = Get-Item -Path "$($log.FullName)\.."

        $serviceName = $Service.Name

        if ($serviceName -eq "AzureBackup") { $serviceName = "Backup" }
        if ($serviceName -eq "AzureBatch") { $serviceName = "Batch" }

        if (!(Test-Path "$PathToRepo\artifacts\Debug\Az.$serviceName\Az.$serviceName.psd1"))
        {
            continue
        }

        
        $Module = Get-Item -Path "$PathToRepo\artifacts\Debug\Az.$serviceName\Az.$serviceName.psd1"

        
        $PathToChangeLog = "$($log.FullName)"
        
        $PathToModule = "$($module.FullName)"

        
        $serviceResult = UpdateLog -PathToChangeLog $PathToChangeLog -PathToModule $PathToModule -Service $Service.Name
        
        
        if ($serviceResult.Length -gt 0)
        {
            $result += $serviceResult
        }

        Copy-Item -Path $PathToModule -Destination "$($Service.FullName)\AzureRM.$serviceName.psd1" -Force
    }

    
    return $result
}


function UpdateLog([string]$PathToChangeLog, [string]$PathToModule, [string]$Service)
{
    
    $log = Get-Item -Path $PathToChangeLog

    
    $module = Get-Item -Path $PathToModule

    
    $ModuleVersion = GetModuleVersion -PathToModule $module.FullName

    
    $changeLogContent = UpdateServiceChangeLog -PathToChangeLog $log.FullName -ModuleVersion $ModuleVersion

    
    UpdateModule -PathToModule $module.FullName -ChangeLogContent $changeLogContent

    $result = @()

    
    
    if ($changeLogContent.Length -gt 1)
    {
        $result += "* $Service"
        for ($idx = 0; $idx -lt $changeLogContent.Length - 1; $idx++)
        {
            $result += "    $($changeLogContent[$idx])"
        }
    }

    
    return $result
}




if (!$PathToRepo)
{
    $PathToRepo = "$PSScriptRoot\.." 
}

Import-Module PowerShellGet


$ResourceManagerResult = UpdateARMLogs -PathToServices $PathToRepo\src

$result = @()



if ($ResourceManagerResult.Length -gt 0)
{
    $result += $ResourceManagerResult

    UpdateModule -PathToModule "$PathToRepo\tools\AzureRM\AzureRM.psd1" -ChangeLogContent $ResourceManagerResult
}


$result += ""


$ChangeLogFile = Get-Item -Path "$PathToRepo\ChangeLog.md"


UpdateChangeLog -PathToChangeLog $ChangeLogFile.FullName -ServiceChangeLog $result