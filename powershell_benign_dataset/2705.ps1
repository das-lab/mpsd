



$Mod = New-InMemoryModule -ModuleName Win32

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
    Machine = field 0 $ImageFileMachine
    NumberOfSections = field 1 UInt16
    TimeDateStamp = field 2 UInt32
    PointerToSymbolTable = field 3 UInt32
    NumberOfSymbols = field 4 UInt32
    SizeOfOptionalHeader = field 5 UInt16
    Characteristics  = field 6 $ImageFileCharacteristics
}


$PeImageDataDir = struct $Mod PE.IMAGE_DATA_DIRECTORY @{
    VirtualAddress = field 0 UInt32
    Size = field 1 UInt32
}

$ImageOptionalHdr = struct $Mod PE.IMAGE_OPTIONAL_HEADER @{
    Magic = field 0 $ImageHdrMagic
    MajorLinkerVersion = field 1 Byte
    MinorLinkerVersion = field 2 Byte
    SizeOfCode = field 3 UInt32
    SizeOfInitializedData = field 4 UInt32
    SizeOfUninitializedData = field 5 UInt32
    AddressOfEntryPoint = field 6 UInt32
    BaseOfCode = field 7 UInt32
    BaseOfData = field 8 UInt32
    ImageBase = field 9 UInt32
    SectionAlignment = field 10 UInt32
    FileAlignment = field 11 UInt32
    MajorOperatingSystemVersion = field 12 UInt16
    MinorOperatingSystemVersion = field 13 UInt16
    MajorImageVersion = field 14 UInt16
    MinorImageVersion = field 15 UInt16
    MajorSubsystemVersion = field 16 UInt16
    MinorSubsystemVersion = field 17 UInt16
    Win32VersionValue = field 18 UInt32
    SizeOfImage = field 19 UInt32
    SizeOfHeaders = field 20 UInt32
    CheckSum = field 21 UInt32
    Subsystem = field 22 $ImageSubsystem
    DllCharacteristics = field 23 $ImageDllCharacteristics
    SizeOfStackReserve = field 24 UInt32
    SizeOfStackCommit = field 25 UInt32
    SizeOfHeapReserve = field 26 UInt32
    SizeOfHeapCommit = field 27 UInt32
    LoaderFlags = field 28 UInt32
    NumberOfRvaAndSizes = field 29 UInt32
    DataDirectory = field 30 $PeImageDataDir.MakeArrayType() -MarshalAs @('ByValArray', 16)
}

$ImageOptionalHdr64 = struct $Mod PE.IMAGE_OPTIONAL_HEADER64 @{
    Magic = field 0 $ImageHdrMagic
    MajorLinkerVersion = field 1 Byte
    MinorLinkerVersion = field 2 Byte
    SizeOfCode = field 3 UInt32
    SizeOfInitializedData = field 4 UInt32
    SizeOfUninitializedData = field 5 UInt32
    AddressOfEntryPoint = field 6 UInt32
    BaseOfCode = field 7 UInt32
    ImageBase = field 8 UInt64
    SectionAlignment = field 9 UInt32
    FileAlignment = field 10 UInt32
    MajorOperatingSystemVersion = field 11 UInt16
    MinorOperatingSystemVersion = field 12 UInt16
    MajorImageVersion = field 13 UInt16
    MinorImageVersion = field 14 UInt16
    MajorSubsystemVersion = field 15 UInt16
    MinorSubsystemVersion = field 16 UInt16
    Win32VersionValue = field 17 UInt32
    SizeOfImage = field 18 UInt32
    SizeOfHeaders = field 19 UInt32
    CheckSum = field 20 UInt32
    Subsystem = field 21 $ImageSubsystem
    DllCharacteristics = field 22 $ImageDllCharacteristics
    SizeOfStackReserve = field 23 UInt64
    SizeOfStackCommit = field 24 UInt64
    SizeOfHeapReserve = field 25 UInt64
    SizeOfHeapCommit = field 26 UInt64
    LoaderFlags = field 27 UInt32
    NumberOfRvaAndSizes = field 28 UInt32
    DataDirectory = field 29 $PeImageDataDir.MakeArrayType() -MarshalAs @('ByValArray', 16)
}

$ImageNTHdrs = struct $mod PE.IMAGE_NT_HEADERS @{
    Signature = field 0 $ImageNTSig
    FileHeader = field 1 $ImageFileHeader
    OptionalHeader = field 2 $ImageOptionalHdr
}

$ImageNTHdrs64 = struct $mod PE.IMAGE_NT_HEADERS64 @{
    Signature = field 0 $ImageNTSig
    FileHeader = field 1 $ImageFileHeader
    OptionalHeader = field 2 $ImageOptionalHdr64
}

$FunctionDefinitions = @(
(func kernel32 GetProcAddress ([IntPtr]) @([IntPtr], [String])),
(func kernel32 GetModuleHandle ([Intptr]) @([String])),
(func ntdll RtlGetCurrentPeb ([IntPtr]) @())
)

$Types = $FunctionDefinitions | Add-Win32Type -Module $Mod -Namespace 'Win32'
$Kernel32 = $Types['kernel32']
$Ntdll = $Types['ntdll']












$ntdllbase = $Kernel32::GetModuleHandle('ntdll')
$DosHeader = $ntdllbase -as $ImageDosHeader
$NtHeaderOffset = [IntPtr] ($ntdllbase.ToInt64() + $DosHeader.e_lfanew)
$NTHeader = $NtHeaderOffset -as $ImageNTHdrs
if ($NtHeader.OptionalHeader.Magic -eq 'PE64')
{
    $NTHeader = $NtHeaderOffset -as $ImageNTHdrs64
}

$NtHeader.FileHeader
$NtHeader.OptionalHeader
$NtHeader.OptionalHeader.DataDirectory


$Bytes = [IO.File]::ReadAllBytes('C:\Windows\System32\kernel32.dll')


$Handle = [Runtime.InteropServices.GCHandle]::Alloc($Bytes, 'Pinned')
$PEBaseAddr = $Handle.AddrOfPinnedObject()

$DosHeader = $PEBaseAddr -as $ImageDosHeader
$NtHeaderOffset = [IntPtr] ($PEBaseAddr.ToInt64() + $DosHeader.e_lfanew)
$NTHeader = $NtHeaderOffset -as $ImageNTHdrs
if ($NtHeader.OptionalHeader.Magic -eq 'PE64')
{
    $NTHeader = $NtHeaderOffset -as $ImageNTHdrs64
}

$NtHeader.FileHeader
$NtHeader.OptionalHeader
$NtHeader.OptionalHeader.DataDirectory
