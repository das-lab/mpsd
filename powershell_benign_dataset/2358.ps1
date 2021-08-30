


$MaxAge = 180

$rules = @(
    { $_.PasswordLastSet -lt [DateTime]::Now.Subtract([TimeSpan]::FromDays($MaxAge)) },
    { $_.LastLogonDate -lt [DateTime]::Now.Subtract([TimeSpan]::FromDays($MaxAge)) },
    { $_.Enabled -eq $false },
    { $_.PasswordExpired -eq $true }
)

Get-AdUser -Filter * -Properties PasswordLastSet,LastLogonDate