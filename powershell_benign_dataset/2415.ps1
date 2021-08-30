
function Get-DPContent {
	[CmdletBinding()]
	[OutputType([PSObject[]])]
	Param
	(
		
		[Parameter(Mandatory = $true,
				   ValueFromPipeline,
				   ValueFromPipelineByPropertyName)]
		[string[]]$DPname,
		
		
		[Parameter()]
		[ValidateSet("Package", "Application", "ImagePackage", "BootImagePackage", "DriverPackage", "SoftwareUpdatePackage")]
		[string]$ObjectType = "Package",
		
		
		[Parameter(Mandatory = $false)]
		[Alias("SMSProvider")]
		[String]$SCCMServer = "dexsccm"
	)
	
	begin {
		Write-Verbose -Message "[BEGIN] Starting Function"
		
		$CIMSessionParams = @{
			ComputerName = $SCCMServer
			ErrorAction = 'Stop'
		}
		try {
			if ((Test-WSMan -ComputerName $SCCMServer -ErrorAction SilentlyContinue).ProductVersion -match 'Stack: 3.0') {
				Write-Verbose -Message "[BEGIN] WSMAN is responsive"
				$CimSession = New-CimSession @CIMSessionParams
				$CimProtocol = $CimSession.protocol
				Write-Verbose -Message "[BEGIN] [$CimProtocol] CIM SESSION - Opened"
			} else {
				Write-Verbose -Message "[PROCESS] Attempting to connect with protocol: DCOM"
				$CIMSessionParams.SessionOption = New-CimSessionOption -Protocol Dcom
				$CimSession = New-CimSession @CIMSessionParams
				$CimProtocol = $CimSession.protocol
				
				Write-Verbose -Message "[BEGIN] [$CimProtocol] CIM SESSION - Opened"
			}
			
			
			
			$sccmProvider = Get-CimInstance -query "select * from SMS_ProviderLocation where ProviderForLocalSite = true" -Namespace "root\sms" -CimSession $CimSession -ErrorAction Stop
			
			$Splits = $sccmProvider.NamespacePath -split "\\", 4
			Write-Verbose "[BEGIN] Provider is located on $($sccmProvider.Machine) in namespace $($splits[3])"
			
			
			$hash = @{ "CimSession" = $CimSession; "NameSpace" = $Splits[3]; "ErrorAction" = "Stop" }
			
			switch -exact ($ObjectType) {
				'Package' { $ObjectTypeID = 2; $ObjectClass = "SMS_Package"; break }
				'Application' { $ObjectTypeID = 31; $ObjectClass = "SMS_Application"; break }
				'ImagePackage' { $ObjectTypeID = 18; $ObjectClass = "SMS_ImagePackage"; break }
				'BootImagePackage' { $ObjectTypeID = 19; $ObjectClass = "SMS_BootImagePackage"; break }
				'DriverPackage' { $ObjectTypeID = 23; $ObjectClass = "SMS_DriverPackage"; break }
				'SoftwareUpdatePackage' { $ObjectTypeID = 24; $ObjectClass = "SMS_SoftwareUpdatesPackage"; break }
			}
		} catch {
			Write-Warning "[BEGIN] $SCCMServer needs to have SMS Namespace Installed"
			throw $Error[0].Exception
		}
	}
	
	process {
		foreach ($DP in $DPname) {
			Write-Verbose -Message "[PROCESS] Working with Distribution Point $DP"
			try {
				if ($ObjectType -eq "Application") {
					
					$SecureObjectIDs = Get-CimInstance -query "Select SecureObjectID from SMS_DistributionPoint Where (ServerNALPath LIKE '%$DP%') AND (ObjectTypeID='$ObjectTypeID')" @hash | select -ExpandProperty SecureObjectId
					
					$SecureObjectIDs | foreach {
						if ($App = Get-CimInstance -query "Select LocalizedDisplayName,LocalizedDescription from $ObjectClass WHERE ModelName='$_'" @hash | select -Unique) {
							[pscustomobject]@{
								DP = $DP
								ObjectType = $ObjectType
								Application = $App.LocalizedDisplayName
								Description = $app.LocalizedDescription
							}
						}
					}
				} else {
					$PackageIDs = Get-CimInstance -query "Select SecureObjectID from SMS_DistributionPoint Where (ServerNALPath LIKE '%$DP%') AND (ObjectTypeID='$ObjectTypeID')" @hash | select -ExpandProperty SecureObjectID
					
					$PackageIDs | foreach {
						if ($Package = Get-CimInstance -query "Select Name from $ObjectClass WHERE PackageID='$_'" @hash) {
							[pscustomobject]@{
								DP = $DP
								ObjectType = $ObjectType
								Package = $Package.Name
								PackageID = $_
							}
						}
					}
				}
			} catch {
				Write-Warning "[PROCESS] Something went wrong while querying $SCCMServer for the DP or Object info"
				throw $_.Exception
			}
		}
	}
	end {
		Write-Verbose -Message "[END] Ending Function"
		Remove-CimSession -CimSession $CimSession
	}
}