function Get-SyscallDelegate {


	param(
		[Parameter(Mandatory=$True)]
		[ValidateSet(
			'[Byte]',
			'[UInt16]',
			'[UInt32]',
			'[UInt64]',
			'[IntPtr]',
			'[String]')
		]
		$ReturnType,
		[Parameter(Mandatory=$True)]
		[AllowEmptyCollection()]
		[Object[]]$ParameterArray
	)

	Add-Type -TypeDefinition @"
	using System;
	using System.Diagnostics;
	using System.Runtime.InteropServices;
	using System.Security.Principal;
	
	public class Syscall
	{
		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern IntPtr VirtualAlloc(
			IntPtr lpAddress,
			uint dwSize,
			UInt32 flAllocationType,
			UInt32 flProtect);

		[DllImport("kernel32.dll", SetLastError=true)]
		public static extern bool VirtualFree(
			IntPtr lpAddress,
			uint dwSize,
			uint dwFreeType);
	}
"@

	
	
	
	
	
	$x86SyscallStub = [Byte[]] @(
	0x55,                                
	0x89, 0xE5,                          
	0x81, 0xEC, 0x84, 0x00, 0x00, 0x00,  
	0x8B, 0x8D, 0x88, 0x00, 0x00, 0x00,  
	0x51,                                
	0x8B, 0x8D, 0x84, 0x00, 0x00, 0x00,  
	0x51,                                
	0x8B, 0x8D, 0x80, 0x00, 0x00, 0x00,  
	0x51,                                
	0x8B, 0x4D, 0x7C,                    
	0x51,                                
	0x8B, 0x4D, 0x78,                    
	0x51,                                
	0x8B, 0x4D, 0x74,                    
	0x51,                                
	0x8B, 0x4D, 0x70,                    
	0x51,                                
	0x8B, 0x4D, 0x6C,                    
	0x51,                                
	0x8B, 0x4D, 0x68,                    
	0x51,                                
	0x8B, 0x4D, 0x64,                    
	0x51,                                
	0x8B, 0x4D, 0x60,                    
	0x51,                                
	0x8B, 0x4D, 0x5C,                    
	0x51,                                
	0x8B, 0x4D, 0x58,                    
	0x51,                                
	0x8B, 0x4D, 0x54,                    
	0x51,                                
	0x8B, 0x4D, 0x50,                    
	0x51,                                
	0x8B, 0x4D, 0x4C,                    
	0x51,                                
	0x8B, 0x4D, 0x48,                    
	0x51,                                
	0x8B, 0x4D, 0x44,                    
	0x51,                                
	0x8B, 0x4D, 0x40,                    
	0x51,                                
	0x8B, 0x4D, 0x3C,                    
	0x51,                                
	0x8B, 0x4D, 0x38,                    
	0x51,                                
	0x8B, 0x4D, 0x34,                    
	0x51,                                
	0x8B, 0x4D, 0x30,                    
	0x51,                                
	0x8B, 0x4D, 0x2C,                    
	0x51,                                
	0x8B, 0x4D, 0x28,                    
	0x51,                                
	0x8B, 0x4D, 0x24,                    
	0x51,                                
	0x8B, 0x4D, 0x20,                    
	0x51,                                
	0x8B, 0x4D, 0x1C,                    
	0x51,                                
	0x8B, 0x4D, 0x18,                    
	0x51,                                
	0x8B, 0x4D, 0x14,                    
	0x51,                                
	0x8B, 0x4D, 0x10,                    
	0x51,                                
	0x8B, 0x4D, 0x0C,                    
	0x51,                                
	0x8B, 0x45, 0x08,                    
	0xBA, 0x00, 0x03, 0xFE, 0x7F,        
	0xFF, 0x12,                          
	0x89, 0xEC,                          
	0x5D,                                
	0xC3)                                
	
	
	
	
	
	
	$x64SyscallStub = [Byte[]] @(
	0x55,                                      
	0x48, 0x89, 0xE5,                          
	0x48, 0x81, 0xEC, 0x18, 0x01, 0x00, 0x00,  
	0x48, 0x89, 0xC8,                          
	0x49, 0x89, 0xD2,                          
	0x4C, 0x89, 0xC2,                          
	0x4D, 0x89, 0xC8,                          
	0x48, 0x8B, 0x8D, 0x10, 0x01, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0x08, 0x01, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0x00, 0x01, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xF8, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xF0, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xE8, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xE0, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xD8, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xD0, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xC8, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xC0, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xB8, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xB0, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xA8, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0xA0, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0x98, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0x90, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0x88, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x8D, 0x80, 0x00, 0x00, 0x00,  
	0x51,                                      
	0x48, 0x8B, 0x4D, 0x78,                    
	0x51,                                      
	0x48, 0x8B, 0x4D, 0x70,                    
	0x51,                                      
	0x48, 0x8B, 0x4D, 0x68,                    
	0x51,                                      
	0x48, 0x8B, 0x4D, 0x60,                    
	0x51,                                      
	0x48, 0x8B, 0x4D, 0x58,                    
	0x51,                                      
	0x48, 0x8B, 0x4D, 0x50,                    
	0x51,                                      
	0x48, 0x8B, 0x4D, 0x48,                    
	0x51,                                      
	0x48, 0x8B, 0x4D, 0x40,                    
	0x51,                                      
	0x48, 0x8B, 0x4D, 0x38,                    
	0x51,                                      
	0x4C, 0x8B, 0x4D, 0x30,                    
	0x4C, 0x89, 0xD1,                          
	0x0F, 0x05,                                
	0x48, 0x89, 0xEC,                          
	0x5D,                                      
	0xC3)                                      

	if (!$SyscallStubPointer) {
		
		if ([System.IntPtr]::Size -eq 4) {
			[IntPtr]$Script:SyscallStubPointer = [Syscall]::VirtualAlloc([System.IntPtr]::Zero, $x86SyscallStub.Length, 0x3000, 0x40)
			[System.Runtime.InteropServices.Marshal]::Copy($x86SyscallStub, 0, $SyscallStubPointer, $x86SyscallStub.Length)
		} else {
			[IntPtr]$Script:SyscallStubPointer = [Syscall]::VirtualAlloc([System.IntPtr]::Zero, $x64SyscallStub.Length, 0x3000, 0x40)
			[System.Runtime.InteropServices.Marshal]::Copy($x64SyscallStub, 0, $SyscallStubPointer, $x64SyscallStub.Length)
		}
	}

	
	
	Function Get-DelegateType
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

	
	if ($ParameterArray) {
		$ParamCount = $ParameterArray.Length
		$ParamList = [String]::Empty
		for ($i=0;$i-lt$ParamCount;$i++) {
			if ($ParameterArray[$i].Value) {
				$ParamList += "[" + $ParameterArray[$i].Value.Name + "].MakeByRefType(), "
			} else {
				$ParamList += "[" + $ParameterArray[$i].Name + "], "
			}
		}
		$ParamList = ($ParamList.Substring(0,$ParamList.Length-2)).Insert(0,", ")
	}
	$IEXBootstrap = "Get-DelegateType @([UInt16] $ParamList) ($ReturnType)"
	$SyscallDelegate = IEX $IEXBootstrap
	[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($SyscallStubPointer, $SyscallDelegate)
}