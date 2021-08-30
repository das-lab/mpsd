$vstsVariables = @{
    PSES_BRANCH = 'master'
}


foreach ($var in $vstsVariables.Keys)
{
    
    if (Get-Item "env:$var" -ErrorAction Ignore)
    {
        continue
    }

    $val = $vstsVariables[$var]
    Write-Host "Setting var '$var' to value '$val'"
    Write-Host "
}
