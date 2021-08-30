
function Add-GroupUser {
    
    [PoshBot.BotCommand(Permissions = 'manage-groups')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Mandatory, Position = 1)]
        [string]$User
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        
        if ($userId = $Bot.RoleManager.ResolveUsernameToId($User)) {
            try {
                $bot.RoleManager.AddUserToGroup($userId, $Group)
                New-PoshBotCardResponse -Type Normal -Text "User [$User] added to group [$Group]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to add [$User] to group [$Group]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "User [$User] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
