Function Lock-Computer
{
	

$signature = @"
[DllImport("user32.dll", SetLastError = true)]
public static extern bool LockWorkStation();
"@

	$LockComputer = Add-Type -memberDefinition $signature -name "Win32LockWorkStation" -namespace Win32Functions -passthru
	$LockComputer::LockWorkStation() | Out-Null
}