task default -depends test

task test {
    

    Push-Location 'legacy_build_file'
    $result = invoke-psake -Docs | Out-String -Width 120
    Pop-Location

    Assert ($result -match 'alegacydefaulttask') 'Default build file should a task called alegacydefaulttask'
}
