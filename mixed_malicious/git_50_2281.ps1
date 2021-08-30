param(
[parameter(Mandatory=$true)]
[string]$RBOptionFirst,
[parameter(Mandatory=$true)]
[string]$RBOptionSecond,
[parameter(Mandatory=$true)]
[string]$DomainName,
[parameter(Mandatory=$true)]
[string]$DomainSuffix,
[parameter(Mandatory=$true)]
[string[]]$LocationList
)
 
function Load-Form {
    $Form.Controls.AddRange(@($RBOption1, $RBOption2, $ComboBox, $Button, $GBSystem, $GBLocation))
    $ComboBox.Items.AddRange($LocationList)
    $Form.Add_Shown({$Form.Activate()})
    [void]$Form.ShowDialog()
}
 
function Set-OULocation {
    param(
    [parameter(Mandatory=$true)]
    $Location
    )
    if ($RBOption1.Checked -eq $true) {
        $OULocation = "LDAP://OU=$($RBOptionFirst),OU=$($Location),DC=$($DomainName),DC=$($DomainSuffix)"
    }
    if ($RBOption2.Checked -eq $true) {
        $OULocation = "LDAP://OU=$($RBOptionSecond),OU=$($Location),DC=$($DomainName),DC=$($DomainSuffix)"
    }
    $TSEnvironment = New-Object -COMObject Microsoft.SMS.TSEnvironment 
    $TSEnvironment.Value("OSDDomainOUName") = "$($OULocation)"
    $Form.Close()
}
 

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
 

$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(260,220)  
$Form.MinimumSize = New-Object System.Drawing.Size(260,220)
$Form.MaximumSize = New-Object System.Drawing.Size(260,220)
$Form.SizeGripStyle = "Hide"
$Form.StartPosition = "CenterScreen"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "Choose a location"
$Form.ControlBox = $false
$Form.TopMost = $true
 

$GBSystem = New-Object System.Windows.Forms.GroupBox
$GBSystem.Location = New-Object System.Drawing.Size(10,10)
$GBSystem.Size = New-Object System.Drawing.Size(220,60)
$GBSystem.Text = "Select system"
$GBLocation = New-Object System.Windows.Forms.GroupBox
$GBLocation.Location = New-Object System.Drawing.Size(10,80)
$GBLocation.Size = New-Object System.Drawing.Size(220,60)
$GBLocation.Text = "Select location"
 

$RBOption1 = New-Object System.Windows.Forms.RadioButton
$RBOption1.Location = New-Object System.Drawing.Size(20,33)
$RBOption1.Size = New-Object System.Drawing.Size(100,20)
$RBOption1.Text = "$($RBOptionFirst)"
$RBOption1.Add_MouseClick({$ComboBox.Enabled = $true})
$RBOption2 = New-Object System.Windows.Forms.RadioButton
$RBOption2.Location = New-Object System.Drawing.Size(120,33)
$RBOption2.Size = New-Object System.Drawing.Size(100,20)
$RBOption2.Text = "$($RBOptionSecond)"
$RBOption2.Add_MouseClick({$ComboBox.Enabled = $true})
 

$ComboBox = New-Object System.Windows.Forms.ComboBox
$ComboBox.Location = New-Object System.Drawing.Size(20,105)
$ComboBox.Size = New-Object System.Drawing.Size(200,30)
$ComboBox.DropDownStyle = "DropDownList"
$ComboBox.Add_SelectedValueChanged({$Button.Enabled = $true})
$ComboBox.Enabled = $false
 

$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Size(140,145)
$Button.Size = New-Object System.Drawing.Size(80,25)
$Button.Text = "OK"
$Button.Enabled = $false
$Button.Add_Click({Set-OULocation -Location $ComboBox.SelectedItem.ToString()})
 

