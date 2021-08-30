
function Add-MrStartupVariable {



    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('AllUsersAllHosts', 'AllUsersCurrentHost', 'CurrentUserAllHosts', 'CurrentUserCurrentHost')]
        $Location
    )

    $Content = @'
$StartupVars = @()
$StartupVars = Get-Variable | Select-Object -ExpandProperty Name
'@

    if (-not(Test-Path -Path $profile.$Location)) {
        New-Item -Path $profile.$Location -ItemType File |
        Set-Content -Value $Content
    }
    elseif (-not(Get-Content -Path $profile.$Location |
             Select-String -SimpleMatch '$StartupVars = Get-Variable | Select-Object -ExpandProperty Name')) {
        Add-Content -Path $profile.$Location -Value "`r`n$Content"
    }
    else {
        Write-Verbose -Message "`$StartupVars already exists in '$($profile.$Location)'"
    }

}