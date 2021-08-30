

param([parameter(Mandatory=$true)][string] $newdata,
			[parameter(Mandatory=$true)][string] $newlog,
			[string] $instance="localhost",
      [string] $outputfile=([Environment]::GetFolderPath("MyDocuments"))+"`\FileMover.ps1")




[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null


$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $instance


$db_list=$server.Databases




"[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') `"$instance`" | out-null" >> $outputfile
"`$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server " >> $outputfile

foreach($db_build in $db_list)
{
	
	if(!($db_build.IsSystemObject))
	{
		
		"
		"`$db=`$server.Databases[`""+$db_build.Name+"`"]" >> $outputfile

		$dbchange = @()
		$robocpy =@()
		foreach ($fg in $db_build.Filegroups)
		{
			foreach($file in $fg.Files)
			{
				$shortfile=$file.Filename.Substring($file.Filename.LastIndexOf('\')+1)
				$oldloc=$file.Filename.Substring(0,$file.Filename.LastIndexOf('\'))
				$dbchange+="`$db.FileGroups[`""+$fg.Name+"`"].Files[`""+$file.Name+"`"].Filename=`"$newdata`\"+$shortfile+"`""
				$robocpy+="ROBOCOPY `"$oldloc`" `"$newdata`" $shortfile /copyall /mov"

			}
		}

		foreach($logfile in $db_build.LogFiles)
		{
			$shortfile=$logfile.Filename.Substring($logfile.Filename.LastIndexOf('\')+1)
			$oldloc=$logfile.Filename.Substring(0,$logfile.Filename.LastIndexOf('\'))
			$dbchange+="`$db.LogFiles[`""+$logfile.Name+"`"].Filename=`"$newlog`\"+$shortfile+"`""
			$robocpy+="ROBOCOPY `"$oldloc`" `"$newlog`" $shortfile"
		}

		$dbchange+="`$db.Alter()"
		$dbchange+="Invoke-Sqlcmd -Query `"ALTER DATABASE ["+$db_build.Name+"] SET OFFLINE WITH ROLLBACK IMMEDIATE;`" -ServerInstance `"$instance`" -Database `"master`""

		$dbchange >> $outputfile
		$robocpy >> $outputfile

		"Invoke-Sqlcmd -Query `"ALTER DATABASE ["+$db_build.Name+"] SET ONLINE;`" -ServerInstance `"$instance`" -Database `"master`""  >> $outputfile
	}
}