task default -depends test

task test {
    

    Push-Location 'missing_build_file'
    $result = invoke-psake -Docs | Out-String
    Pop-Location

    Assert ($result -match 'adefaulttask') 'Default build file should a task called adefaulttask'
}