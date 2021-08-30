

function Format-FileSize{



	[CmdletBinding()]
	param(        
		[Parameter(Position=0, Mandatory=$true)]
		[int]
		$Size
	)
    
    
    
    
	
    If($Size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf($Size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf($Size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf($Size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf($Size -gt 0)   {[string]::Format("{0:0.00} B", $size)}
    Else{""}
}
