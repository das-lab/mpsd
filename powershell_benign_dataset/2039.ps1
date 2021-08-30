


Describe "Assembly.LoadFrom Validation Test" -Tags "CI" {
    BeforeAll {
        $ConsumerCode = @'
            using System;
            using Assembly.Bar;

            namespace Assembly.Foo
            {
                public class Consumer
                {
                    public static string GetName()
                    {
                        return Provider.GetProviderName();
                    }
                }
            }
'@
        $ProviderCode = @'
            using System;

            namespace Assembly.Bar
            {
                public class Provider
                {
                    public static string GetProviderName()
                    {
                        return "Assembly.Bar.Provider";
                    }
                }
            }
'@

        
        
        $TempPath = [System.IO.Path]::GetTempFileName()
        if (Test-Path $TempPath) { Remove-Item -Path $TempPath -Force -Recurse }
        New-Item -Path $TempPath -ItemType Directory -Force > $null

        $ConsumerAssembly = Join-Path -Path $TempPath -ChildPath "Consumer.dll"
        $ProviderAssembly = Join-Path -Path $TempPath -ChildPath "Provider.dll"

        Add-Type -TypeDefinition $ProviderCode -OutputType Library -OutputAssembly $ProviderAssembly
        Add-Type -TypeDefinition $ConsumerCode -OutputType Library -OutputAssembly $ConsumerAssembly -ReferencedAssemblies $ProviderAssembly

        
        
        $AssemblyName = [System.Reflection.AssemblyName]::GetAssemblyName($ProviderAssembly)
        $ProviderAssemblyNewPath = Join-Path -Path $TempPath -ChildPath "$($AssemblyName.Name).dll"
        Move-Item -Path $ProviderAssembly -Destination $ProviderAssemblyNewPath
    }

    It "Assembly.LoadFrom should automatically load the implicit referenced assembly from the same folder" {
        
        { [Assembly.Foo.Consumer] } | Should -Throw -ErrorId "TypeNotFound"
        { [Assembly.Bar.Provider] } | Should -Throw -ErrorId "TypeNotFound"

        
        [System.Reflection.Assembly]::LoadFrom($ConsumerAssembly) > $null
        [Assembly.Foo.Consumer].FullName | Should -Be "Assembly.Foo.Consumer"
        
        { [Assembly.Bar.Provider] } | Should -Throw -ErrorId "TypeNotFound"

        
        [Assembly.Foo.Consumer]::GetName() | Should -BeExactly "Assembly.Bar.Provider"
        
        [Assembly.Bar.Provider].FullName | Should -BeExactly "Assembly.Bar.Provider"
    }
}
