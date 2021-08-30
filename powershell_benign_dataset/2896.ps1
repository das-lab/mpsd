task default -depends test

task test {
    

    Push-Location 'default_build_file'
    $result = invoke-psake -Docs | Out-String -Width 120
    Pop-Location

    Assert ($result -match 'adefaulttask') 'Default build file should a task called adefaulttask'
}
