
function Add-GroupRole {
    
    [PoshBot.BotCommand(
        Permissions = 'manage-groups'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Mandatory, Position = 1)]
        [string]$Role
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        if ($r = $Bot.RoleManager.GetRole($Role)) {
            try {
                $bot.RoleManager.AddRoleToGroup($Role, $Group)
                New-PoshBotCardResponse -Type Normal -Text "Role [$Role] added to group [$Group]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to add [$Role] to group [$Group]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
