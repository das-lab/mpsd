














function Test-Capabilities
{
	$location = "eastus"
	$all = Get-AzSqlCapability $location
	Validate-Capabilities $all

	$default = Get-AzSqlCapability $location -Defaults
	Validate-Capabilities $default

	$version = Get-AzSqlCapability $location -ServerVersionName "12.0"
	Validate-Capabilities $default

	$edition = Get-AzSqlCapability $location -EditionName "Premium"
	Validate-Capabilities $default

	$so = Get-AzSqlCapability $location -ServiceObjectiveName "S3"
	Validate-Capabilities $default

}


function Validate-Capabilities ($capabilities)
{
	Assert-NotNull $capabilities
	Assert-AreEqual $capabilities.Status "Default"
	Assert-True {$capabilities.SupportedServerVersions.Count -gt 0}

	foreach($version in $capabilities.SupportedServerVersions) {
		Assert-NotNull $version
		Assert-NotNull $version.ServerVersionName
		Assert-NotNull $version.Status
		Assert-True {$version.SupportedEditions.Count -gt 0}

		foreach($edition in $version.SupportedEditions) {
			Assert-NotNull $edition
			Assert-NotNull $edition.EditionName
			Assert-NotNull $edition.Status
			Assert-True {$edition.SupportedServiceObjectives.Count -gt 0}

			foreach($so in $edition.SupportedServiceObjectives) {
				Assert-NotNull $so
				Assert-NotNull $so.ServiceObjectiveName
				Assert-NotNull $so.Status
				Assert-NotNull $so.Id
				Assert-AreNotEqual $so.Id [System.Guid]::Empty
				

				foreach($size in $so.SupportedMaxSizes) {
					Assert-NotNull $size
					Assert-NotNull $size.MinValue.Limit
					Assert-True { $size.MinValue.Limit -gt 0 }
					Assert-NotNull $size.MinValue.Unit

					Assert-NotNull $size.MaxValue.Limit
					Assert-True { $size.MaxValue.Limit -gt 0 }
					Assert-NotNull $size.MaxValue.Unit

					Assert-NotNull $size.ScaleSize.Limit
					Assert-NotNull $size.ScaleSize.Unit

					Assert-NotNull $size.Status
				}
			}
		}
	}
}
