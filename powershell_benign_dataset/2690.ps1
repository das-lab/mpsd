function Register-ProcessModuleTrace
{


    [CmdletBinding()] Param ()

    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
    {
        throw 'You must run this cmdlet from an elevated PowerShell session.'
    }

    $ModuleLoadedAction = {
        $Event = $EventArgs.NewEvent

        $ModuleInfo = @{
            TimeCreated = [DateTime]::FromFileTime($Event.TIME_CREATED)
            ProcessId = $Event.ProcessId
            FileName = $Event.FileName
            ImageBase = $Event.ImageBase
            ImageSize = $Event.ImageSize
        }

        $ModuleObject = New-Object PSObject -Property $ModuleInfo
        $ModuleObject.PSObject.TypeNames[0] = 'LOADED_MODULE'

        $ModuleObject
    }

    Register-WmiEvent 'Win32_ModuleLoadTrace' -SourceIdentifier 'ModuleLoaded' -Action $ModuleLoadedAction
}

function Get-ProcessModuleTrace
{


    $Events = Get-EventSubscriber -SourceIdentifier 'ModuleLoaded' -ErrorVariable NoEventRegistered -ErrorAction SilentlyContinue

    if ($NoEventRegistered)
    {
        throw 'You must execute Register-ProcessModuleTrace before you can retrieve a loaded module list'
    }

    $Events.Action.Output
}

function Unregister-ProcessModuleTrace
{


    Unregister-Event -SourceIdentifier 'ModuleLoaded'
}
