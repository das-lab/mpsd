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
