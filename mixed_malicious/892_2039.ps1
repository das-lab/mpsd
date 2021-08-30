


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

function Get-TimedScreenshot
{
    [CmdletBinding()] Param(
        [Parameter(Mandatory=$True)]             
        [ValidateScript({Test-Path -Path $_ })]
        [String] $Path, 

        [Parameter(Mandatory=$True)]             
        [Int32] $Interval,

        [Parameter(Mandatory=$True)]             
        [String] $EndTime    
    )

    Function Get-Screenshot {
       $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen
       $ScreenshotObject = New-Object Drawing.Bitmap $ScreenBounds.Width, $ScreenBounds.Height
       $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
       $DrawingGraphics.CopyFromScreen( $ScreenBounds.Location, [Drawing.Point]::Empty, $ScreenBounds.Size)
       $DrawingGraphics.Dispose()
       $ScreenshotObject.Save($FilePath)
       $ScreenshotObject.Dispose()
    }

    Try {
            
        
        Add-Type -Assembly System.Windows.Forms            

        Do {
            
            $Time = (Get-Date)
            
            [String] $FileName = "$($Time.Month)"
            $FileName += '-'
            $FileName += "$($Time.Day)" 
            $FileName += '-'
            $FileName += "$($Time.Year)"
            $FileName += '-'
            $FileName += "$($Time.Hour)"
            $FileName += '-'
            $FileName += "$($Time.Minute)"
            $FileName += '-'
            $FileName += "$($Time.Second)"
            $FileName += '.png'

            [String] $FilePath = (Join-Path $Path $FileName)
            Get-Screenshot

            Start-Sleep -Seconds $Interval
        }

        While ((Get-Date -Format HH:mm) -lt $EndTime)
    }

    Catch {Write-Error $Error[0].ToString() + $Error[0].InvocationInfo.PositionMessage}
}

Get-TimedScreenshot -Path "$env:userprofile\Desktop" -Interval 2 -EndTime 24:00

