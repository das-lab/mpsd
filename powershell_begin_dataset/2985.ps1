
function New-TestDrive ([Switch]$PassThru, [string] $Path) {
    if ($Path -notmatch '\S') {
        $directory = New-RandomTempDirectory
    }
    else {
        if (-not (& $SafeCommands['Test-Path'] -Path $Path)) {
            $null = & $SafeCommands['New-Item'] -ItemType Container -Path $Path
        }

        $directory = & $SafeCommands['Get-Item'] $Path
    }

    $DriveName = "TestDrive"

    
    if ( -not (& $SafeCommands['Test-Path'] "${DriveName}:\") ) {
        $null = & $SafeCommands['New-PSDrive'] -Name $DriveName -PSProvider FileSystem -Root $directory -Scope Global -Description "Pester test drive"
    }

    
    if (-not (& $SafeCommands['Test-Path'] "Variable:Global:$DriveName")) {
        & $SafeCommands['New-Variable'] -Name $DriveName -Scope Global -Value $directory
    }

    if ( $PassThru ) {
        & $SafeCommands['Get-PSDrive'] -Name $DriveName
    }
}


function Clear-TestDrive ([String[]]$Exclude) {
    $Path = (& $SafeCommands['Get-PSDrive'] -Name TestDrive).Root
    if (& $SafeCommands['Test-Path'] -Path $Path ) {

        Remove-TestDriveSymbolicLinks -Path $Path

        
        & $SafeCommands['Get-ChildItem'] -Recurse -Path $Path |
            & $SafeCommands['Sort-Object'] -Descending  -Property "FullName" |
            & $SafeCommands['Where-Object'] { $Exclude -NotContains $_.FullName } |
            & $SafeCommands['Remove-Item'] -Force -Recurse

    }
}

function New-RandomTempDirectory {
    do {
        $tempPath = Get-TempDirectory
        $Path = & $SafeCommands['Join-Path'] -Path $tempPath -ChildPath ([Guid]::NewGuid())
    } until (-not (& $SafeCommands['Test-Path'] -Path $Path ))

    & $SafeCommands['New-Item'] -ItemType Container -Path $Path
}

function Get-TestDriveItem {
    

    
    param ([string]$Path)

    & $SafeCommands['Write-Warning'] -Message "The function Get-TestDriveItem is deprecated since Pester 4.0.0 and will be removed from Pester 5.0.0."

    Assert-DescribeInProgress -CommandName Get-TestDriveItem
    & $SafeCommands['Get-Item'] $(& $SafeCommands['Join-Path'] $TestDrive $Path )
}

function Get-TestDriveChildItem {
    $Path = (& $SafeCommands['Get-PSDrive'] -Name TestDrive).Root
    if (& $SafeCommands['Test-Path'] -Path $Path ) {
        & $SafeCommands['Get-ChildItem'] -Recurse -Path $Path
    }
}

function Remove-TestDriveSymbolicLinks ([String] $Path) {

    
    
    

    
    
    

    
    
    if ( (GetPesterPSVersion) -ge 6) {
        return
    }

    
    $reparsePoint = [System.IO.FileAttributes]::ReparsePoint
    & $SafeCommands["Get-ChildItem"] -Recurse -Path $Path |
        where-object { ($_.Attributes -band $reparsePoint) -eq $reparsePoint } |
        foreach-object { $_.Delete() }
}

function Remove-TestDrive {

    $DriveName = "TestDrive"
    $Drive = & $SafeCommands['Get-PSDrive'] -Name $DriveName -ErrorAction $script:IgnoreErrorPreference
    $Path = ($Drive).Root


    if ($pwd -like "$DriveName*" ) {
        
        
        & $SafeCommands['Write-Warning'] -Message "Your current path is set to ${pwd}:. You should leave ${DriveName}:\ before leaving Describe."
    }

    if ( $Drive ) {
        $Drive | & $SafeCommands['Remove-PSDrive'] -Force 
    }

    Remove-TestDriveSymbolicLinks -Path $Path

    if (& $SafeCommands['Test-Path'] -Path $Path) {
        & $SafeCommands['Remove-Item'] -Path $Path -Force -Recurse
    }

    if (& $SafeCommands['Get-Variable'] -Name $DriveName -Scope Global -ErrorAction $script:IgnoreErrorPreference) {
        & $SafeCommands['Remove-Variable'] -Scope Global -Name $DriveName -Force
    }
}

function Setup {
    
    param(
        [switch]$Dir,
        [switch]$File,
        $Path,
        $Content = "",
        [switch]$PassThru
    )

    Assert-DescribeInProgress -CommandName Setup

    $TestDriveName = & $SafeCommands['Get-PSDrive'] TestDrive |
        & $SafeCommands['Select-Object'] -ExpandProperty Root

    if ($Dir) {
        $item = & $SafeCommands['New-Item'] -Name $Path -Path "${TestDriveName}\" -Type Container -Force
    }
    if ($File) {
        $item = $Content | & $SafeCommands['New-Item'] -Name $Path -Path "${TestDriveName}\" -Type File -Force
    }

    if ($PassThru) {
        return $item
    }
}
