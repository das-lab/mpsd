
$ModuleBasePath = Split-Path $MyInvocation.MyCommand.Path -Parent





$invokeErrors = New-Object System.Collections.ArrayList 256



function Invoke-NullCoalescing {
    $result = $null
    foreach ($arg in $args) {
        if ($arg -is [ScriptBlock]) {
            $result = & $arg
        }
        else {
            $result = $arg
        }
        if ($result) { break }
    }
    $result
}

Set-Alias ?? Invoke-NullCoalescing -Force

function Invoke-Utf8ConsoleCommand([ScriptBlock]$cmd) {
    $currentEncoding = [Console]::OutputEncoding
    $errorCount = $global:Error.Count
    try {
        
        
        $ErrorActionPreference = 'Continue'
        if ($currentEncoding.IsSingleByte) {
            [Console]::OutputEncoding = [Text.Encoding]::UTF8
        }
        & $cmd
    }
    finally {
        if ($currentEncoding.IsSingleByte) {
            [Console]::OutputEncoding = $currentEncoding
        }

        
        if ($global:Error.Count -gt $errorCount) {
            $numNewErrors = $global:Error.Count - $errorCount
            $invokeErrors.InsertRange(0, $global:Error.GetRange(0, $numNewErrors))
            if ($invokeErrors.Count -gt 256) {
                $invokeErrors.RemoveRange(256, ($invokeErrors.Count - 256))
            }
            $global:Error.RemoveRange(0, $numNewErrors)
        }
    }
}

function Test-Administrator {
    
    
    if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
        $currentUser = [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    
    return 0 -eq (id -u)
}


function Add-PoshGitToProfile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]
        $AllHosts,

        [Parameter()]
        [switch]
        $AllUsers,

        [Parameter()]
        [switch]
        $Force,

        [Parameter(ValueFromRemainingArguments)]
        [psobject[]]
        $TestParams
    )

    if ($AllUsers -and !(Test-Administrator)) {
        throw 'Adding posh-git to an AllUsers profile requires an elevated host.'
    }

    $underTest = $false

    $profileName = $(if ($AllUsers) { 'AllUsers' } else { 'CurrentUser' }) `
                 + $(if ($AllHosts) { 'AllHosts' } else { 'CurrentHost' })
    Write-Verbose "`$profileName = '$profileName'"

    $profilePath = $PROFILE.$profileName
    Write-Verbose "`$profilePath = '$profilePath'"

    
    if (($TestParams.Count -gt 0) -and ($TestParams[0] -is [string])) {
        $profilePath = [string]$TestParams[0]
        $underTest = $true
        if ($TestParams.Count -gt 1) {
            $ModuleBasePath = [string]$TestParams[1]
        }
    }

    if (!$profilePath) { $profilePath = $PROFILE }

    if (!$Force) {
        
        
        $importedInProfile = Test-PoshGitImportedInScript $profilePath
        if (!$importedInProfile -and !$underTest) {
            $importedInProfile = Test-PoshGitImportedInScript $PROFILE
        }
        if (!$importedInProfile -and !$underTest) {
            $importedInProfile = Test-PoshGitImportedInScript $PROFILE.CurrentUserCurrentHost
        }
        if (!$importedInProfile -and !$underTest) {
            $importedInProfile = Test-PoshGitImportedInScript $PROFILE.CurrentUserAllHosts
        }
        if (!$importedInProfile -and !$underTest) {
            $importedInProfile = Test-PoshGitImportedInScript $PROFILE.AllUsersCurrentHost
        }
        if (!$importedInProfile -and !$underTest) {
            $importedInProfile = Test-PoshGitImportedInScript $PROFILE.AllUsersAllHosts
        }

        if ($importedInProfile) {
            Write-Warning "Skipping add of posh-git import to file '$profilePath'."
            Write-Warning "posh-git appears to already be imported in one of your profile scripts."
            Write-Warning "If you want to force the add, use the -Force parameter."
            return
        }
    }

    if (!$profilePath) {
        Write-Warning "Skipping add of posh-git import to profile; no profile found."
        Write-Verbose "`$PROFILE              = '$PROFILE'"
        Write-Verbose "CurrentUserCurrentHost = '$($PROFILE.CurrentUserCurrentHost)'"
        Write-Verbose "CurrentUserAllHosts    = '$($PROFILE.CurrentUserAllHosts)'"
        Write-Verbose "AllUsersCurrentHost    = '$($PROFILE.AllUsersCurrentHost)'"
        Write-Verbose "AllUsersAllHosts       = '$($PROFILE.AllUsersAllHosts)'"
        return
    }

    
    if (Test-Path -LiteralPath $profilePath) {
        if (!(Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue))
        {
            Write-Verbose "Platform doesn't support script signing, skipping test for signed profile."
        }
        else {
            $sig = Get-AuthenticodeSignature $profilePath
            if ($null -ne $sig.SignerCertificate) {
                Write-Warning "Skipping add of posh-git import to profile; '$profilePath' appears to be signed."
                Write-Warning "Add the command 'Import-Module posh-git' to your profile and resign it."
                return
            }
        }
    }

    
    if (Test-InPSModulePath $ModuleBasePath) {
        $profileContent = "`nImport-Module posh-git"
    }
    else {
        $modulePath = Join-Path $ModuleBasePath posh-git.psd1
        $profileContent = "`nImport-Module '$modulePath'"
    }

    
    $profileDir = Split-Path $profilePath -Parent
    if (!(Test-Path -LiteralPath $profileDir)) {
        if ($PSCmdlet.ShouldProcess($profileDir, "Create current user PowerShell profile directory")) {
            New-Item $profileDir -ItemType Directory -Force -Verbose:$VerbosePreference > $null
        }
    }

    if ($PSCmdlet.ShouldProcess($profilePath, "Add 'Import-Module posh-git' to profile")) {
        Add-Content -LiteralPath $profilePath -Value $profileContent -Encoding UTF8
    }
}


