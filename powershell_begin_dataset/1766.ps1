


Import-Module HelpersCommon




Describe "ExecutionPolicy" -Tags "CI" {

    Context "Check Get-ExecutionPolicy behavior" {
        It "Should unrestricted when not on Windows" -Skip:$IsWindows {
            Get-ExecutionPolicy | Should -Be Unrestricted
        }

        It "Should return Microsoft.Powershell.ExecutionPolicy PSObject on Windows" -Skip:($IsLinux -Or $IsMacOS) {
            Get-ExecutionPolicy | Should -BeOfType Microsoft.Powershell.ExecutionPolicy
        }
    }

    Context "Check Set-ExecutionPolicy behavior" {
        It "Should throw PlatformNotSupported when not on Windows" -Skip:$IsWindows {
            { Set-ExecutionPolicy Unrestricted } | Should -Throw "Operation is not supported on this platform."
        }

        It "Should succeed on Windows" -Skip:($IsLinux -Or $IsMacOS) {
            
            
            { Set-ExecutionPolicy -Force -Scope Process -ExecutionPolicy Unrestricted } | Should -Not -Throw
        }
    }
}











try {

    
    $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
    $IsNotSkipped = ($IsWindows -eq $true);
    $PSDefaultParameterValues["it:skip"] = !$IsNotSkipped
    $ShouldSkipTest = !$IsNotSkipped -or !(Test-CanWriteToPsHome)

    Describe "Help work with ExecutionPolicy Restricted " -Tags "Feature" {

        
        

        
        
        It "Test for Get-Help Get-Disk" -skip:(!(Test-Path (Join-Path -Path $PSHOME -ChildPath Modules\Storage\Storage.psd1)) -or $ShouldSkipTest) {

                try
                {
                    $currentExecutionPolicy = Get-ExecutionPolicy
                    Get-Module -Name Storage | Remove-Module -Force -ErrorAction Stop

                    
                    Set-ExecutionPolicy -ExecutionPolicy Restricted -Force -ErrorAction Stop
                    (Get-Help -Name Get-Disk -ErrorAction Stop).Name | Should -Be 'Get-Disk'
                }
                catch {
                    $_.ToString | Should -Be null
                }
                finally
                {
                    Set-ExecutionPolicy $currentExecutionPolicy -Force
                }
        }
    }

    Describe "Validate ExecutionPolicy cmdlets in PowerShell" -Tags "CI" {

        BeforeAll {
            if ($IsNotSkipped) {
                
                $drive = 'TestDrive:\'
                $testDirectory =  Join-Path $drive ("MultiMachineTestData\Commands\Cmdlets\Security_TestData\ExecutionPolicyTestData")
                if(Test-Path $testDirectory)
                {
                    Remove-Item -Force -Recurse $testDirectory -ErrorAction SilentlyContinue
                }
                $null = New-Item $testDirectory -ItemType Directory -Force
                $remoteTestDirectory = $testDirectory

                $InternetSignatureCorruptedScript = Join-Path -Path $remoteTestDirectory -ChildPath InternetSignatureCorruptedScript.ps1
                $InternetSignedScript = Join-Path -Path $remoteTestDirectory -ChildPath InternetSignedScript.ps1
                $InternetUnsignedScript = Join-Path -Path $remoteTestDirectory -ChildPath InternetUnsignedScript.ps1
                $IntranetSignatureCorruptedScript = Join-Path -Path $remoteTestDirectory -ChildPath IntranetSignatureCorruptedScript.ps1
                $IntranetSignedScript = Join-Path -Path $remoteTestDirectory -ChildPath IntranetSignedScript.ps1
                $IntranetUnsignedScript = Join-Path -Path $remoteTestDirectory -ChildPath IntranetUnsignedScript.ps1
                $LocalSignatureCorruptedScript = Join-Path -Path $remoteTestDirectory -ChildPath LocalSignatureCorruptedScript.ps1
                $LocalSignedScript = Join-Path -Path $remoteTestDirectory -ChildPath LocalSignedScript.ps1
                $LocalUnsignedScript = Join-Path -Path $remoteTestDirectory -ChildPath LocalUnsignedScript.ps1
                $PSHomeUnsignedModule = Join-Path -Path $PSHome -ChildPath 'Modules' -AdditionalChildPath 'LocalUnsignedModule', 'LocalUnsignedModule.psm1'
                $PSHomeUntrustedModule = Join-Path -Path $PSHome -ChildPath 'Modules' -AdditionalChildPath 'LocalUntrustedModule', 'LocalUntrustedModule.psm1'
                $TrustedSignatureCorruptedScript = Join-Path -Path $remoteTestDirectory -ChildPath TrustedSignatureCorruptedScript.ps1
                $TrustedSignedScript = Join-Path -Path $remoteTestDirectory -ChildPath TrustedSignedScript.ps1
                $TrustedUnsignedScript = Join-Path -Path $remoteTestDirectory -ChildPath TrustedUnsignedScript.ps1
                $UntrustedSignatureCorruptedScript = Join-Path -Path $remoteTestDirectory -ChildPath UntrustedSignatureCorruptedScript.ps1
                $UntrustedSignedScript = Join-Path -Path $remoteTestDirectory -ChildPath UntrustedSignedScript.ps1
                $UntrustedUnsignedScript = Join-Path -Path $remoteTestDirectory -ChildPath UntrustedUnsignedScript.ps1
                $MyComputerSignatureCorruptedScript = Join-Path -Path $remoteTestDirectory -ChildPath MyComputerSignatureCorruptedScript.ps1
                $MyComputerSignedScript = Join-Path -Path $remoteTestDirectory -ChildPath MyComputerSignedScript.ps1
                $MyComputerUnsignedScript = Join-Path -Path $remoteTestDirectory -ChildPath MyComputerUnsignedScript.ps1

                $fileType = @{
                    "Local" = -1
                    "MyComputer" = 0
                    "Intranet" = 1
                    "Trusted" = 2
                    "Internet" = 3
                    "Untrusted" = 4
                }

                $testFilesInfo = @(
                    @{
                        FilePath = $InternetSignatureCorruptedScript
                        FileType = $fileType.Internet
                        AddSignature = $true
                        Corrupted = $true
                    }
                    @{
                        FilePath = $InternetSignedScript
                        FileType = $fileType.Internet
                        AddSignature = $true
                        Corrupted = $false
                    }
                    @{
                        FilePath = $InternetUnsignedScript
                        FileType = $fileType.Internet
                        AddSignature = $false
                        Corrupted = $false
                    }
                    @{
                        FilePath = $IntranetSignatureCorruptedScript
                        FileType = $fileType.Intranet
                        AddSignature = $true
                        Corrupted = $true
                    }
                    @{
                        FilePath = $IntranetSignedScript
                        FileType = $fileType.Intranet
                        AddSignature = $true
                        Corrupted = $false
                    }
                    @{
                        FilePath = $IntranetUnsignedScript
                        FileType = $fileType.Intranet
                        AddSignature = $true
                        Corrupted = $true
                    }
                    @{
                        FilePath = $LocalSignatureCorruptedScript
                        FileType = $fileType.Local
                        AddSignature = $true
                        Corrupted = $true
                    }
                    @{
                        FilePath = $LocalSignedScript
                        FileType = $fileType.Local
                        AddSignature = $true
                        Corrupted = $false
                    }
                    @{
                        FilePath = $LocalUnsignedScript
                        FileType = $fileType.Local
                        AddSignature = $false
                        Corrupted = $false
                    }
                    @{
                        FilePath = $PSHomeUnsignedModule
                        FileType = $fileType.Local
                        AddSignature = $false
                        Corrupted = $false
                    }
                    @{
                        FilePath = $PSHomeUntrustedModule
                        FileType = $fileType.Untrusted
                        AddSignature = $false
                        Corrupted = $false
                    }
                    @{
                        FilePath = $TrustedSignatureCorruptedScript
                        FileType = $fileType.Trusted
                        AddSignature = $true
                        Corrupted = $true
                    }
                    @{
                        FilePath = $TrustedSignedScript
                        FileType = $fileType.Trusted
                        AddSignature = $true
                        Corrupted = $false
                    }
                    @{
                        FilePath = $TrustedUnsignedScript
                        FileType = $fileType.Trusted
                        AddSignature = $false
                        Corrupted = $false
                    }
                     @{
                        FilePath = $UntrustedSignatureCorruptedScript
                        FileType = $fileType.Untrusted
                        AddSignature = $true
                        Corrupted = $true
                    }
                    @{
                        FilePath = $UntrustedSignedScript
                        FileType = $fileType.Untrusted
                        AddSignature = $true
                        Corrupted = $true
                    }
                    @{
                        FilePath = $UntrustedUnsignedScript
                        FileType = $fileType.Untrusted
                        AddSignature = $true
                        Corrupted = $false
                    }
                     @{
                        FilePath = $MyComputerSignatureCorruptedScript
                        FileType = $fileType.MyComputer
                        AddSignature = $true
                        Corrupted = $true
                    }
                    @{
                        FilePath = $MyComputerSignedScript
                        FileType = $fileType.MyComputer
                        AddSignature = $true
                        Corrupted = $false
                    }
                    @{
                        FilePath = $MyComputerUnsignedScript
                        FileType = $fileType.MyComputer
                        AddSignature = $false
                        Corrupted = $false
                    }
                )

                

                function createTestFile
                {
                    param (
                    [Parameter(Mandatory)]
                    [string]
                    $FilePath,

                    [Parameter(Mandatory)]
                    [int]
                    $FileType,

                    [switch]
                    $AddSignature,

                    [switch]
                    $Corrupted
                    )

                    $folder = Split-Path -Path $FilePath
                    
                    if(!(Test-Path $folder))
                    {
                        $null = New-Item -Path $folder -ItemType Directory
                    }

                    $null = New-Item -Path $filePath -ItemType File -Force

                    $content = "`"Hello`"" + "`r`n"
                    if($AddSignature)
                    {
                        if($Corrupted)
                        {
                            
                            $content += @"




















































































"@
                        }
                        else
                        {
                            
                            $content += @"




















































































"@
                        }
                    }

                    set-content $filePath -Value $content

                    
                    
                    
                    
                    
                    
                    
                    
                    

                    if(-1 -ne $FileType)
                    {
                        $alternateStreamContent = @"
[ZoneTransfer]
ZoneId=$FileType
"@
                        Add-Content -Path $filePath -Value $alternateStreamContent -stream Zone.Identifier
                    }
                }

                foreach($fileInfo in $testFilesInfo)
                {
                    if ((Test-CanWriteToPsHome) -or (!(Test-CanWriteToPsHome) -and !$fileInfo.filePath.StartsWith($PSHOME, $true, $null)) ) {
                        createTestFile -FilePath $fileInfo.filePath -FileType $fileInfo.fileType -AddSignature:$fileInfo.AddSignature -Corrupted:$fileInfo.corrupted
                    }
                }

                
                $originalExecPolicy = Get-ExecutionPolicy
                $originalExecutionPolicy =  $originalExecPolicy

                $archiveSigned = $false
                $archivePath = Get-Module -ListAvailable Microsoft.PowerShell.Archive -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
                if($archivePath)
                {
                    $archiveFolder = Split-Path -Path $archivePath

                    
                    $script:archiveAllCert = Get-ChildItem -File -Path (Join-Path -Path $archiveFolder -ChildPath '*') -Recurse |
                        Get-AuthenticodeSignature

                    
                    $script:archiveCert = $script:archiveAllCert |
                        Where-Object { $_.status -eq 'Valid'} |
                            Select-Object -Unique -ExpandProperty SignerCertificate

                    
                    if($script:archiveCert)
                    {
                        $store = [System.Security.Cryptography.X509Certificates.X509Store]::new([System.Security.Cryptography.X509Certificates.StoreName]::TrustedPublisher,[System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser)
                        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
                        $archiveCert | ForEach-Object {
                            $store.Add($_)
                        }
                        $store.Close()
                        $archiveSigned = $true
                    }
                }
            }
        }
        AfterAll {
            if ($IsNotSkipped) {
                
                $testDirectory = $remoteTestDirectory

                Remove-Item $testDirectory -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item function:createTestFile -ErrorAction SilentlyContinue
            }
        }

        Context "Prereq: Validate that 'Microsoft.PowerShell.Archive' is signed" {
            It "'Microsoft.PowerShell.Archive' should have a signature" {
                $script:archiveAllCert | should not be null
            }
            It "'Microsoft.PowerShell.Archive' should have a valid signature" {
                $script:archiveCert | should not be null
            }
        }

        Context "Validate that 'Restricted' execution policy works on OneCore powershell" {

            BeforeAll {
                if ($IsNotSkipped) {
                    Set-ExecutionPolicy Restricted -Force -Scope Process | Out-Null
                }
            }

            AfterAll {
                if ($IsNotSkipped) {
                    Set-ExecutionPolicy $originalExecutionPolicy -Force -Scope Process | Out-Null
                }
            }

            function Test-RestrictedExecutionPolicy
            {
                param ($testScript)

                $TestTypePrefix = "Test 'Restricted' execution policy."

                It "$TestTypePrefix Running $testScript script should raise PSSecurityException" {

                    $scriptName = $testScript

                    $exception = { & $scriptName } | Should -Throw -PassThru

                    $exception.Exception | Should -BeOfType "System.Management.Automation.PSSecurityException"
                }
            }

            $testScripts = @(
                $InternetSignatureCorruptedScript
                $InternetSignedScript
                $InternetUnsignedScript
                $IntranetSignatureCorruptedScript
                $IntranetSignedScript
                $IntranetUnsignedScript
                $LocalSignatureCorruptedScript
                $localSignedScript
                $LocalUnsignedScript
                $TrustedSignatureCorruptedScript
                $TrustedSignedScript
                $UntrustedSignatureCorruptedScript
                $UntrustedSignedScript
                $UntrustedUnsignedScript
                $TrustedUnsignedScript
                $MyComputerSignatureCorruptedScript
                $MyComputerSignedScript
                $MyComputerUnsignedScript
            )

            foreach($testScript in $testScripts)
            {
                Test-RestrictedExecutionPolicy $testScript
            }
        }

        AfterAll {
            if ($IsNotSkipped) {
                
                $testDirectory = $remoteTestDirectory

                Remove-Item $testDirectory -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item function:createTestFile -ErrorAction SilentlyContinue
            }
        }
        Context "Validate that 'Unrestricted' execution policy works on OneCore powershell" {

            BeforeAll {
                if ($IsNotSkipped) {
                    Set-ExecutionPolicy Unrestricted -Force -Scope Process | Out-Null
                }
            }

            AfterAll {
                if ($IsNotSkipped) {
                    Set-ExecutionPolicy $originalExecutionPolicy -Force -Scope Process | Out-Null
                }
            }

            function Test-UnrestrictedExecutionPolicy {

                param($testScript, $expected)

                $TestTypePrefix = "Test 'Unrestricted' execution policy."

                It "$TestTypePrefix Running $testScript script should return $expected" {
                    $scriptName = $testScript

                    $result = & $scriptName

                    $result | Should -Be $expected
                }
            }

            $expected = "Hello"
            $testScripts = @(
                $IntranetSignatureCorruptedScript
                $IntranetSignedScript
                $IntranetUnsignedScript
                $LocalSignatureCorruptedScript
                $localSignedScript
                $LocalUnsignedScript
                $TrustedSignatureCorruptedScript
                $TrustedSignedScript
                $TrustedUnsignedScript
                $MyComputerSignatureCorruptedScript
                $MyComputerSignedScript
                $MyComputerUnsignedScript
            )

            foreach($testScript in $testScripts) {
                Test-UnrestrictedExecutionPolicy $testScript $expected
            }

            $expectedError = "UnauthorizedAccess,Microsoft.PowerShell.Commands.ImportModuleCommand"

            $testData = @(
                @{
                    module = "Microsoft.PowerShell.Archive"
                    error = $null
                }
            )

            if (Test-CanWriteToPsHome) {
                $testData += @(
                    @{
                        shouldMarkAsPending = $true
                        module = $PSHomeUntrustedModule
                        expectedError = $expectedError
                    }
                    @{
                        module = $PSHomeUnsignedModule
                        error = $null
                    }
                )
            }

            $TestTypePrefix = "Test 'Unrestricted' execution policy."
            It "$TestTypePrefix Importing <module> Module should throw '<error>'" -TestCases $testData  {
                param([string]$module, [string]$expectedError, [bool]$shouldMarkAsPending)

                if ($shouldMarkAsPending)
                {
                    Set-ItResult -Pending -Because "Test is unreliable"
                }

                $execPolicy = Get-ExecutionPolicy -List | Out-String

                $testScript = {Import-Module -Name $module -Force -ErrorAction Stop}
                if($expectedError)
                {
                    $testScript | Should -Throw -ErrorId $expectedError -Because "Untrusted modules should not be loaded even on unrestricted execution policy"
                }
                else
                {
                    $testScript | Should -Not -Throw -Because "Execution Policy is set as: $execPolicy"
                }
            }
        }

        Context "Validate that 'ByPass' execution policy works on OneCore powershell" {

            BeforeAll {
                if ($IsNotSkipped) {
                    Set-ExecutionPolicy Bypass -Force -Scope Process | Out-Null
                }
            }

            AfterAll {
                if ($IsNotSkipped) {
                    Set-ExecutionPolicy $originalExecutionPolicy -Force -Scope Process | Out-Null
                }
            }

            function Test-ByPassExecutionPolicy {

                param($testScript, $expected)

                $TestTypePrefix = "Test 'ByPass' execution policy."

                It "$TestTypePrefix Running $testScript script should return $expected" {
                    $scriptName = $testScript

                    $result = & $scriptName
                    return $result

                    $result | Should -Be $expected
                }
            }

            $expected = "Hello"
            $testScripts = @(
                $InternetSignatureCorruptedScript
                $InternetSignedScript
                $InternetUnsignedScript
                $IntranetSignatureCorruptedScript
                $IntranetSignedScript
                $IntranetUnsignedScript
                $LocalSignatureCorruptedScript
                $LocalSignedScript
                $LocalUnsignedScript
                $TrustedSignatureCorruptedScript
                $TrustedSignedScript
                $TrustedUnsignedScript
                $UntrustedSignatureCorruptedScript
                $UntrustedSignedScript
                $UntrustedUnSignedScript
                $MyComputerSignatureCorruptedScript
                $MyComputerSignedScript
                $MyComputerUnsignedScript
            )
            foreach($testScript in $testScripts) {
                Test-ByPassExecutionPolicy $testScript $expected
            }
        }

        Context "'RemoteSigned' execution policy works on OneCore powershell" {

            BeforeAll {
                if ($IsNotSkipped) {
                    Set-ExecutionPolicy RemoteSigned -Force -Scope Process | Out-Null
                }
            }

            AfterAll {
                if ($IsNotSkipped) {
                    Set-ExecutionPolicy $originalExecutionPolicy -Force -Scope Process
                }
            }

            function Test-RemoteSignedExecutionPolicy {

                param($testScript, $expected, $error)

                $TestTypePrefix = "Test 'RemoteSigned' execution policy."

                It "$TestTypePrefix Running $testScript script should return $expected" {
                    $scriptName=$testScript

                    $scriptResult = $null
                    $exception = $null

                    try
                    {
                        $scriptResult = & $scriptName
                    }
                    catch
                    {
                        $exception = $_
                    }

                    $errorType = $null
                    if($null -ne $exception)
                    {
                        $errorType = $exception.exception.getType()
                        $scriptResult = $null
                    }
                    $result = @{
                        "result" = $scriptResult
                        "exception" = $errorType
                    }

                    $actualResult = $result."result"
                    $actualError = $result."exception"

                    $actualResult | Should -Be $expected
                    $actualError | Should -Be $error
                }
            }
            $message = "Hello"
            $error = "System.Management.Automation.PSSecurityException"
            $testData = @(
                @{
                    testScript = $LocalUnsignedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $LocalSignatureCorruptedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $LocalSignedScript
                    expected = "Hello"
                    error = $null
                }
                @{
                    testScript = $MyComputerUnsignedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $MyComputerSignatureCorruptedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $myComputerSignedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $TrustedUnsignedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $TrustedSignatureCorruptedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $TrustedSignedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $IntranetUnsignedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $IntranetSignatureCorruptedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $IntranetSignedScript
                    expected = $message
                    error = $null
                }
                @{
                    testScript = $InternetUnsignedScript
                    expected = $null
                    error = $error
                }
                @{
                    testScript = $InternetSignatureCorruptedScript
                    expected = $null
                    error = $error
                }
                @{
                    testScript = $UntrustedUnsignedScript
                    expected = $null
                    error = $error
                }
                @{
                    testScript = $UntrustedSignatureCorruptedScript
                    expected = $null
                    error = $error
                }
            )

            foreach($testCase in $testData) {
                Test-RemoteSignedExecutionPolicy @testCase
            }
        }

        Context "Validate that 'AllSigned' execution policy works on OneCore powershell" {

            BeforeAll {
                if ($IsNotSkipped) {
                    Set-ExecutionPolicy AllSigned -Force -Scope Process
                }
            }

            AfterAll {
                if ($IsNotSkipped) {
                    Set-ExecutionPolicy $originalExecutionPolicy -Force -Scope Process
                }
            }

            $TestTypePrefix = "Test 'AllSigned' execution policy."

            $error = "UnauthorizedAccess,Microsoft.PowerShell.Commands.ImportModuleCommand"
            $testData = @(
                @{
                    module = "Microsoft.PowerShell.Archive"
                    error = $null
                }
            )

            if (Test-CanWriteToPsHome) {
                $testData += @(
                    @{
                        module = $PSHomeUntrustedModule
                        error = $error
                    }
                    @{
                        module = $PSHomeUnsignedModule
                        error = $error
                    }
                )
            }

            It "$TestTypePrefix Importing <module> Module should throw '<error>'" -TestCases $testData  {
                param([string]$module, [string]$error)
                $testScript = {Import-Module -Name $module -Force}
                if($error)
                {
                    $testScript | Should -Throw -ErrorId $error
                }
                else
                {
                    {& $testScript} | Should -Not -Throw
                }
            }

            $error = "UnauthorizedAccess"
            $pendingTestData = @(
                
                
                @{
                    testScript = $MyComputerSignedScript
                    error = $null
                }
                @{
                    testScript = $UntrustedSignedScript
                    error = $null
                }
                @{
                    testScript = $TrustedSignedScript
                    error = $null
                }
                @{
                    testScript = $LocalSignedScript
                    error = $null
                }
                @{
                    testScript = $IntranetSignedScript
                    error = $null
                }
                @{
                    testScript = $InternetSignedScript
                    error = $null
                }
            )
            It "$TestTypePrefix Running <testScript> Script should throw '<error>'" -TestCases $pendingTestData -Pending  {}

            $testData = @(
                @{
                    testScript = $InternetSignatureCorruptedScript
                    error = $error
                }
                @{
                    testScript = $InternetUnsignedScript
                    error = $error
                }
                @{
                    testScript = $IntranetSignatureCorruptedScript
                    error = $error
                }
                @{
                    testScript = $IntranetSignatureCorruptedScript
                    error = $error
                }
                @{
                    testScript = $IntranetUnsignedScript
                    error = $error
                }
                @{
                    testScript = $LocalSignatureCorruptedScript
                    error = $error
                }
                @{
                    testScript = $LocalUnsignedScript
                    error = $error
                }
                @{
                    testScript = $TrustedSignatureCorruptedScript
                    error = $error
                }
                @{
                    testScript = $TrustedUnsignedScript
                    error = $error
                }
                @{
                    testScript = $UntrustedSignatureCorruptedScript
                    error = $error
                }
                @{
                    testScript = $UntrustedUnsignedScript
                    error = $error
                }
                @{
                    testScript = $MyComputerSignatureCorruptedScript
                    error = $error
                }
                @{
                    testScript = $MyComputerUnsignedScript
                    error = $error
                }

            )
            It "$TestTypePrefix Running <testScript> Script should throw '<error>'" -TestCases $testData  {
                param([string]$testScript, [string]$error)
                $testScript | Should -Exist
                if($error)
                {
                    {& $testScript} | Should -Throw -ErrorId $error
                }
                else
                {
                    {& $testScript} | Should -Not -Throw
                }
            }
        }
    }

    function VerfiyBlockedSetExecutionPolicy
    {
        param(
            [string]
            $policyScope
        )
        { Set-ExecutionPolicy -Scope $policyScope -ExecutionPolicy Restricted } |
            Should -Throw -ErrorId "CantSetGroupPolicy,Microsoft.PowerShell.Commands.SetExecutionPolicyCommand"
    }

    function RestoreExecutionPolicy
    {
        param($originalPolicies)

        foreach ($scopedPolicy in $originalPolicies)
        {
            if (($scopedPolicy.Scope -eq "Process") -or
                ($scopedPolicy.Scope -eq "CurrentUser"))
            {
                try {
                    Set-ExecutionPolicy -Scope $scopedPolicy.Scope -ExecutionPolicy $scopedPolicy.ExecutionPolicy -Force
                }
                catch {
                    if ($_.FullyQualifiedErrorId -ne "ExecutionPolicyOverride,Microsoft.PowerShell.Commands.SetExecutionPolicyCommand")
                    {
                        
                        
                        throw $_
                    }
                }
            }
            elseif($scopedPolicy.Scope -eq "LocalMachine")
            {
                try {
                    Set-ExecutionPolicy -Scope $scopedPolicy.Scope -ExecutionPolicy $scopedPolicy.ExecutionPolicy -Force
                }
                catch {
                    if ($_.FullyQualifiedErrorId -eq "System.UnauthorizedAccessException,Microsoft.PowerShell.Commands.SetExecutionPolicyCommand")
                    {
                        
                        
                        
                        
                        
                        
                    }
                    elseif ($_.FullyQualifiedErrorId -ne "ExecutionPolicyOverride,Microsoft.PowerShell.Commands.SetExecutionPolicyCommand")
                    {
                        
                        
                        throw $_
                    }
                }
            }
        }
    }

    Describe "Validate Set-ExecutionPolicy -Scope" -Tags "CI" {

        BeforeAll {
            if ($IsNotSkipped) {
                $originalPolicies = Get-ExecutionPolicy -list
            }
        }

        AfterAll {
            if ($IsNotSkipped) {
                RestoreExecutionPolicy $originalPolicies
            }
        }

        It "-Scope MachinePolicy is not Modifiable" {
            VerfiyBlockedSetExecutionPolicy "MachinePolicy"
        }

        It "-Scope UserPolicy is not Modifiable" {
            VerfiyBlockedSetExecutionPolicy "UserPolicy"
        }

        It "-Scope Process is Settable" {
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy ByPass
            Get-ExecutionPolicy -Scope Process | Should -Be "ByPass"
        }

        It "-Scope CurrentUser is Settable" {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy ByPass
            Get-ExecutionPolicy -Scope CurrentUser | Should -Be "ByPass"
        }
    }

    Describe "Validate Set-ExecutionPolicy -Scope (Admin)" -Tags @('CI', 'RequireAdminOnWindows') {

        BeforeAll {
            if ($IsNotSkipped)
            {
                $originalPolicies = Get-ExecutionPolicy -list
            }
        }

        AfterAll {
            if ($IsNotSkipped)
            {
                RestoreExecutionPolicy $originalPolicies
            }
        }

        It '-Scope LocalMachine is Settable, but overridden' -Skip:$ShouldSkipTest {
            
            
            
            
            
            
            
            
            
            
            

            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Undefined
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted

            { Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy ByPass } |
                Should -Throw -ErrorId 'ExecutionPolicyOverride,Microsoft.PowerShell.Commands.SetExecutionPolicyCommand'

            Get-ExecutionPolicy -Scope LocalMachine | Should -Be "ByPass"
        }

        It '-Scope LocalMachine is Settable' -Skip:$ShouldSkipTest {
            
            
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Undefined
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Undefined

            Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy ByPass
            Get-ExecutionPolicy -Scope LocalMachine | Should -Be "ByPass"
        }
    }
}
finally {
    $global:PSDefaultParameterValues = $originalDefaultParameterValues
}
