enum DiscordChannelType {
    GUILD_TEXT     = 0
    DM             = 1
    GUILD_VOICE    = 2
    GROUP_DM       = 3
    GUILD_CATEGORY = 4
    GUILD_NEWS     = 5
    GUILD_STORE    = 6
}

class DiscordChannel : Room {
    
    [DiscordChannelType]$Type

    
    [string]$GuildId

    
    [int]$Position

    
    [bool]$NSFW

    
    [string]$LastMessageId

    
    [int]$Bitrate

    
    [int]$UserLimit

    
    
    [int]$RateLimitPerUser

    
    [DiscordUser[]]$Recipients

    
    [string]$Icon

    
    [string]$OwnerId

    
    [string]$ApplicationId

    
    [string]$ParentId

    
    [datetime]$LastPinTimestamp
}