function Get-FileEncoding($Path) {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $bytes = [byte[]](Get-Content $Path -AsByteStream -ReadCount 4 -TotalCount 4)
    }
    else {
        $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)
    }

    if (!$bytes) { return 'utf8' }

    switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3]) {
        '^efbbbf'   { return 'utf8' }
        '^2b2f76'   { return 'utf7' }
        '^fffe'     { return 'unicode' }
        '^feff'     { return 'bigendianunicode' }
        '^0000feff' { return 'utf32' }
        default     { return 'ascii' }
    }
}


function Get-PathStringComparison {
    
    if (($PSVersionTable.PSVersion.Major -ge 6) -and $IsLinux) {
        [System.StringComparison]::Ordinal
    }
    else {
        [System.StringComparison]::OrdinalIgnoreCase
    }
}

function Get-PromptPath {
    $settings = $global:GitPromptSettings
    $abbrevHomeDir = $settings -and $settings.DefaultPromptAbbreviateHomeDirectory

    
    
    
    
    $pathInfo = $ExecutionContext.SessionState.Path.CurrentLocation
    $currentPath = if ($pathInfo.Drive) { $pathInfo.Path } else { $pathInfo.ProviderPath }

    $stringComparison = Get-PathStringComparison

    
    if ($abbrevHomeDir -and $currentPath -and !$currentPath.Equals($Home, $stringComparison) -and
        $currentPath.StartsWith($Home, $stringComparison)) {

        $currentPath = "~" + $currentPath.SubString($Home.Length)
    }

    return $currentPath
}


function Get-PromptConnectionInfo($Format = '[{1}@{0}]: ') {
    if ($GitPromptSettings -and (Test-Path Env:SSH_CONNECTION)) {
        $MachineName = [System.Environment]::MachineName
        $UserName = [System.Environment]::UserName
        $Format -f $MachineName,$UserName
    }
}

function Get-PSModulePath {
    $modulePaths = $Env:PSModulePath -split ';'
    $modulePaths
}

function Test-InPSModulePath {
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $Path
    )

    $modulePaths = Get-PSModulePath
    if (!$modulePaths) { return $false }

    $pathStringComparison = Get-PathStringComparison
    $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $inModulePath = @($modulePaths | Where-Object { $Path.StartsWith($_.TrimEnd([System.IO.Path]::DirectorySeparatorChar), $pathStringComparison) }).Count -gt 0

    if ($inModulePath -and ('src' -eq (Split-Path $Path -Leaf))) {
        Write-Warning 'posh-git repository structure is incompatible with %PSModulePath%.'
        Write-Warning 'Importing with absolute path instead.'
        return $false
    }

    $inModulePath
}

function Test-PoshGitImportedInScript {
    param (
        [Parameter(Position=0)]
        [string]
        $Path
    )

    if (!$Path -or !(Test-Path -LiteralPath $Path)) {
        return $false
    }

    $match = (@(Get-Content $Path -ErrorAction SilentlyContinue) -match 'posh-git').Count -gt 0
    if ($match) { Write-Verbose "posh-git found in '$Path'" }
    $match
}

function dbg($Message, [Diagnostics.Stopwatch]$Stopwatch) {
    if ($Stopwatch) {
        Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds,$Message) -Verbose 
    }
}
