






Function RenameWindow ($Title) {

	
	Set-Variable -Name a -Scope Local -Force
	
	$a = (Get-Host).UI.RawUI
	$a.WindowTitle = $Title
	
	
	Remove-Variable -Name a -Scope Local -Force
}

Function UninstallName($Description) {

	
	Set-Variable -Name AppName -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	Set-Variable -Name Result -Scope Local -Force
	Set-Variable -Name GUID -Scope Local -Force
	Set-Variable -Name Output -Scope Local -Force
	Set-Variable -Name Output1 -Scope Local -Force
	
	
	$Description = [char]34+"description like"+[char]32+[char]39+[char]37+$Description+[char]37+[char]39+[char]34
	$Output1 = wmic product where $Description get Description
	$Output1 | ForEach-Object {
		$_ = $_.Trim()
    	if(($_ -ne "Description")-and($_ -ne "")){
        	$AppName = $_
    	}
	}
	If ($AppName -eq $null) {
		return
	}
	Write-Host "Uninstalling"$AppName"....." -NoNewline
	$Output = wmic product where $Description get IdentifyingNumber
	$Output | ForEach-Object {
		$_ = $_.Trim()
	   	if(($_ -ne "IdentifyingNumber")-and($_ -ne "")){
	       	$GUID = $_
	   	}
	}
	$Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"
	$Result = (Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode
	If ($Result -eq 0) {
		Write-Host "Uninstalled" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$Result -ForegroundColor Red
	}
	
	
	Remove-Variable -Name AppName -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
	Remove-Variable -Name Result -Scope Local -Force
	Remove-Variable -Name GUID -Scope Local -Force
	Remove-Variable -Name Output -Scope Local -Force
	Remove-Variable -Name Output1 -Scope Local -Force
	
}

Function UninstallGUID($Application,$GUID) {
	
	
	Set-Variable -Name Result -Scope Local -Force
	Set-Variable -Name Arguments -Scope Local -Force
	
	Write-Host $Application"...." -NoNewline
	$Arguments = "/x "+$GUID+" /qb- /norestart"
	$Result = (Start-Process -FilePath msiexec.exe -ArgumentList $Arguments -Wait -Passthru).ExitCode
	If ($Result -eq 0) {
		Write-Host "Uninstalled" -ForegroundColor Yellow
	} elseIf ($Result -eq 1605) {
		Write-Host "Not Installed" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$Result -ForegroundColor Red
	}
	
	
	Remove-Variable -Name Result -Scope Local -Force
	Remove-Variable -Name Arguments -Scope Local -Force
	
}

cls
RenameWindow "Autodesk 2014 Uninstaller"

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
If ($args -ne $null) {
	$args = $args.ToLower()
}
If ($args -eq "architecture") {
	
	UninstallGUID "Revit 2014" "{7346B4A0-1400-0510-0000-705C0D862004}"
	UninstallName "Autodesk Workflows 2014"
	UninstallGUID "Revit 2014 Language Pack - English" "{7346B4A0-1400-0511-0409-705C0D862004}"
	UninstallGUID "Autodesk Material Library 2014" "{644F9B19-A462-499C-BF4D-300ABC2A28B1}"
	UninstallGUID "Autodesk Material Library Base Resolution Image Library 2014" "{51BF3210-B825-4092-8E0D-66D689916E02}"
	UninstallGUID "Autodesk Material Library Low Resolution Image Library 2014" "{5C29CC1F-218F-4C30-948A-11066CAC59FB}"
	UninstallGUID "Autodesk Content Service" "{62F029AB-85F2-0000-866A-9FC0DD99DDBC}"
	UninstallGUID "Autodesk Content Service Language Pack" "{62F029AB-85F2-0001-866A-9FC0DD99DDBC}"
	UninstallGUID "AutoCAD 2014 - English" "{5783F2D7-D001-0000-0102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD 2014 Language Pack - English" "{5783F2D7-D001-0409-1102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD 2014 - English" "{5783F2D7-D001-0409-2102-0060B0CE6BBA}"
	UninstallGUID "Autodesk Navisworks 2014 64 bit Exporter Plug-ins" "{914E5049-303D-5993-9734-CF12636383B4}"
	UninstallGUID "Autodesk Navisworks 2014 64 bit Exporter Plug-ins English Language Pack" "{914E5049-303D-0409-9734-CF12636383B4}"
	UninstallGUID "Autodesk Material Library Medium Resolution Image Library 2014" "{A0633D4E-5AF2-4E3E-A70A-FE9C2BD8A958}"
	UninstallGUID "Autodesk Revit Interoperability for 3ds Max 2014" "{0BB716E0-1400-0610-0000-097DC2F354DF}"
	UninstallGUID "Autodesk 3ds Max Design 2014" "{52B37EC7-D836-0409-0164-3C24BCED2010}"
	UninstallName "Autodesk 3ds Max Design 2014 SP2"
	UninstallGUID "Autodesk 3ds Max Design 2014 64-bit Populate Data" "{2BCAFE22-BE25-4437-815C-54596D630397}"
	UninstallGUID "Autodesk DirectConnect 2014 64-bit" "{8FC7C2B2-0F64-4B35-AA3D-2B051D009243}"
	UninstallGUID "Autodesk Inventor Server Engine for 3ds Max Design 2014 64-bit" "{CBC74B06-FE35-482C-89D6-CE95A0289C06}"
	UninstallGUID "Autodesk Composite 2014" "{5AAB972C-FF31-4B01-8445-50C42860EC02}"
	UninstallGUID "Autodesk Revit Interoperability for Showcase 2014" "{0BB716E0-1400-0410-0000-097DC2F354DF}"
	UninstallGUID "AutoCAD Architecture 2014 - English" "{5783F2D7-D004-0000-0102-0060B0CE6BBA}"
	UninstallGUID "Autodesk 360" "{52B28CAD-F49D-47BA-9FFE-29C2E85F0D0B}"
	UninstallGUID "Autodesk Showcase 2014 64-bit" "{42FCE681-2220-4EAA-8E39-20B527585547}"
	UninstallGUID "Autodesk SketchBook Designer 2014" "{4057E6CF-C9AC-45D7-87D4-A8FAE305AAC1}"
	UninstallGUID "Autodesk SketchBook Designer for AutoCAD 2014" "{8BFDC12D-7F32-4F77-95DE-D1A42BAC91DD}"
	UninstallName "Autodesk Backburner 2014"
	UninstallGUID "Autodesk Essential Skills Movies for 3ds Max Design 2014 64-bit" "{280881E4-0E3C-40E6-9B76-E05A865551BB}"
	UninstallGUID "AutoCAD Architecture 2014 Language Pack - English" "{5783F2D7-D004-0409-1102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD Architecture 2014 - English" "{5783F2D7-D004-0409-2102-0060B0CE6BBA}"
	UninstallGUID "SketchUp Import for AutoCAD 2014" "{644E9589-F73A-49A4-AC61-A953B9DE5669}"
} elseif ($args -eq "engineering") {
	
	UninstallGUID "Revit 2014" "{7346B4A0-1400-0510-0000-705C0D862004}"
	UninstallName "Autodesk Workflows 2014"
	UninstallGUID "Revit 2014 Language Pack - English" "{7346B4A0-1400-0511-0409-705C0D862004}"
	UninstallGUID "Autodesk Material Library 2014" "{644F9B19-A462-499C-BF4D-300ABC2A28B1}"
	UninstallGUID "Autodesk Material Library Base Resolution Image Library 2014" "{51BF3210-B825-4092-8E0D-66D689916E02}"
	UninstallGUID "Autodesk Material Library Low Resolution Image Library 2014" "{5C29CC1F-218F-4C30-948A-11066CAC59FB}"
	UninstallGUID "Autodesk Content Service" "{62F029AB-85F2-0000-866A-9FC0DD99DDBC}"
	UninstallGUID "Autodesk Content Service Language Pack" "{62F029AB-85F2-0001-866A-9FC0DD99DDBC}"
	UninstallGUID "AutoCAD 2014 - English" "{5783F2D7-D001-0000-0102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD 2014 Language Pack - English" "{5783F2D7-D001-0409-1102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD 2014 - English" "{5783F2D7-D001-0409-2102-0060B0CE6BBA}"
	UninstallGUID "Autodesk 360" "{52B28CAD-F49D-47BA-9FFE-29C2E85F0D0B}"
	UninstallGUID "SketchUp Import for AutoCAD 2014" "{644E9589-F73A-49A4-AC61-A953B9DE5669}"
	UninstallGUID "Autodesk Navisworks 2014 64 bit Exporter Plug-ins" "{914E5049-303D-5993-9734-CF12636383B4}"
	UninstallGUID "Autodesk Navisworks 2014 64 bit Exporter Plug-ins English Language Pack" "{914E5049-303D-0409-9734-CF12636383B4}"
	UninstallGUID "Autodesk Material Library Medium Resolution Image Library 2014" "{A0633D4E-5AF2-4E3E-A70A-FE9C2BD8A958}"
	UninstallGUID "Autodesk Revit Interoperability for 3ds Max 2014" "{0BB716E0-1400-0610-0000-097DC2F354DF}"
	UninstallGUID "Autodesk 3ds Max Design 2014" "{52B37EC7-D836-0409-0164-3C24BCED2010}"
	UninstallName "Autodesk 3ds Max Design 2014 SP2"
	UninstallGUID "Autodesk 3ds Max Design 2014 64-bit Populate Data" "{2BCAFE22-BE25-4437-815C-54596D630397}"
	UninstallGUID "Autodesk DirectConnect 2014 64-bit" "{8FC7C2B2-0F64-4B35-AA3D-2B051D009243}"
	UninstallGUID "Autodesk Inventor Server Engine for 3ds Max Design 2014 64-bit" "{CBC74B06-FE35-482C-89D6-CE95A0289C06}"
	UninstallGUID "Autodesk Composite 2014" "{5AAB972C-FF31-4B01-8445-50C42860EC02}"
	UninstallName "Autodesk® Backburner 2014"
	UninstallGUID "Autodesk Essential Skills Movies for 3ds Max Design 2014 64-bit" "{280881E4-0E3C-40E6-9B76-E05A865551BB}"
} elseif ($args -eq "civil3d") {
	
	UninstallGUID "Autodesk Material Library 2014" "{644F9B19-A462-499C-BF4D-300ABC2A28B1}"
	UninstallGUID "Autodesk Material Library Base Resolution Image Library 2014" "{51BF3210-B825-4092-8E0D-66D689916E02}"
	UninstallGUID "Autodesk Content Service" "{62F029AB-85F2-0000-866A-9FC0DD99DDBC}"
	UninstallGUID "Autodesk Content Service Language Pack" "{62F029AB-85F2-0001-866A-9FC0DD99DDBC}"
	UninstallGUID "Autodesk AutoCAD Civil 3D 2014" "{5783F2D7-D000-0409-0102-0060B0CE6BBA}"
	UninstallGUID "Autodesk AutoCAD Civil 3D 2014 Language Pack - English" "{5783F2D7-D000-0409-1102-0060B0CE6BBA}"
	UninstallGUID "Autodesk AutoCAD Civil 3D 2014 - English" "{5783F2D7-D000-0409-2102-0060B0CE6BBA}"
	UninstallGUID "Autodesk 360" "{52B28CAD-F49D-47BA-9FFE-29C2E85F0D0B}"
	UninstallGUID "SketchUp Import for AutoCAD 2014" "{644E9589-F73A-49A4-AC61-A953B9DE5669}"
	UninstallName "Autodesk AutoCAD Civil 3D 2014 64 Bit Object Enabler on Autodesk 360 - Language Neutral"
	UninstallGUID "Autodesk® Storm and Sanitary Analysis 2014" "{6BBA09C8-6B20-4115-B917-C09D8337AE09}"
	UninstallGUID "Autodesk® Storm and Sanitary Analysis 2014 x64 Plug-in" "{F49CAD53-8F0F-441A-B974-CA5C3D7D03C1}"
	UninstallName "Autodesk AutoCAD Civil 3D 2014 32 bit Object Enabler"
	UninstallGUID "Autodesk ReCap" "{31ABA3F2-0000-1033-0102-111D43815377}"
	UninstallGUID "Autodesk ReCap Language Pack-English" "{31ABA3F2-0010-1033-0102-111D43815377}"
	UninstallGUID "Autodesk App Manager" "{C070121A-C8C5-4D52-9A7D-D240631BD433}"
	UninstallGUID "Autodesk Featured Apps" "{F732FEDA-7713-4428-934B-EF83B8DD65D0}"
} else {
	

	UninstallGUID "Revit 2014" "{7346B4A0-1400-0510-0000-705C0D862004}"
	UninstallName "Autodesk Workflows 2014"
	UninstallGUID "Autodesk Material Library 2014" "{644F9B19-A462-499C-BF4D-300ABC2A28B1}"
	UninstallGUID "Autodesk Material Library Base Resolution Image Library 2014" "{51BF3210-B825-4092-8E0D-66D689916E02}"
	UninstallGUID "Autodesk Material Library Low Resolution Image Library 2014" "{5C29CC1F-218F-4C30-948A-11066CAC59FB}"
	UninstallGUID "DWG TrueView 2014" "{5783F2D7-D028-0409-0100-0060B0CE6BBA}"
	UninstallGUID "Autodesk Content Service" "{62F029AB-85F2-0000-866A-9FC0DD99DDBC}"
	UninstallGUID "AutoCAD 2014 - English" "{5783F2D7-D001-0000-0102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD Structural Detailing 2014 - English" "{5783F2D7-D030-0000-0102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD Architecture 2014 - English" "{5783F2D7-D004-0000-0102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD MEP 2014 - English" "{5783F2D7-D006-0000-0102-0060B0CE6BBA}"
	UninstallGUID "Autodesk 360" "{52B28CAD-F49D-47BA-9FFE-29C2E85F0D0B}"
	UninstallGUID "Autodesk Design Review 2013" "{153DB567-6FF3-49AD-AC4F-86F8A3CCFDFB}"
	UninstallGUID "Autodesk Revit Interoperability for Inventor 2014" "{0BB716E0-1400-0210-0000-097DC2F354DF}"
	UninstallGUID "Autodesk Inventor 2014" "{7F4DD591-1864-0001-0000-7107D70F3DB4}"
	UninstallName "Eco Materials Adviser for Autodesk Inventor 2014 (64-bit)"
	UninstallName "Microsoft SQL Server 2008 Native Client"
	UninstallGUID "Revit 2014 Language Pack - English" "{7346B4A0-1400-0511-0409-705C0D862004}"
	UninstallGUID "Autodesk Content Service Language Pack" "{62F029AB-85F2-0001-866A-9FC0DD99DDBC}"
	UninstallGUID "AutoCAD 2014 Language Pack - English" "{5783F2D7-D001-0409-1102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD 2014 - English" "{5783F2D7-D001-0409-2102-0060B0CE6BBA}"
	UninstallGUID "Autodesk Navisworks Manage 2014" "{22332F6C-46C6-0000-9863-06EE744B0218}"
	UninstallGUID "Autodesk Navisworks Manage 2014 English Language Pack" "{22332F6C-46C6-0409-9863-06EE744B0218}"
	UninstallGUID "Autodesk Navisworks Manage 2014 - 2014 DWG File Reader" "{82562ABD-3D6B-4845-9D11-60A649D727F1}"
	UninstallGUID "Autodesk Navisworks Manage 2014 - 2013 DWG File Reader" "{C877FD20-CB02-42E5-BA97-283260216417}"
	UninstallGUID "Autodesk Navisworks Manage 2014 - 2012 DWG File Reader" "{CE4E85D0-26F7-40D8-A639-F4F16ED205BC}"
	UninstallGUID "Autodesk Navisworks Manage 2014 - 2011 DWG File Reader" "{B6DD48B0-1941-4E04-993B-1986CF000735}"
	UninstallGUID "Autodesk Navisworks Manage 2014 - 2010 DWG File Reader" "{087CA76C-9188-4F47-B08B-22374918AF19}"
	UninstallGUID "Autodesk Navisworks Manage 2014 - 2009 DWG File Reader" "{80BBD08D-5477-4437-881D-F0D16C13F1B8}"
	UninstallGUID "Autodesk Navisworks Manage 2014 - 2008 DWG File Reader" "{452519E8-B784-4519-8BEB-CC62D31E5A0D}"
	UninstallGUID "Autodesk Navisworks 2014 64 bit Exporter Plug-ins" "{914E5049-303D-5993-9734-CF12636383B4}"
	UninstallGUID "Autodesk Navisworks 2014 64 bit Exporter Plug-ins English Language Pack" "{914E5049-303D-0409-9734-CF12636383B4}"
	UninstallGUID "Autodesk Robot Structural Analysis Professional 2014" "{A3BD9E70-84AD-4E93-A92F-E6A245CD786C}"
	UninstallGUID "Autodesk Robot Structural Analysis Professional 2014 - English regional settings" "{F9F0C54F-A993-488C-8CC9-4E74001F83A6}"
	UninstallName "Autodesk Robot Structural Analysis Professional 2014 Autodesk Robot Structural Analysis Professional 2014 Service Pack 1"
	UninstallGUID "Autodesk Material Library Medium Resolution Image Library 2014" "{A0633D4E-5AF2-4E3E-A70A-FE9C2BD8A958}"
	UninstallGUID "Autodesk Revit Interoperability for 3ds Max 2014" "{0BB716E0-1400-0610-0000-097DC2F354DF}"
	UninstallGUID "Autodesk 3ds Max Design 2014" "{52B37EC7-D836-0409-0164-3C24BCED2010}"
	UninstallGUID "Autodesk 3ds Max Design 2014 64-bit Populate Data" "{2BCAFE22-BE25-4437-815C-54596D630397}"
	UninstallGUID "Autodesk DirectConnect 2014 64-bit" "{8FC7C2B2-0F64-4B35-AA3D-2B051D009243}"
	UninstallGUID "Autodesk Inventor Server Engine for 3ds Max Design 2014 64-bit" "{CBC74B06-FE35-482C-89D6-CE95A0289C06}"
	UninstallGUID "Autodesk Composite 2014" "{5AAB972C-FF31-4B01-8445-50C42860EC02}"
	UninstallGUID "Autodesk Revit Interoperability for Showcase 2014" "{0BB716E0-1400-0410-0000-097DC2F354DF}"
	UninstallGUID "Autodesk Showcase 2014 64-bit" "{42FCE681-2220-4EAA-8E39-20B527585547}"
	UninstallGUID "AutoCAD Structural Detailing 2014 Language Pack - English" "{5783F2D7-D030-0409-1102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD Structural Detailing 2014 - English" "{5783F2D7-D030-0409-2102-0060B0CE6BBA}"
	UninstallGUID "Autodesk SketchBook Designer 2014" "{4057E6CF-C9AC-45D7-87D4-A8FAE305AAC1}"
	UninstallGUID "Autodesk Inventor 2014 English Language Pack" "{7F4DD591-1864-0001-1033-7107D70F3DB4}"
	UninstallGUID "Autodesk InfraWorks 2014" "{58E36D07-3001-0000-0102-C854F44898ED}"
	UninstallName "Autodesk Inventor 2014 Content Libraries"
	UninstallGUID "Autodesk SketchBook Designer for AutoCAD 2014" "{8BFDC12D-7F32-4F77-95DE-D1A42BAC91DD}"
	UninstallGUID "Autodesk ReCap" "{31ABA3F2-0000-1033-0102-111D43815377}"
	UninstallGUID "Autodesk ReCap Language Pack-English" "{31ABA3F2-0010-1033-0102-111D43815377}"
	UninstallName "Autodesk® Backburner 2014"
	UninstallGUID "Autodesk Essential Skills Movies for 3ds Max Design 2014 64-bit" "{280881E4-0E3C-40E6-9B76-E05A865551BB}"
	UninstallGUID "AutoCAD Architecture 2014 Language Pack - English" "{5783F2D7-D004-0409-1102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD Architecture 2014 - English" "{5783F2D7-D004-0409-2102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD MEP 2014 Language Pack - English" "{5783F2D7-D006-0409-1102-0060B0CE6BBA}"
	UninstallGUID "AutoCAD MEP 2014 - English" "{5783F2D7-D006-0409-2102-0060B0CE6BBA}"
	UninstallGUID "SketchUp Import for AutoCAD 2014" "{644E9589-F73A-49A4-AC61-A953B9DE5669}"
	UninstallGUID "AutoCAD Raster Design 2014" "{5783F2D7-D031-0409-0102-0060B0CE6BBA}"
	UninstallName "Autodesk AutoCAD Structural Detailing 2014 Object Enabler"
}