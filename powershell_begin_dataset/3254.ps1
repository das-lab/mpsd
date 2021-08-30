

class Backend : BaseLogger {

    [string]$Name

    [string]$BotId

    
    [Connection]$Connection

    [hashtable]$Users = @{}

    [hashtable]$Rooms = @{}

    [System.Collections.ArrayList]$IgnoredMessageTypes = (New-Object System.Collections.ArrayList)

    [bool]$LazyLoadUsers = $false

    Backend() {}

    
    [void]SendMessage([Response]$Response) {
        
        throw 'Implement me!'
    }

    
    [void]AddReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        
        throw 'Implement me!'
    }

    [void]AddReaction([Message]$Message, [ReactionType]$Type) {
        $this.AddReaction($Message, $Type, [string]::Empty)
    }

    
    [void]RemoveReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        
        throw 'Implement me!'
    }

    [void]RemoveReaction([Message]$Message, [ReactionType]$Type) {
        $this.RemoveReaction($Message, $Type, [string]::Empty)
    }

    
    [Message[]]ReceiveMessage() {
        
        throw 'Implement me!'
    }

    
    [void]Ping() {
        
        
    }

    
    [Person]GetUser([string]$UserId) {
        
        throw 'Implement me!'
    }

    
    [void]Connect() {
        $this.Connection.Connect()
    }

    
    [void]Disconnect() {
        $this.Connection.Disconnect()
    }

    
    [void]LoadUsers() {
        
        throw 'Implement me!'
    }

    
    [void]LoadRooms() {
        
        throw 'Implement me!'
    }

    
    [string]GetBotIdentity() {
        
        throw 'Implement me!'
    }

    
    [string]UsernameToUserId([string]$Username) {
        
        throw 'Implement me!'
    }

    
    [string]UserIdToUsername([string]$UserId) {
        
        throw 'Implement me!'
    }

    [hashtable]GetUserInfo([string]$UserId) {
        
        throw 'Implement me!'
    }

    [string]ChannelIdToName([string]$ChannelId) {
        
        throw 'Implement me!'
    }

    [Message]ResolveFromName([Message]$Message) {
        
        throw 'Implement me!'
    }

    [Message]ResolveToName([Message]$Message) {
        
        throw 'Implement me!'
    }
}