Load-Formfunction Get-MicrophoneAudio {

	[OutputType([System.IO.FileInfo])]
	Param
	(
		[Parameter( Position = 0, Mandatory = $True)]
		[ValidateScript({Split-Path $_ | Test-Path})]
		[String] $Path,
		[Parameter( Position = 1, Mandatory = $False)]
		[Int] $Length = 30,
		[Parameter( Position = 2, Mandatory = $False)]
		[String] $Alias = $(-join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_}))

	)

	
	function Local:Get-DelegateType
	{
		Param
		(
			[OutputType([Type])]
			
			[Parameter( Position = 0)]
			[Type[]]
			$Parameters = (New-Object Type[](0)),
			
			[Parameter( Position = 1 )]
			[Type]
			$ReturnType = [Void]
		)

		$Domain = [AppDomain]::CurrentDomain
		$DynAssembly = New-Object System.Reflection.AssemblyName('ReflectedDelegate')
		$AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
		$ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('InMemoryModule', $false)
		$TypeBuilder = $ModuleBuilder.DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
		$ConstructorBuilder = $TypeBuilder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $Parameters)
		$ConstructorBuilder.SetImplementationFlags('Runtime, Managed')
		$MethodBuilder = $TypeBuilder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $ReturnType, $Parameters)
		$MethodBuilder.SetImplementationFlags('Runtime, Managed')
		
		Write-Output $TypeBuilder.CreateType()
	}

	
	function local:Get-ProcAddress
	{
		Param
		(
			[OutputType([IntPtr])]
		
			[Parameter( Position = 0, Mandatory = $True )]
			[String]
			$Module,
			
			[Parameter( Position = 1, Mandatory = $True )]
			[String]
			$Procedure
		)

		
		$SystemAssembly = [AppDomain]::CurrentDomain.GetAssemblies() |
			Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }
		$UnsafeNativeMethods = $SystemAssembly.GetType('Microsoft.Win32.UnsafeNativeMethods')
		
		$GetModuleHandle = $UnsafeNativeMethods.GetMethod('GetModuleHandle')
		$GetProcAddress = $UnsafeNativeMethods.GetMethod('GetProcAddress')
		
		$Kern32Handle = $GetModuleHandle.Invoke($null, @($Module))
		$tmpPtr = New-Object IntPtr
		$HandleRef = New-Object System.Runtime.InteropServices.HandleRef($tmpPtr, $Kern32Handle)
		
		
		Write-Output $GetProcAddress.Invoke($null, @([System.Runtime.InteropServices.HandleRef]$HandleRef, $Procedure))
	} 

	
	$LoadLibraryAddr = Get-ProcAddress kernel32.dll LoadLibraryA
	$LoadLibraryDelegate = Get-DelegateType @([String]) ([IntPtr])
	$LoadLibrary = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($LoadLibraryAddr, $LoadLibraryDelegate)
	$HND = $null
	$HND = $LoadLibrary.Invoke('winmm.dll')
	if ($HND -eq $null)
	{
		Throw 'Failed to aquire handle to winmm.dll'
	}

	
	$waveInGetNumDevsAddr = $null
	$waveInGetNumDevsAddr = Get-ProcAddress winmm.dll waveInGetNumDevs
	$waveInGetNumDevsDelegate = Get-DelegateType @() ([Uint32])
	if ($waveInGetNumDevsAddr -eq $null)
	{
		Throw 'Failed to aquire address to WaveInGetNumDevs'
	}
	$waveInGetNumDevs = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($waveInGetNumDevsAddr, $waveInGetNumDevsDelegate)

	
	$mciSendStringAddr = $null
	$mciSendStringAddr = Get-ProcAddress winmm.dll mciSendStringA
	$mciSendStringDelegate = Get-DelegateType @([String],[String],[UInt32],[IntPtr]) ([Uint32])
	if ($mciSendStringAddr -eq $null)
	{
		Throw 'Failed to aquire address to mciSendStringA'
	}
	$mciSendString = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($mciSendStringAddr, $mciSendStringDelegate)

	
	$mciGetErrorStringAddr = $null
	$mciGetErrorStringAddr = Get-ProcAddress winmm.dll mciGetErrorStringA
	$mciGetErrorStringDelegate = Get-DelegateType @([UInt32],[Text.StringBuilder],[UInt32]) ([bool])
	if ($mciGetErrorStringAddr -eq $null)
	{
		Throw 'Failed to aquire address to mciGetErrorString'
	}
	$mciGetErrorString = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($mciGetErrorStringAddr,$mciGetErrorStringDelegate)

	
	$DeviceCount = $waveInGetNumDevs.Invoke()

	if ($DeviceCount -gt 0)
	{

		
		$errmsg = New-Object Text.StringBuilder 150

		
		$rtnVal = $mciSendString.Invoke("open new Type waveaudio Alias $alias",'',0,0)
		if ($rtnVal -ne 0) {$mciGetErrorString.Invoke($rtnVal,$errmsg,150); $msg=$errmsg.ToString();Throw "MCI Error ($rtnVal): $msg"}
		
		
		$rtnVal = $mciSendString.Invoke("record $alias", '', 0, 0)
		if ($rtnVal -ne 0) {$mciGetErrorString.Invoke($rtnVal,$errmsg,150); $msg=$errmsg.ToString();Throw "MCI Error ($rtnVal): $msg"}
		
		Start-Sleep -s $Length

		
		$rtnVal = $mciSendString.Invoke("save $alias `"$path`"", '', 0, 0)
		if ($rtnVal -ne 0) {$mciGetErrorString.Invoke($rtnVal,$errmsg,150); $msg=$errmsg.ToString();Throw "MCI Error ($rtnVal): $msg"}

		
		$rtnVal = $mciSendString.Invoke("close $alias", '', 0, 0);
		if ($rtnVal -ne 0) {$mciGetErrorString.Invoke($rtnVal,$errmsg,150); $msg=$errmsg.ToString();Throw "MCI Error ($rtnVal): $msg"}

		$OutFile = Get-ChildItem -path $path 
		Write-Output $OutFile

	}
	else
	{
		Throw 'Failed to enumerate any recording devices'
	}
}
