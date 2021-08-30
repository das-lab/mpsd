function Get-PE
{


    [CmdletBinding(DefaultParameterSetName = 'OnDisk')] Param(
        [Parameter(Mandatory = $True,
                   ParameterSetName = 'OnDisk',
                   Position = 0,
                   ValueFromPipelineByPropertyName = $True,
                   ValueFromPipeline = $True)]
        [Alias('FullName')]
        [String[]]
        $FilePath,

        [Parameter(ParameterSetName = 'InMemory',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [Alias('Id')]
        [ValidateScript({Get-Process -Id $_})]
        [Int32]
        $ProcessID,

        [Parameter(ParameterSetName = 'InMemory',
                   Position = 1)]
        [IntPtr]
        $ModuleBaseAddress,

        [Parameter(ParameterSetName = 'InMemory',
                   Position = 2,
                   ValueFromPipelineByPropertyName = $True)]
        [Alias('MainModule')]
        [Alias('Modules')]
        [Diagnostics.ProcessModule[]]
        $Module,
        
        [Parameter(ParameterSetName = 'InMemory')]
        [String]
        [ValidateScript({[IO.Directory]::Exists((Resolve-Path $_).Path)})]
        $DumpDirectory,

        [Parameter(Mandatory = $True,
                   ParameterSetName = 'ByteArray',
                   Position = 0,
                   ValueFromPipeline = $True)]
        [Byte[]]
        $FileBytes,

        [Parameter()]
        [Switch]
        $IgnoreMalformedPE
    )

    BEGIN
    {
        function local:Test-Pointer
        {
        

            Param (
                [Parameter(Position = 0, Mandatory = $True)] [Int64] $Ptr,
                [Parameter(Position = 1, Mandatory = $True)] [Int64] $PtrDerefSize,
                [Parameter(Position = 2, Mandatory = $True)] [Int64] $PValidMem,
                [Parameter(Position = 3, Mandatory = $True)] [Int64] $ValidMemSize
            )

            $EndPtr = $Ptr + $PtrDerefSize
            $EndValidMem = $PValidMem + $ValidMemSize
            if (($Ptr -ge $PValidMem)    -and
                ($EndPtr -ge $PValidMem) -and
                ($Ptr -le $EndValidMem)  -and
                ($EndPtr -le $EndValidMem)) {
                return $True
            }

            return $False
        }

        
        function local:Convert-RVAToFileOffset([IntPtr] $Rva, $SectionHeaders, $PEBase) {
            foreach ($Section in $SectionHeaders) {
                if ((($Rva.ToInt64() - $PEBase.ToInt64()) -ge $Section.VirtualAddress) -and
                    (($Rva.ToInt64() - $PEBase.ToInt64()) -lt ($Section.VirtualAddress + $Section.VirtualSize))) {
                    return [IntPtr] ($Rva.ToInt64() - ($Section.VirtualAddress - $Section.PointerToRawData))
                }
            }
        
            
            return $Rva
        }

        
        $Mod = New-InMemoryModule -ModuleName PEParser

        $ImageDosSignature = psenum $Mod PE.IMAGE_DOS_SIGNATURE UInt16 @{
            DOS_SIGNATURE =    0x5A4D
            OS2_SIGNATURE =    0x454E
            OS2_SIGNATURE_LE = 0x454C
            VXD_SIGNATURE =    0x454C
        }

        $ImageFileMachine = psenum $Mod PE.IMAGE_FILE_MACHINE UInt16 @{
            UNKNOWN =   0x0000
            I386 =      0x014C 
            R3000 =     0x0162 
            R4000 =     0x0166 
            R10000 =    0x0168 
            WCEMIPSV2 = 0x0169 
            ALPHA =     0x0184 
            SH3 =       0x01A2 
            SH3DSP =    0x01A3
            SH3E =      0x01A4 
            SH4 =       0x01A6 
            SH5 =       0x01A8 
            ARM =       0x01C0 
            THUMB =     0x01C2
            ARMNT =     0x01C4 
            AM33 =      0x01D3
            POWERPC =   0x01F0 
            POWERPCFP = 0x01F1
            IA64 =      0x0200 
            MIPS16 =    0x0266 
            ALPHA64 =   0x0284 
            MIPSFPU =   0x0366 
            MIPSFPU16 = 0x0466 
            TRICORE =   0x0520 
            CEF =       0x0CEF
            EBC =       0x0EBC 
            AMD64 =     0x8664 
            M32R =      0x9041 
            CEE =       0xC0EE
        }

        $ImageFileCharacteristics = psenum $Mod PE.IMAGE_FILE_CHARACTERISTICS UInt16 @{
            IMAGE_RELOCS_STRIPPED =         0x0001 
            IMAGE_EXECUTABLE_IMAGE =        0x0002 
            IMAGE_LINE_NUMS_STRIPPED =      0x0004 
            IMAGE_LOCAL_SYMS_STRIPPED =     0x0008 
            IMAGE_AGGRESIVE_WS_TRIM =       0x0010 
            IMAGE_LARGE_ADDRESS_AWARE =     0x0020 
            IMAGE_REVERSED_LO =             0x0080 
            IMAGE_32BIT_MACHINE =           0x0100 
            IMAGE_DEBUG_STRIPPED =          0x0200 
            IMAGE_REMOVABLE_RUN_FROM_SWAP = 0x0400 
            IMAGE_NET_RUN_FROM_SWAP =       0x0800 
            IMAGE_SYSTEM =                  0x1000 
            IMAGE_DLL =                     0x2000 
            IMAGE_UP_SYSTEM_ONLY =          0x4000 
            IMAGE_REVERSED_HI =             0x8000 
        } -Bitfield

        $ImageHdrMagic = psenum $Mod PE.IMAGE_NT_OPTIONAL_HDR_MAGIC UInt16 @{
            PE32 = 0x010B
            PE64 = 0x020B
        }

        $ImageNTSig = psenum $Mod PE.IMAGE_NT_SIGNATURE UInt32 @{
            VALID_PE_SIGNATURE = 0x00004550
        }

        $ImageSubsystem = psenum $Mod PE.IMAGE_SUBSYSTEM UInt16 @{
            UNKNOWN =                  0
            NATIVE =                   1 
            WINDOWS_GUI =              2 
            WINDOWS_CUI =              3 
            OS2_CUI =                  5 
            POSIX_CUI =                7 
            NATIVE_WINDOWS =           8 
            WINDOWS_CE_GUI =           9 
            EFI_APPLICATION =          10
            EFI_BOOT_SERVICE_DRIVER =  11
            EFI_RUNTIME_DRIVER =       12
            EFI_ROM =                  13
            XBOX =                     14
            WINDOWS_BOOT_APPLICATION = 16
        }

        $ImageDllCharacteristics = psenum $Mod PE.IMAGE_DLLCHARACTERISTICS UInt16 @{
            HIGH_ENTROPY_VA =       0x0020 
            DYNAMIC_BASE =          0x0040 
            FORCE_INTEGRITY =       0x0080 
            NX_COMPAT =             0x0100 
            NO_ISOLATION =          0x0200 
            NO_SEH =                0x0400 
            NO_BIND =               0x0800 
            WDM_DRIVER =            0x2000 
            TERMINAL_SERVER_AWARE = 0x8000
        } -Bitfield

        $ImageScn = psenum $Mod PE.IMAGE_SCN Int32 @{
            TYPE_NO_PAD =               0x00000008
            CNT_CODE =                  0x00000020
            CNT_INITIALIZED_DATA =      0x00000040
            CNT_UNINITIALIZED_DATA =    0x00000080
            LNK_INFO =                  0x00000200
            LNK_REMOVE =                0x00000800
            LNK_COMDAT =                0x00001000
            NO_DEFER_SPEC_EXC =         0x00004000
            GPREL =                     0x00008000
            MEM_FARDATA =               0x00008000
            MEM_PURGEABLE =             0x00020000
            MEM_16BIT =                 0x00020000
            MEM_LOCKED =                0x00040000
            MEM_PRELOAD =               0x00080000
            ALIGN_1BYTES =              0x00100000
            ALIGN_2BYTES =              0x00200000
            ALIGN_4BYTES =              0x00300000
            ALIGN_8BYTES =              0x00400000
            ALIGN_16BYTES =             0x00500000
            ALIGN_32BYTES =             0x00600000
            ALIGN_64BYTES =             0x00700000
            ALIGN_128BYTES =            0x00800000
            ALIGN_256BYTES =            0x00900000
            ALIGN_512BYTES =            0x00A00000
            ALIGN_1024BYTES =           0x00B00000
            ALIGN_2048BYTES =           0x00C00000
            ALIGN_4096BYTES =           0x00D00000
            ALIGN_8192BYTES =           0x00E00000
            ALIGN_MASK =                0x00F00000
            LNK_NRELOC_OVFL =           0x01000000
            MEM_DISCARDABLE =           0x02000000
            MEM_NOT_CACHED =            0x04000000
            MEM_NOT_PAGED =             0x08000000
            MEM_SHARED =                0x10000000
            MEM_EXECUTE =               0x20000000 
            MEM_READ =                  0x40000000 
            MEM_WRITE =                 0x80000000 
        } -Bitfield

        $ImageReloc = psenum $Mod PE.IMAGE_RELOC Int16 @{
            ABSOLUTE = 0
            HIGH =     1
            LOW =      2
            HIGHLOW =  3
            HIGHADJ =  4
            DIR64 =    10
        }

        $ImageDosHeader = struct $Mod PE.IMAGE_DOS_HEADER @{
            e_magic =    field 0 $ImageDosSignature
            e_cblp =     field 1 UInt16
            e_cp =       field 2 UInt16
            e_crlc =     field 3 UInt16
            e_cparhdr =  field 4 UInt16
            e_minalloc = field 5 UInt16
            e_maxalloc = field 6 UInt16
            e_ss =       field 7 UInt16
            e_sp =       field 8 UInt16
            e_csum =     field 9 UInt16
            e_ip =       field 10 UInt16
            e_cs =       field 11 UInt16
            e_lfarlc =   field 12 UInt16
            e_ovno =     field 13 UInt16
            e_res =      field 14 UInt16[] -MarshalAs @('ByValArray', 4)
            e_oemid =    field 15 UInt16
            e_oeminfo =  field 16 UInt16
            e_res2 =     field 17 UInt16[] -MarshalAs @('ByValArray', 10)
            e_lfanew =   field 18 Int32
        }

        $ImageFileHeader = struct $Mod PE.IMAGE_FILE_HEADER @{
            Machine =              field 0 $ImageFileMachine
            NumberOfSections =     field 1 UInt16
            TimeDateStamp =        field 2 UInt32
            PointerToSymbolTable = field 3 UInt32
            NumberOfSymbols =      field 4 UInt32
            SizeOfOptionalHeader = field 5 UInt16
            Characteristics  =     field 6 $ImageFileCharacteristics
        }

        $PeImageDataDir = struct $Mod PE.IMAGE_DATA_DIRECTORY @{
            VirtualAddress = field 0 UInt32
            Size =           field 1 UInt32
        }

        $ImageOptionalHdr = struct $Mod PE.IMAGE_OPTIONAL_HEADER @{
            Magic =                       field 0 $ImageHdrMagic
            MajorLinkerVersion =          field 1 Byte
            MinorLinkerVersion =          field 2 Byte
            SizeOfCode =                  field 3 UInt32
            SizeOfInitializedData =       field 4 UInt32
            SizeOfUninitializedData =     field 5 UInt32
            AddressOfEntryPoint =         field 6 UInt32
            BaseOfCode =                  field 7 UInt32
            BaseOfData =                  field 8 UInt32
            ImageBase =                   field 9 UInt32
            SectionAlignment =            field 10 UInt32
            FileAlignment =               field 11 UInt32
            MajorOperatingSystemVersion = field 12 UInt16
            MinorOperatingSystemVersion = field 13 UInt16
            MajorImageVersion =           field 14 UInt16
            MinorImageVersion =           field 15 UInt16
            MajorSubsystemVersion =       field 16 UInt16
            MinorSubsystemVersion =       field 17 UInt16
            Win32VersionValue =           field 18 UInt32
            SizeOfImage =                 field 19 UInt32
            SizeOfHeaders =               field 20 UInt32
            CheckSum =                    field 21 UInt32
            Subsystem =                   field 22 $ImageSubsystem
            DllCharacteristics =          field 23 $ImageDllCharacteristics
            SizeOfStackReserve =          field 24 UInt32
            SizeOfStackCommit =           field 25 UInt32
            SizeOfHeapReserve =           field 26 UInt32
            SizeOfHeapCommit =            field 27 UInt32
            LoaderFlags =                 field 28 UInt32
            NumberOfRvaAndSizes =         field 29 UInt32
            DataDirectory =               field 30 $PeImageDataDir.MakeArrayType() -MarshalAs @('ByValArray', 16)
        }

        $ImageOptionalHdr64 = struct $Mod PE.IMAGE_OPTIONAL_HEADER64 @{
            Magic =                       field 0 $ImageHdrMagic
            MajorLinkerVersion =          field 1 Byte
            MinorLinkerVersion =          field 2 Byte
            SizeOfCode =                  field 3 UInt32
            SizeOfInitializedData =       field 4 UInt32
            SizeOfUninitializedData =     field 5 UInt32
            AddressOfEntryPoint =         field 6 UInt32
            BaseOfCode =                  field 7 UInt32
            ImageBase =                   field 8 UInt64
            SectionAlignment =            field 9 UInt32
            FileAlignment =               field 10 UInt32
            MajorOperatingSystemVersion = field 11 UInt16
            MinorOperatingSystemVersion = field 12 UInt16
            MajorImageVersion =           field 13 UInt16
            MinorImageVersion =           field 14 UInt16
            MajorSubsystemVersion =       field 15 UInt16
            MinorSubsystemVersion =       field 16 UInt16
            Win32VersionValue =           field 17 UInt32
            SizeOfImage =                 field 18 UInt32
            SizeOfHeaders =               field 19 UInt32
            CheckSum =                    field 20 UInt32
            Subsystem =                   field 21 $ImageSubsystem
            DllCharacteristics =          field 22 $ImageDllCharacteristics
            SizeOfStackReserve =          field 23 UInt64
            SizeOfStackCommit =           field 24 UInt64
            SizeOfHeapReserve =           field 25 UInt64
            SizeOfHeapCommit =            field 26 UInt64
            LoaderFlags =                 field 27 UInt32
            NumberOfRvaAndSizes =         field 28 UInt32
            DataDirectory =               field 29 $PeImageDataDir.MakeArrayType() -MarshalAs @('ByValArray', 16)
        }

        $ImageNTHdrs = struct $Mod PE.IMAGE_NT_HEADERS @{
            Signature =      field 0 $ImageNTSig
            FileHeader =     field 1 $ImageFileHeader
            OptionalHeader = field 2 $ImageOptionalHdr
        }

        $ImageNTHdrs64 = struct $Mod PE.IMAGE_NT_HEADERS64 @{
            Signature =      field 0 $ImageNTSig
            FileHeader =     field 1 $ImageFileHeader
            OptionalHeader = field 2 $ImageOptionalHdr64
        }

        $ImageSectionHdr = struct $Mod PE.IMAGE_SECTION_HEADER @{
            Name =                 field 0 String -MarshalAs @('ByValTStr', 7)
            VirtualSize =          field 1 UInt32
            VirtualAddress =       field 2 UInt32
            SizeOfRawData =        field 3 UInt32
            PointerToRawData =     field 4 UInt32
            PointerToRelocations = field 5 UInt32
            PointerToLinenumbers = field 6 UInt32
            NumberOfRelocations =  field 7 UInt16
            NumberOfLinenumbers =  field 8 UInt16
            Characteristics =      field 9 $ImageScn
        }

        $ImageExportDir = struct $Mod PE.IMAGE_EXPORT_DIRECTORY @{
            Characteristics =       field 0 UInt32
            TimeDateStamp =         field 1 UInt32
            MajorVersion =          field 2 UInt16
            MinorVersion =          field 3 UInt16
            Name =                  field 4 UInt32
            Base =                  field 5 UInt32
            NumberOfFunctions =     field 6 UInt32
            NumberOfNames =         field 7 UInt32
            AddressOfFunctions =    field 8 UInt32
            AddressOfNames =        field 9 UInt32
            AddressOfNameOrdinals = field 10 UInt32
        }

        $ImageImportDescriptor = struct $Mod PE.IMAGE_IMPORT_DESCRIPTOR @{
            OriginalFirstThunk = field 0 UInt32
            TimeDateStamp =      field 1 UInt32
            ForwarderChain =     field 2 UInt32
            Name =               field 3 UInt32
            FirstThunk =         field 4 UInt32
        }

        $ImageThunkData = struct $Mod PE.IMAGE_THUNK_DATA @{
            AddressOfData = field 0 Int32
        }

        $ImageThunkData64 = struct $Mod PE.IMAGE_THUNK_DATA64 @{
            AddressOfData = field 0 Int64
        }
        
        $ImageImportByName = struct $Mod PE.IMAGE_IMPORT_BY_NAME @{
            Hint = field 0 UInt16
            Name = field 1 char
        }

        $FunctionDefinitions = @(
            (func kernel32 GetLastError ([Int32]) @()),
            (func kernel32 GetModuleHandle ([Intptr]) @([String]) -SetLastError),
            (func kernel32 OpenProcess ([IntPtr]) @([UInt32], [Bool], [UInt32]) -SetLastError),
            (func kernel32 ReadProcessMemory ([Bool]) @([IntPtr], [IntPtr], [IntPtr], [Int], [Int].MakeByRefType()) -SetLastError),
            (func kernel32 CloseHandle ([Bool]) @([IntPtr]) -SetLastError),
            (func kernel32 GetModuleFileNameEx ([Int]) @([Int], [IntPtr], [Text.StringBuilder], [Int]) -SetLastError),
            (func kernel32 K32GetModuleFileNameEx ([Int]) @([Int], [IntPtr], [Text.StringBuilder], [Int]) -SetLastError),
            (func ntdll memset ([Void]) @([IntPtr], [Int], [Int]))
        )

        $Types = $FunctionDefinitions | Add-Win32Type -Module $Mod -Namespace 'Win32PEParser'
        $Kernel32 = $Types['kernel32']
        $Ntdll = $Types['ntdll']
        

        $FullDumpPath = $null
        if ($DumpDirectory) { $FullDumpPath = (Resolve-Path $DumpDirectory).Path }
    }

    PROCESS
    {
        
        $SystemInfo = Get-SystemInfo

        $ImageParsingFailed = $False

        switch ($PsCmdlet.ParameterSetName) {
            'OnDisk' {
                if ($FilePath.Length -gt 1) {
                    foreach ($Path in $FilePath) { Get-PE -FilePath $Path }
                }
            
                if (!(Test-Path $FilePath)) {
                    Write-Warning 'Invalid path or file does not exist.'
                    return
                }
            
                $FilePath = (Resolve-Path $FilePath).Path
            
                $ModuleName = $FilePath
                
                $ImageType = 'File'
                $ProcessID = $PID

                $FileByteArray = [IO.File]::ReadAllBytes($FilePath)
                $PELen = $FileByteArray.Length
                
                
                $Handle = [Runtime.InteropServices.GCHandle]::Alloc($FileByteArray, 'Pinned')
                $PEHeaderAddr = $Handle.AddrOfPinnedObject()
                if (!$PEHeaderAddr) { throw 'Unable to allocate local memory to store a copy of the PE header.' }
            }

            'ByteArray' {
                
                $ModuleName = ''
                $ImageType = 'File'
                $ProcessID = $PID

                $PELen = $FileBytes.Length
                
                
                $Handle = [Runtime.InteropServices.GCHandle]::Alloc($FileBytes, 'Pinned')
                $PEHeaderAddr = $Handle.AddrOfPinnedObject()
                if (!$PEHeaderAddr) { throw 'Unable to allocate local memory to store a copy of the PE header.' }
            }

            'InMemory' {
                if ($Module.Length -gt 1) {
                    foreach ($Mod in $Module) {
                        $BaseAddr = $Mod.BaseAddress
                        if ($DumpDirectory) {
                            Get-PE -ProcessID $ProcessID -Module $Mod -ModuleBaseAddress $BaseAddr -DumpDirectory $DumpDirectory
                        } else {
                            Get-PE -ProcessID $ProcessID -Module $Mod -ModuleBaseAddress $BaseAddr
                        }
                    }
                }

                if (-not $ModuleBaseAddress) { return }

                
                $ImageType = 'Image'

                
                $HeaderSize = $SystemInfo.PageSize
                $PELen = $HeaderSize
                
                $PEHeaderAddr = [Runtime.InteropServices.Marshal]::AllocHGlobal($HeaderSize)
                if (!$PEHeaderAddr) { throw 'Unable to allocate local memory to store a copy of the PE header.' }

                
                
                $hProcess = $Kernel32::OpenProcess(0x410, $False, $ProcessID)
        
                if (-not $hProcess) {
                    throw "Unable to get a process handle for process ID: $ProcessID"
                }

                if ($Module) {
                    $ModuleName = $Module[0].FileName
                } else {
                    $FileNameSize = 255
                    $StrBuilder = New-Object Text.StringBuilder $FileNameSize
                    try {
                        
                        
                        $null = $Kernel32::K32GetModuleFileNameEx($hProcess, $ModuleBaseAddress, $StrBuilder, $FileNameSize)
                    } catch {
                        $null = $Kernel32::GetModuleFileNameEx($hProcess, $ModuleBaseAddress, $StrBuilder, $FileNameSize)
                    }

                    $ModuleName = $StrBuilder.ToString()
                }

                Write-Verbose "Opened process handle for PID: $ProcessID"
                Write-Verbose "Processing module: $ModuleName, BaseAddress: 0x$($ModuleBaseAddress.ToString('X16'))"

                $BytesRead = 0
                
                $Result = $Kernel32::ReadProcessMemory($hProcess,
                                                       $ModuleBaseAddress,
                                                       $PEHeaderAddr,
                                                       $SystemInfo.PageSize,
                                                       [Ref] $BytesRead)

                if (!$Result) {
                    $VirtualMem = Get-VirtualMemoryInfo -ProcessID $ProcessID -ModuleBaseAddress $ModuleBaseAddress
                    if ($ModuleName) {
                        $ErrorMessage = "Failed to read PE header of $ModuleName. Address: " +
                                        "0x$($ModuleBaseAddress.ToString('X16')), Protect: " +
                                        "$($VirtualMem.Protect), Type: $($VirtualMem.Type)"

                        Write-Error $ErrorMessage
                    } else {
                        $ErrorMessage = "Failed to read PE header of process ID: $ProcessID. " +
                                        "Address: 0x$($ModuleBaseAddress.ToString('X16')), " +
                                        "Protect: $($VirtualMem.Protect), Type: $($VirtualMem.Type)"

                        Write-Error $ErrorMessage
                    }
            
                    $null = $Kernel32::CloseHandle($hProcess)
                    [Runtime.InteropServices.Marshal]::FreeHGlobal($PEHeaderAddr)
                    return
                }
            }
        }

        if (!(Test-Pointer $PEHeaderAddr $ImageDosHeader::GetSize() $PEHeaderAddr $PELen)) {
            Write-Error 'Dereferencing IMAGE_DOS_HEADER will cause an out-of-bounds memory access. Quiting.'

            if ($ImageType -eq 'File') {
                $Handle.Free()
            } else {
                $null = $Kernel32::CloseHandle($hProcess)
                [Runtime.InteropServices.Marshal]::FreeHGlobal($PEHeaderAddr)
            }

            return
        }

        $DosHeader = $PEHeaderAddr -as $ImageDosHeader

        if ($DosHeader.e_magic -ne $ImageDosSignature::DOS_SIGNATURE) {
            Write-Warning 'Malformed DOS header detected. File does not contain an MZ signature.'
            if (-not $IgnoreMalformedPE) {
                if ($ImageType -eq 'File') {
                    $Handle.Free()
                } else {
                    $null = $Kernel32::CloseHandle($hProcess)
                    [Runtime.InteropServices.Marshal]::FreeHGlobal($PEHeaderAddr)
                }

                return
            }

            $ImageParsingFailed = $True
        }

        if (($DosHeader.e_lfanew -lt 0x40) -or ($DosHeader.e_lfanew % 4 -ne 0) -or ($DosHeader.e_lfanew -gt 360)) {
            Write-Warning 'Malformed DOS header detected. Invalid e_lfanew field.'
            if (-not $IgnoreMalformedPE) {
                if ($ImageType -eq 'File') {
                    $Handle.Free()
                } else {
                    $null = $Kernel32::CloseHandle($hProcess)
                    [Runtime.InteropServices.Marshal]::FreeHGlobal($PEHeaderAddr)
                }

                return
            }

            $ImageParsingFailed = $True
        }

        $NtHeaderOffset = [IntPtr] ($PEHeaderAddr.ToInt64() + $DosHeader.e_lfanew)

        if (!(Test-Pointer $NtHeaderOffset $ImageNTHdrs::GetSize() $PEHeaderAddr $PELen)) {
            Write-Error 'Dereferencing IMAGE_NT_HEADERS will cause an out-of-bounds memory access. Quiting.'

            if ($ImageType -eq 'File') {
                $Handle.Free()
            } else {
                $null = $Kernel32::CloseHandle($hProcess)
                [Runtime.InteropServices.Marshal]::FreeHGlobal($PEHeaderAddr)
            }

            return
        }

        $NTHeader = $NtHeaderOffset -as $ImageNTHdrs

        if ($NTHeader.Signature -ne $ImageNTSig::VALID_PE_SIGNATURE) {
            Write-Warning 'Malformed NT header. Invalid PE signature.'
            if (-not $IgnoreMalformedPE) {
                if ($ImageType -eq 'File') {
                    $Handle.Free()
                } else {
                    $null = $Kernel32::CloseHandle($hProcess)
                    [Runtime.InteropServices.Marshal]::FreeHGlobal($PEHeaderAddr)
                }

                return
            }

            $ImageParsingFailed = $True
        }

        $Is64Bit = $False
        $Bits = 32
        $ThunkDataStruct = $ImageThunkData
        $OrdinalFlag = 0x80000000
        if ($NtHeader.OptionalHeader.Magic -eq 'PE64') {
            $Bits = 64
            
            $NTHeader = $NtHeaderOffset -as $ImageNTHdrs64
            $Is64Bit = $True
            $ThunkDataStruct = $ImageThunkData64
            $OrdinalFlag = 0x8000000000000000
            Write-Verbose '64-bit PE detected'
        }
        else {
            Write-Verbose '32-bit PE detected'
        }

        if ($NtHeader.OptionalHeader.NumberOfRvaAndSizes -ne 16) {
            Write-Warning 'Malformed optional header. 16 data directories are expected.'
            if (-not $IgnoreMalformedPE) {
                if ($ImageType -eq 'File') {
                    $Handle.Free()
                } else {
                    $null = $Kernel32::CloseHandle($hProcess)
                    [Runtime.InteropServices.Marshal]::FreeHGlobal($PEHeaderAddr)
                }

                return
            }

            $ImageParsingFailed = $True
        }

        $SectionHeaderOffset = $DosHeader.e_lfanew + 4 +
                               $ImageFileHeader::GetSize() +
                               $NtHeader.FileHeader.SizeOfOptionalHeader
        $PSectionHeaders = [IntPtr] ($PEHeaderAddr.ToInt64() + $SectionHeaderOffset)

        $NumSections = $NtHeader.FileHeader.NumberOfSections
        $FileAlignment = $NtHeader.OptionalHeader.FileAlignment
        $UnadjustedHeaderSize = ($SectionHeaderOffset + ($NumSections * $ImageSectionHdr::GetSize())) - 1
        $HeaderSize = [Math]::Ceiling($UnadjustedHeaderSize / $FileAlignment) * $FileAlignment

        if ($HeaderSize -gt $PELen) {
            Write-Error 'Malformed PE. The calculated size of the PE header exceeds the size of the buffer allocated.'

            if ($ImageType -eq 'File') {
                $Handle.Free()
            } else {
                $null = $Kernel32::CloseHandle($hProcess)
                [Runtime.InteropServices.Marshal]::FreeHGlobal($PEHeaderAddr)
            }

            return
        }

        if ($HeaderSize -gt $NtHeader.OptionalHeader.SizeOfHeaders) {
            Write-Warning 'Malformed optional header. Number of sections exceed the expected total size of the PE header'
            if (-not $IgnoreMalformedPE) {
                if ($ImageType -eq 'File') {
                    $Handle.Free()
                } else {
                    $null = $Kernel32::CloseHandle($hProcess)
                    [Runtime.InteropServices.Marshal]::FreeHGlobal($PEHeaderAddr)
                }

                return
            }

            $ImageParsingFailed = $True
        }

        $SectionHeaders = New-Object Object[] $NumSections
        $MaxRVA = $NTHeader.OptionalHeader.SizeOfImage
        $SizeOfPEFile = 0

        Write-Verbose "Image size in memory: 0x$($MaxRVA.ToString('X8'))"
        Write-Verbose 'Copying local version of the module...'

        $OrigPELen = $PELen

        
        
        
        
        if ($ImageType -eq 'File') {
            $PEBase = $PEHeaderAddr
        } else {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($PEHeaderAddr)
            $PEBase = [Runtime.InteropServices.Marshal]::AllocHGlobal($MaxRVA)
            $PELen = $MaxRVA

            
            $Ntdll::memset($PEBase, 0, $MaxRVA)
        }

        $PEMinAddr = $PEBase.ToInt64()
        $PEMaxAddr = $PEBase.ToInt64() + $MaxRVA
        $ImageIsDatafile = $True

        if ($ImageType -ne 'File') {
            Write-Verbose 'Copying PE header from the remote process...'

            $BytesRead = 0
            
            $Result = $Kernel32::ReadProcessMemory($hProcess,
                $ModuleBaseAddress,
                $PEBase,
                $NtHeader.OptionalHeader.SizeOfHeaders,
                [Ref] $BytesRead)

            Write-Verbose "Number of bytes read: 0x$($BytesRead.ToString('X8'))"

            if (!$Result) {
                if ($ModuleName) {
                    Write-Error "Failed to read PE header of $ModuleName"
                } else {
                    Write-Error "Failed to read PE header of process ID: $ProcessID"
                }
            
                $null = $Kernel32::CloseHandle($hProcess)
                [Runtime.InteropServices.Marshal]::FreeHGlobal($PEBase)

                return
            }

            $Properties = @{
                ProcessID = $ProcessID
                ModuleBaseAddress = $ModuleBaseAddress
                PageSize = $SystemInfo.PageSize
            }
            $MemoryInfo = Get-VirtualMemoryInfo @Properties
            $ImageIsDatafile = $False

            if ($MemoryInfo.Type -eq 'MEM_MAPPED') {
                
                $ImageIsDatafile = $True
                $ImageType = 'Mapped'
            } elseif ($MemoryInfo.Type -eq 'MEM_PRIVATE') {
                
                $WarningMessage = "Image at address 0x$($ModuleBaseAddress.ToString('X16')) was " +
                                  'not mapped with LoadLibrary[Ex]. It is possible ' +
                                  'that malicious code reflectively loaded this module!'

                Write-Warning $WarningMessage
            }
        }

        
        foreach ($i in 0..($NumSections - 1)) {
            if (!(Test-Pointer $PSectionHeaders $ImageSectionHdr::GetSize() $PEHeaderAddr $OrigPELen)) {
                Write-Error 'Dereferencing IMAGE_SECTION_HEADER will cause an out-of-bounds memory access. Quiting.'

                if ($ImageType -eq 'File') {
                    $Handle.Free()
                } else {
                    $null = $Kernel32::CloseHandle($hProcess)
                    [Runtime.InteropServices.Marshal]::FreeHGlobal($PEBase)
                }

                return
            }

            $SectionHeaders[$i] = $PSectionHeaders -as $ImageSectionHdr

            if ($ImageIsDatafile) {
                $SectionSize = $SectionHeaders[$i].SizeOfRawData
                $SectionMaxRVA = $SectionHeaders[$i].PointerToRawData + $SectionSize
                $SectionRVA = $SectionHeaders[$i].PointerToRawData
            } else {
                $SectionSize = $SectionHeaders[$i].VirtualSize
                $SectionMaxRVA = $SectionHeaders[$i].VirtualAddress + $SectionSize
                $SectionRVA = $SectionHeaders[$i].VirtualAddress
            }
                
            $MaxFileOffset = $SectionHeaders[$i].PointerToRawData + $SectionHeaders[$i].SizeOfRawData

            if ($MaxFileOffset -gt $SizeOfPEFile) {
                $SizeOfPEFile = $MaxFileOffset
            }

            if ($SectionMaxRVA -gt $MaxRVA) {
                Write-Warning "Malformed section header. $($SectionHeaders[$i].Name) section exceeds SizeOfImage."
                if (-not $IgnoreMalformedPE) {
                    if ($ImageType -eq 'File') {
                        $Handle.Free()
                    } else {
                        $null = $Kernel32::CloseHandle($hProcess)
                        [Runtime.InteropServices.Marshal]::FreeHGlobal($PEBase)
                    }

                    return
                }

                $ImageParsingFailed = $True
            }

            
            $PSectionHeaders = [IntPtr] ($PSectionHeaders.ToInt64() + $ImageSectionHdr::GetSize())

            if ($ImageType -ne 'File') {
                $VerboseMessage = "Copying $($SectionHeaders[$i].Name) section.`tRange: " +
                                  "0x$(($ModuleBaseAddress.ToInt64() + $SectionRVA).ToString('X16'))" +
                                  "-0x$(($ModuleBaseAddress.ToInt64() + $SectionMaxRVA - 1).ToString('X16'))" +
                                  ", Size: 0x$($SectionSize.ToString('X8'))"

                Write-Verbose $VerboseMessage

                $BytesRead = 0

                
                $Result = $Kernel32::ReadProcessMemory($hProcess,
                    ($ModuleBaseAddress.ToInt64() + $SectionRVA),
                    ($PEBase.ToInt64() + $SectionRVA),
                    $SectionSize,
                    [Ref] $BytesRead)

                Write-Verbose "Number of bytes read: 0x$($BytesRead.ToString('X8'))"

                if (!$Result) {
                    if ($ModuleName) {
                        Write-Warning "Failed to read $($SectionHeaders[$i].Name) section of $ModuleName."
                    } else {
                        $WarningMessage = "Failed to read $($SectionHeaders[$i].Name) section" +
                                          " of module 0x$($ModuleBaseAddress.ToString('X16'))."

                        Write-Warning $WarningMessage
                    }

                    $ImageParsingFailed = $True
                }
            }
        }

        if ($ImageIsDatafile) {
            $PEMinAddr = $PEBase.ToInt64()
            $PEMaxAddr = $PEBase.ToInt64() + $SizeOfPEFile
        }

        
        if ($ImageParsingFailed) {
            if (-not $DumpDirectory) {
                if ($ImageType -eq 'File') {
                    $NewProcessID = $null
                    $BaseAddr = $null
                } else {
                    $NewProcessID = $ProcessID
                    $BaseAddr = $ModuleBaseAddress
                }

                $Fields = @{
                    ProcessId = $NewProcessID
                    BaseAddress = $BaseAddr
                    ModuleName = $ModuleName
                    Bits = $Bits
                    ImageType = $ImageType
                    DOSHeader = $DosHeader
                    NTHeader = $NTHeader
                    SectionHeaders = $SectionHeaders
                    ImportDirectory = $ImportEntries
                    Imports = $Imports
                    ExportDirectory = $ExportDir
                    Exports = $Exports
                }

                $PE = New-Object PSObject -Property $Fields
                $PE.PSObject.TypeNames.Insert(0, 'PE.ParsedPE')
            }

            if ($ImageType -eq 'File') {
                $Handle.Free()
            } else {
                $null = $Kernel32::CloseHandle($hProcess)
                [Runtime.InteropServices.Marshal]::FreeHGlobal($PEBase)
            }

            return $PE
        }

        
        if ($ImageType -ne 'File') { $null = $Kernel32::CloseHandle($hProcess) }

        Write-Verbose 'Processing imports...'

        
        $ImportDirRVA = $NtHeader.OptionalHeader.DataDirectory[1].VirtualAddress
        $ImportDirSize = $NtHeader.OptionalHeader.DataDirectory[1].Size
        $ImportEntries = $null
        $Imports = $null

        if ($ImportDirRVA -and $ImportDirSize) {
            $FirstImageImportDescriptorPtr = [IntPtr] ($PEBase.ToInt64() + $ImportDirRVA)

            if ($ImageIsDatafile) {
                $FirstImageImportDescriptorPtr = Convert-RVAToFileOffset $FirstImageImportDescriptorPtr $SectionHeaders $PEBase
            }

            $ImportDescriptorPtr = $FirstImageImportDescriptorPtr

            $ImportEntries = New-Object 'Collections.Generic.List[PSObject]'
            $Imports = New-Object 'Collections.Generic.List[PSObject]'

            $i = 0
            
            while ($True) {
                $ImportDescriptorPtr = [IntPtr] ($FirstImageImportDescriptorPtr.ToInt64() +
                                                ($i * $ImageImportDescriptor::GetSize()))

                if (!(Test-Pointer $ImportDescriptorPtr $ImageImportDescriptor::GetSize() $PEBase $PELen)) {
                    Write-Verbose 'Dereferencing IMAGE_IMPORT_DESCRIPTOR will cause an out-of-bounds memory access.'
                    $i++
                    break
                }

                $ImportDescriptor = $ImportDescriptorPtr -as $ImageImportDescriptor

                if ($ImportDescriptor.OriginalFirstThunk -eq 0) { break }

                $DllNamePtr = [IntPtr] ($PEBase.ToInt64() + $ImportDescriptor.Name)
                if ($ImageIsDatafile) { $DllNamePtr = Convert-RVAToFileOffset $DllNamePtr $SectionHeaders $PEBase }

                if (!(Test-Pointer $DllNamePtr 256 $PEBase $PELen)) {
                    Write-Verbose 'Import dll name address exceeded the reported address range.'
                    $i++
                    break
                }

                $DllName = [Runtime.InteropServices.Marshal]::PtrToStringAnsi($DllNamePtr)

                $FirstFuncAddrPtr = [IntPtr] ($PEBase.ToInt64() + $ImportDescriptor.FirstThunk)
                if ($ImageIsDatafile) {
                    $FirstFuncAddrPtr = Convert-RVAToFileOffset $FirstFuncAddrPtr $SectionHeaders $PEBase
                }

                $FuncAddrPtr = $FirstFuncAddrPtr
                $FirstOFTPtr = [IntPtr] ($PEBase.ToInt64() + $ImportDescriptor.OriginalFirstThunk)

                if ($ImageIsDatafile) {
                    $FirstOFTPtr = Convert-RVAToFileOffset $FirstOFTPtr $SectionHeaders $PEBase
                }

                $OFTPtr = $FirstOFTPtr
                $j = 0

                while ($True)
                {
                    $OFTPtr = [IntPtr] ($FirstOFTPtr.ToInt64() + ($j * $ThunkDataStruct::GetSize()))

                    if (!(Test-Pointer $OFTPtr $ThunkDataStruct::GetSize() $PEBase $PELen)) {
                        Write-Verbose 'Import thunk data address exceeded the reported address range.'
                        j++
                        break
                    }

                    $ThunkData = $OFTPtr -as $ThunkDataStruct

                    $FuncAddrPtr = [IntPtr] ($FirstFuncAddrPtr.ToInt64() + ($j * $ThunkDataStruct::GetSize()))

                    if (($FuncAddrPtr.ToInt64() -lt $PEMinAddr) -or ($FuncAddrPtr.ToInt64() -gt $PEMaxAddr)) {
                        Write-Verbose 'Import thunk data address exceeded the reported address range.'
                        j++
                        break
                    }

                    if (!(Test-Pointer $FuncAddrPtr $ThunkDataStruct::GetSize() $PEBase $PELen)) {
                        Write-Verbose 'Import thunk data address exceeded the reported address range.'
                        j++
                        break
                    }

                    $FuncAddr = $FuncAddrPtr -as $ThunkDataStruct

                    
                    if ($FullDumpPath -and !$ImageIsDatafile) {
                        if ($Is64Bit) {
                            [Runtime.InteropServices.Marshal]::WriteInt64($FuncAddrPtr, $ThunkData.AddressOfData)
                        } else {
                            [Runtime.InteropServices.Marshal]::WriteInt32($FuncAddrPtr, $ThunkData.AddressOfData)
                        }
                    }

                    $Result = @{
                        ModuleName = $DllName
                        OFT = $ThunkData.AddressOfData
                        FT = $FuncAddr.AddressOfData
                    }

                    if (($ThunkData.AddressOfData -band $OrdinalFlag) -eq $OrdinalFlag)
                    {
                        $Result['Ordinal'] = $ThunkData.AddressOfData -band (-bnot $OrdinalFlag)
                        $Result['FunctionName'] = ''
                    }
                    else
                    {
                        $ImportByNamePtr = [IntPtr] ($PEBase.ToInt64() + [Int64]$ThunkData.AddressOfData + 2)

                        if ($ImageIsDatafile) {
                            $ImportByNamePtr = Convert-RVAToFileOffset $ImportByNamePtr $SectionHeaders $PEBase
                        }

                        if (!(Test-Pointer $ImportByNamePtr 256 $PEBase $PELen)) {
                            Write-Verbose 'Import name address exceeded the reported address range.'
                            $FuncName = ''
                        } else {
                            $FuncName = [Runtime.InteropServices.Marshal]::PtrToStringAnsi($ImportByNamePtr)
                        }

                        $Result['Ordinal'] = ''
                        $Result['FunctionName'] = $FuncName
                    }
                
                    $Result['RVA'] = $FuncAddr.AddressOfData

                    if ($FuncAddr.AddressOfData -eq 0) { break }
                    if ($OFTPtr -eq 0) { break }
                
                    $Import = New-Object PSObject -Property $Result
                    $Import.PSObject.TypeNames.Insert(0, 'PE.Import')
                    $Imports.Add($Import)
                
                    $j++
                
                }

                $Fields = @{
                    OriginalFirstThunk = $ImportDescriptor.OriginalFirstThunk
                    TimeDateStamp = $ImportDescriptor.TimeDateStamp
                    ForwarderChain = $ImportDescriptor.ForwarderChain
                    Name = $DllName
                    FirstThunk = $ImportDescriptor.FirstThunk
                }

                $ImportDir = New-Object PSObject -Property $Fields
                $ImportDir.PSObject.TypeNames.Insert(0, 'PE.ImportDir')
                $ImportEntries.Add($ImportDir)

                $i++
            }
        }

        Write-Verbose 'Processing exports...'

        
        $ExportDirRVA = $NtHeader.OptionalHeader.DataDirectory[0].VirtualAddress
        $ExportDirSize = $NtHeader.OptionalHeader.DataDirectory[0].Size
        $ExportDir = $null
        $Exports = $null

        if ($ExportDirRVA -and $ExportDirSize) {
            
            $ExportPointer = [IntPtr] ($PEBase.ToInt64() + $NtHeader.OptionalHeader.DataDirectory[0].VirtualAddress)
            
            $ExportDirLow = $NtHeader.OptionalHeader.DataDirectory[0].VirtualAddress
            if ($ImageIsDatafile) { 
                $ExportPointer = Convert-RVAToFileOffset $ExportPointer $SectionHeaders $PEBase
                $ExportDirLow = Convert-RVAToFileOffset $ExportDirLow $SectionHeaders $PEBase
                $ExportDirHigh = $ExportDirLow.ToInt32() + $NtHeader.OptionalHeader.DataDirectory[0].Size
            } else { $ExportDirHigh = $ExportDirLow + $NtHeader.OptionalHeader.DataDirectory[0].Size }
            
            if (!(Test-Pointer $ExportPointer $ImageExportDir::GetSize() $PEBase $PELen)) {
                Write-Verbose 'Export directory address exceeded the reported address range.'
            } else {
                $ExportDirectory = $ExportPointer -as $ImageExportDir
                $AddressOfNamePtr = [IntPtr] ($PEBase.ToInt64() + $ExportDirectory.AddressOfNames)
                $NameOrdinalAddrPtr = [IntPtr] ($PEBase.ToInt64() + $ExportDirectory.AddressOfNameOrdinals)
                $AddressOfFunctionsPtr = [IntPtr] ($PEBase.ToInt64() + $ExportDirectory.AddressOfFunctions)
                $NumNamesFuncs = $ExportDirectory.NumberOfFunctions - $ExportDirectory.NumberOfNames
                $NumNames = $ExportDirectory.NumberOfNames
                $NumFunctions = $ExportDirectory.NumberOfFunctions
                $Base = $ExportDirectory.Base

                if ($ImageIsDatafile) {
                    $AddressOfNamePtr = Convert-RVAToFileOffset $AddressOfNamePtr $SectionHeaders $PEBase
                    $NameOrdinalAddrPtr = Convert-RVAToFileOffset $NameOrdinalAddrPtr $SectionHeaders $PEBase
                    $AddressOfFunctionsPtr = Convert-RVAToFileOffset $AddressOfFunctionsPtr $SectionHeaders $PEBase
                }

                $Exports = New-Object 'Collections.Generic.List[PSObject]'

                if ($NumFunctions -gt 0) {
                    
                    $FunctionHashTable = @{}
        
                    foreach ($i in 0..($NumFunctions - 1)) {
                        $FuncAddr = $AddressOfFunctionsPtr.ToInt64() + ($i * 4)

                        if (!(Test-Pointer $FuncAddr 4 $PEBase $PELen)) {
                            Write-Verbose 'Export function address exceeded the reported address range. Skipping this export.'
                            break
                        }

                        $RvaFunction = [Runtime.InteropServices.Marshal]::ReadInt32($FuncAddr)
                        
                        
                        if ($RvaFunction) { $FunctionHashTable[[Int]$i] = $RvaFunction }
                    }
            
                    
                    $NameHashTable = @{}
            
                    foreach ($i in 0..($NumNames - 1)) {
                        $NamePtr = $AddressOfNamePtr.ToInt64() + ($i * 4)

                        if (!(Test-Pointer $NamePtr 4 $PEBase $PELen)) {
                            Write-Verbose 'Export AddressOfName address exceeded the reported address range. Skipping this export.'
                            break
                        }

                        $RvaName = [Runtime.InteropServices.Marshal]::ReadInt32($NamePtr)
                        $FuncNameAddr = [IntPtr] ($PEBase.ToInt64() + $RvaName)
                        if ($ImageIsDatafile) { $FuncNameAddr= Convert-RVAToFileOffset $FuncNameAddr $SectionHeaders $PEBase }

                        if (!(Test-Pointer $FuncNameAddr 256 $PEBase $PELen)) {
                            Write-Verbose 'Export name address exceeded the reported address range. Skipping this export.'
                            break
                        }

                        $FuncName = [Runtime.InteropServices.Marshal]::PtrToStringAnsi($FuncNameAddr)
                        $OrdinalPtr = $NameOrdinalAddrPtr.ToInt64() + ($i * 2)

                        if (!(Test-Pointer $OrdinalPtr 2 $PEBase $PELen)) {
                            Write-Verbose 'Export ordinal address exceeded the reported address range. Skipping this export.'
                            break
                        }

                        $NameOrdinal = [Int][Runtime.InteropServices.Marshal]::ReadInt16($OrdinalPtr)
                        $NameHashTable[$NameOrdinal] = $FuncName
                    }
            
                    foreach ($Key in $FunctionHashTable.Keys) {
                        $Result = @{}
                
                        if ($NameHashTable[$Key]) {
                            $Result['FunctionName'] = $NameHashTable[$Key]
                        } else {
                            $Result['FunctionName'] = ''
                        }
                
                        if (($FunctionHashTable[$Key] -ge $ExportDirLow) -and ($FunctionHashTable[$Key] -lt $ExportDirHigh)) {
                            $ForwardedNameAddr = [IntPtr] ($PEBase.ToInt64() + $FunctionHashTable[$Key])

                            if ($ImageIsDatafile) {
                                $ForwardedNameAddr = Convert-RVAToFileOffset $ForwardedNameAddr $SectionHeaders $PEBase
                            }

                            if (!(Test-Pointer $ForwardedNameAddr 256 $PEBase $PELen)) {
                                Write-Verbose 'Forwarded name address exceeded the reported address range. Skipping this export.'
                                break
                            }

                            $ForwardedName = [Runtime.InteropServices.Marshal]::PtrToStringAnsi($ForwardedNameAddr)
                            $Result['ForwardedName'] = $ForwardedName
                        } else {
                            $Result['ForwardedName'] = ''
                        }
                
                        $Result['Ordinal'] = $Key + $Base
                        $Result['RVA'] = $FunctionHashTable[$Key]
                
                        $Export = New-Object PSObject -Property $Result
                        $Export.PSObject.TypeNames.Insert(0, 'PE.Export')
                        $Exports.Add($Export)
                    }
                }

                $ExportNameAddr = [IntPtr] ($PEBase.ToInt64() + $ExportDirectory.Name)

                if ($ImageIsDatafile) {
                    $ExportNameAddr = Convert-RVAToFileOffset $ExportNameAddr $SectionHeaders $PEBase
                }

                if (!(Test-Pointer $ExportNameAddr 256 $PEBase $PELen)) {
                    Write-Verbose 'Export name address exceeded the reported address range.'
                    $ExportName = ''
                } else {
                    $ExportName = [Runtime.InteropServices.Marshal]::PtrToStringAnsi($ExportNameAddr)
                }

                $ExportDirFields = @{
                    Characteristics = $ExportDirectory.Characteristics
                    TimeDateStamp = $ExportDirectory.TimeDateStamp
                    MajorVersion = $ExportDirectory.MajorVersion
                    MinorVersion = $ExportDirectory.MinorVersion
                    Name = $ExportName
                    Base = $ExportDirectory.Base
                    NumberOfFunctions = $ExportDirectory.NumberOfFunctions
                    NumberOfNames = $ExportDirectory.NumberOfNames
                    AddressOfFunctions = $ExportDirectory.AddressOfFunctions
                    AddressOfNames = $ExportDirectory.AddressOfNames
                    AddressOfNameOrdinals = $ExportDirectory.AddressOfNameOrdinals
                }

                $ExportDir = New-Object PSObject -Property $ExportDirFields
                $ExportDir.PSObject.TypeNames.Insert(0, 'PE.ExportDir')

                
                if (!$ModuleName -and $ExportName) {
                    $ModuleName = $ExportName
                }
            }
        }

        
        
        
        
        
        
        
        
        if ($FullDumpPath)
        {
            Write-Verbose "Calculated PE file size: 0x$($SizeOfPEFile.ToString('X8'))"
            $ModuleBaseDelta = $ModuleBaseAddress.ToInt64() - $NtHeader.OptionalHeader.ImageBase

            
            
            
            if ($ModuleBaseDelta -ne 0 -and !$ImageIsDatafile) {
                $RelocRVA = $NtHeader.OptionalHeader.DataDirectory[5].VirtualAddress
                $RelocSize = $NtHeader.OptionalHeader.DataDirectory[5].Size

                
                if ($RelocRVA -and $RelocSize) {
                    $Offset = 0
                    $PRelocBase = [IntPtr] ($PEBase.ToInt64() + $RelocRVA)
                    $PRelocBlock = $PRelocBase
                    $Relocations = New-Object 'Collections.Generic.List[PSObject]'

                    do {
                        if (($PRelocBlock.ToInt64() -lt $PEMinAddr) -or ($PRelocBlock.ToInt64() -gt $PEMaxAddr)) {
                            $VerboseMessage = 'Relocation address exceeded the reported address' +
                                              ' range. This relocation will be skipped.'

                            Write-Verbose $VerboseMessage
                            continue
                        }

                        $PageRva = [Runtime.InteropServices.Marshal]::ReadInt32($PRelocBlock)
                        $BlockSize = [Runtime.InteropServices.Marshal]::ReadInt32($PRelocBlock, 4)
                        $RelocCount = ($BlockSize - 8) / 2

                        for ($i = 0; $i -lt $RelocCount; $i++) {
                            $RelocData = [Runtime.InteropServices.Marshal]::ReadInt16($PRelocBlock, (($i *2) + 8))

                            $Reloc = New-Object PSObject -Property @{
                                Type = (($RelocData -band 0xF000) / 0x1000) -as $ImageReloc
                                Offset = ($RelocData -band 0x0FFF) + $PageRva
                            }

                            if ($Reloc.Type -ne $ImageReloc::ABSOLUTE) {
                                $Relocations.Add($Reloc)
                            }
                        }

                        $Offset += $BlockSize
                        $PRelocBlock = [IntPtr] ($PRelocBase.ToInt64() + $Offset)
                    } while ($Offset -lt $RelocSize)
                }

                Write-Verbose 'Restoring relocated addresses...'
                Write-Verbose "Module base address delta: $($ModuleBaseDelta.ToString('X8'))"

                foreach ($Relocation in $Relocations) {
                    if ($Relocation.Type -eq $ImageReloc::DIR64) {
                        $OriginalAddr = [Runtime.InteropServices.Marshal]::ReadInt64($PEBase, $Relocation.Offset)
                        $RestoredAddr = $OriginalAddr - $ModuleBaseDelta
                        if ([Int64]::TryParse($RestoredAddr, [Ref] 0)) {
                            [Runtime.InteropServices.Marshal]::WriteInt64($PEBase, $Relocation.Offset, $RestoredAddr)
                        }
                    } elseif ($Relocation.Type -eq $ImageReloc::HIGHLOW) {
                        $OriginalAddr = [Runtime.InteropServices.Marshal]::ReadInt32($PEBase, $Relocation.Offset)
                        $RestoredAddr = $OriginalAddr - $ModuleBaseDelta
                        if ([Int32]::TryParse($RestoredAddr, [Ref] 0)) {
                            [Runtime.InteropServices.Marshal]::WriteInt32($PEBase, $Relocation.Offset, $RestoredAddr)
                        }
                    }
                }
            }

            $DumpedPEBytes = New-Object Byte[] $SizeOfPEFile

            if ($ImageIsDatafile) {
                
                [Runtime.InteropServices.Marshal]::Copy($PEBase, $DumpedPEBytes, 0, $SizeOfPEFile)
            } else {
                
                [Runtime.InteropServices.Marshal]::Copy($PEBase, $DumpedPEBytes, 0, $HeaderSize)

                foreach ($Section in $SectionHeaders) {
                    $PSectionData = [IntPtr] ($PEBase.ToInt64() + $Section.VirtualAddress)

                    [Runtime.InteropServices.Marshal]::Copy($PSectionData,
                                                            $DumpedPEBytes,
                                                            $Section.PointerToRawData,
                                                            $Section.SizeOfRawData)
                }
            }

            if ($Is64Bit) { $Format = 'X16' } else { $Format = 'X8' }

            if ($ModuleName) {
                $Name = Split-Path -Leaf $ModuleName
            } else {
                $Name = 'UNKNOWN'
            }

            $DumpFile = "$FullDumpPath\$($ProcessID.ToString('X4'))" +
                        "_$($ModuleBaseAddress.ToString($Format))_$Name.bin"

            [IO.File]::WriteAllBytes($DumpFile, $DumpedPEBytes)
            Write-Verbose "Wrote dumped PE to $DumpFile"
        }

        
        
        if ($FullDumpPath) {
            Get-ChildItem $DumpFile
        } else {
            if ($ImageType -eq 'File') {
                $NewProcessID = $null
                $BaseAddr = $null
            } else {
                $NewProcessID = $ProcessID
                $BaseAddr = $ModuleBaseAddress
            }

            $Fields = @{
                ProcessId = $NewProcessID
                BaseAddress = $BaseAddr
                ModuleName = $ModuleName
                Bits = $Bits
                ImageType = $ImageType
                DOSHeader = $DosHeader
                NTHeader = $NTHeader
                SectionHeaders = $SectionHeaders
                ImportDirectory = $ImportEntries
                Imports = $Imports
                ExportDirectory = $ExportDir
                Exports = $Exports
            }

            $PE = New-Object PSObject -Property $Fields
            $PE.PSObject.TypeNames.Insert(0, 'PE.ParsedPE')

            $ScriptBlock = { & {
                Param (
                    [Parameter(Position = 0, Mandatory = $True)]
                    [String]
                    $OriginalPEDirectory,

                    [Parameter(Position = 1, Mandatory = $True)]
                    $PE
                )

                $SymServerURL = 'https://msdl.microsoft.com/download/symbols/'
                $FileName = Split-Path -Leaf $PE.ModuleName
                $Request = "{0}/{1}/{2:X8}{3:X}/{1}" -f $SymServerURL,
                                                        $FileName,
                                                        $PE.NTHeader.FileHeader.TimeDateStamp,
                                                        $PE.NTHeader.OptionalHeader.SizeOfImage
                $WebClient = New-Object Net.WebClient
                $WebClient.Headers.Add('User-Agent', 'Microsoft-Symbol-Server/10.1710.0.0')

                try {
                    $CabBytes = $WebClient.DownloadData($Request)
                } catch {
                    throw "Unable to download the original file from $Request"
                }
                
                $FileWithoutExt = $FileName.Substring(0, $FileName.LastIndexOf('.'))
                $CabPath = Join-Path $OriginalPEDirectory "$FileWithoutExt.cab"
                [IO.File]::WriteAllBytes($CabPath, $CabBytes)

                Get-ChildItem $CabPath
            } $args[0] $this }

            $Properties = @{
                InputObject = $PE
                MemberType = 'ScriptMethod'
                Name = 'DownloadFromMSSymbolServer'
                Value = $ScriptBlock
                PassThru = $True
                Force = $True
            }
            $PE = Add-Member @Properties

            
            $ScriptBlock = { & {
                Param (
                    [Parameter(Position = 0, Mandatory = $True)]
                    [String]
                    $DumpDirectory,

                    [Parameter(Position = 1, Mandatory = $True)]
                    $ProcessID,

                    [Parameter(Position = 2, Mandatory = $True)]
                    $ModuleBaseAddress
                )

                Get-PE -ProcessID $ProcessID -ModuleBaseAddress $ModuleBaseAddress -DumpDirectory $DumpDirectory
            } $args[0] $this.ProcessId $this.BaseAddress }

            $Properties = @{
                InputObject = $PE
                MemberType = 'ScriptMethod'
                Name = 'DumpToDisk'
                Value = $ScriptBlock
                PassThru = $True
                Force = $True
            }
            $PE = Add-Member @Properties

            $PE
        }
        
        if ($ImageType -eq 'File') {
            $Handle.Free()
        } else {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($PEBase)
        }
    }

    END {}
}

filter Find-ProcessPEs {


    [CmdletBinding()] Param (
        [Parameter(ParameterSetName = 'InMemory',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [Alias('Id')]
        [ValidateScript({Get-Process -Id $_})]
        [Int]
        $ProcessID
    )

    $Mod = New-InMemoryModule -ModuleName PEFinder

    $FunctionDefinitions = @(
        (func kernel32 OpenProcess ([IntPtr]) @([UInt32], [Bool], [UInt32]) -SetLastError),
        (func kernel32 ReadProcessMemory ([Bool]) @([IntPtr], [IntPtr], [IntPtr], [Int], [Int].MakeByRefType()) -SetLastError),
        (func kernel32 CloseHandle ([Bool]) @([IntPtr]) -SetLastError),
        (func ntdll memset ([Void]) @([IntPtr], [Int], [Int]))
    )

    $Types = $FunctionDefinitions | Add-Win32Type -Module $Mod -Namespace 'Win32PEFinder'
    $Kernel32 = $Types['kernel32']
    $Ntdll = $Types['ntdll']

    $Allocations = Get-ProcessMemoryInfo -ProcessID $ProcessID

    $hProcess = $Kernel32::OpenProcess(0x10, $False, $ProcessID) 

    
    $SystemInfo = Get-SystemInfo
    $Ptr = [Runtime.InteropServices.Marshal]::AllocHGlobal($SystemInfo.PageSize)

    Get-ProcessMemoryInfo -ProcessID $ProcessID | % {
        $Ntdll::memset($Ptr, 0, 2)
        $BytesRead = 0
        $Result = $Kernel32::ReadProcessMemory($hProcess, $_.BaseAddress, $Ptr, 2, [Ref] $BytesRead)

        $Bytes = $null

        if ($Result -and ($BytesRead -eq 2)) {
            $Bytes = [Runtime.InteropServices.Marshal]::ReadInt16($Ptr).ToString('X4')

            if ($PSBoundParameters['Verbose']) { $Verbose = $True } else { $Verbose = $False }

            $Params = @{
                ProcessID = $ProcessID
                ModuleBaseAddress = $_.BaseAddress
                Verbose = $Verbose
            }

            if ($Bytes -eq '5A4D') {
                Get-PE -ProcessID $ProcessID -ModuleBaseAddress $_.BaseAddress
            }
        }
    }

    [Runtime.InteropServices.Marshal]::FreeHGlobal($Ptr)
    $null = $Kernel32::CloseHandle($hProcess)
}