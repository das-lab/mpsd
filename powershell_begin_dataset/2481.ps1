


function Copy-AzureItem
{
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[Alias('FullName')]
		[string]$FilePath,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ContainerName,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ResourceGroupName,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$StorageAccountName,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$DestinationName,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Page', 'Block')]
		[string]$BlobType = 'Page'
	)
	begin
	{
		$ErrorActionPreference = 'Stop'
	}
	process
	{
		try
		{
			$saParams = @{
				'ResourceGroupName' = $ResourceGroupName
				'Name' = $StorageAccountName
			}
			
			$storageContainer = Get-AzureRmStorageAccount @saParams | Get-AzureStorageContainer -Container $ContainerName
			
			if (-not $PSBoundParameters.ContainsKey('DestinationName'))
			{
				$DestinationName = $FilePath | Split-Path -Leaf
			}
			
			
			if ($FilePath.EndsWith('.vhd'))
			{
				$destination = ('{0}{1}/{2}' -f $storageContainer.Context.BlobEndPoint, $ContainerName, $DestinationName)
				$vhdParams = @{
					'ResourceGroupName' = $ResourceGroupName
					'Destination' = $destination
					'LocalFilePath' = $FilePath
				}
				Write-Verbose -Message "Uploading [$($vhdParams.LocalFilePath)] to [$($vhdParams.Destination)] in resource group [$($vhdParams.ResourceGroupName)]..."
				Add-AzureRmVhd @vhdParams
			}
			else
			{
				$bcParams = @{
					'File' = $FilePath
					'BlobType' = $BlobType
					'Blob' = $DestinationName
				}
				$storageContainer | Set-AzureStorageBlobContent @bcParams
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}