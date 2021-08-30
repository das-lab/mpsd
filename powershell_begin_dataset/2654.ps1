Try {
	
	If (([System.Diagnostics.Process]::GetCurrentProcess() | Select "SessionID" -ExpandProperty "SessionID") -eq 0) { 
		Exit 1 
	}
	Else {
		Exit 0 
	}
}
Catch {
	Exit 2 
}