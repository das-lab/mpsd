
class TeamsBackend : Backend {

    [bool]$LazyLoadUsers = $true

    
    
    [string[]]$MessageTypes = @(
        'message'
    )

    [string]$TeamId     = $null
    [string]$ServiceUrl = $null
    [string]$BotId      = $null
    [string]$BotName    = $null
    [string]$TenantId   = $null

    [hashtable]$DMConverations = @{}

    [hashtable]$FileUploadTracker = @{}

    TeamsBackend([TeamsConnectionConfig]$Config) {
        $conn = [TeamsConnection]::new($Config)
        $this.TeamId = $Config.TeamId
        $this.Connection = $conn
    }

    
    [void]Connect() {
        $this.LogInfo('Connecting to backend')
        $this.Connection.Connect()
    }

    [Message[]]ReceiveMessage() {
        $messages = New-Object -TypeName System.Collections.ArrayList
        try {
            
            $jsonResults = $this.Connection.ReadReceiveThread()

            if (-not [string]::IsNullOrEmpty($jsonResults)) {

                foreach ($jsonResult in $jsonResults) {

                    $this.LogDebug('Received message', $jsonResult)

                    $teamsMessages = @($jsonResult | ConvertFrom-Json)

                    foreach ($teamsMessage in $teamsMessages) {

                        $this.DelayedInit($teamsMessage)

                        
                        if ($teamsMessage.type -in $this.MessageTypes) {
                            $msg = [Message]::new()

                            switch ($teamsMessage.type) {
                                'message' {
                                    $msg.Type = [MessageType]::Message
                                    break
                                }
                            }
                            $this.LogDebug("Message type is [$($msg.Type)]")

                            $msg.Id = $teamsMessage.id
                            if ($teamsMessage.recipient) {
                                $msg.To = $teamsMessage.recipient.id
                            }

                            $msg.RawMessage = $teamsMessage
                            $this.LogDebug('Raw message', $teamsMessage)

                            
                            
                            
                            if ($teamsMessage.text)    {
                                $msg.Text = $teamsMessage.text.Replace("<at>$($this.Connection.Config.BotName)</at> ", '') -Replace '\n', ''
                            }

                            if ($teamsMessage.from) {
                                $msg.From     = $teamsMessage.from.id
                                $msg.FromName = $teamsMessage.from.name
                            }

                            
                            
                            
                            
                            if (-not $teamsMessage.channelData.team) {
                                $msg.IsDM = $true
                                $msg.ToName = $this.Connection.Config.BotName
                            } else {
                                if ($msg.To) {
                                    $msg.ToName = $this.ResolveToName($msg)
                                }
                            }

                            
                            
                            if (($teamsMessage.channelData.teamsChannelId) -and (-not $msg.IsDM)) {
                                $msg.ToName = $this.ChannelIdToName($teamsMessage.channelData.teamsChannelId)
                            }

                            
                            $msg.Time = [datetime]$teamsMessage.timestamp

                            $messages.Add($msg) > $null
                        } else {
                            $this.LogDebug("Message type is [$($teamsMessage.type)]. Ignoring")
                        }
                    }
                }
            }
        } catch {
            $this.LogInfo([LogSeverity]::Error, 'Error authenticating to Teams', [ExceptionFormatter]::Summarize($_))
        }

        return $messages
    }

    [void]Ping() {}

    
    [void]SendMessage([Response]$Response) {

        $baseUrl        = $Response.OriginalMessage.RawMessage.serviceUrl
        $fromId         = $Response.OriginalMessage.RawMessage.from.id
        $fromName       = $Response.OriginalMessage.RawMessage.from.name
        $recipientId    = $Response.OriginalMessage.RawMessage.recipient.id
        $recipientName  = $Response.OriginalMessage.RawMessage.recipient.name
        $conversationId = $Response.OriginalMessage.RawMessage.conversation.id
        $activityId     = $Response.OriginalMessage.RawMessage.id
        $responseUrl    = "$($baseUrl)v3/conversations/$conversationId/activities/$activityId"
        $headers = @{
            Authorization = "Bearer $($this.Connection._AccessTokenInfo.access_token)"
        }

        
        $this.LogDebug("[$($Response.Data.Count)] custom responses")
        foreach ($customResponse in $Response.Data) {

            if ($customResponse.Text) {
                
            }

            
            if ($customResponse.DM) {
                $conversationId = $this._CreateDMConversation($Response.OriginalMessage.RawMessage.from.id)
                $activityId = $conversationId
                $responseUrl = "$($baseUrl)v3/conversations/$conversationId/activities/"
            }

            switch -Regex ($customResponse.PSObject.TypeNames[0]) {
                '(.*?)PoshBot\.Card\.Response' {
                    $this.LogDebug('Custom response is [PoshBot.Card.Response]')

                    $cardBody = @{
                        type = 'message'
                        from = @{
                            id   = $fromId
                            name = $fromName
                        }
                        conversation = @{
                            id = $conversationId
                        }
                        recipient = @{
                            id = $recipientId
                            name = $recipientName
                        }
                        attachments = @(
                            @{
                                contentType = 'application/vnd.microsoft.teams.card.o365connector'
                                content = @{
                                    "@type" = 'MessageCard'
                                    "@context" = 'http://schema.org/extensions'
                                    themeColor = $customResponse.Color -replace '
                                    sections = @(
                                        @{

                                        }
                                    )
                                }
                            }
                        )
                        replyToId = $activityId
                    }

                    
                    if ($customResponse.ThumbnailUrl) {
                        $cardBody.attachments[0].content.sections[0].activityImageType = 'article'
                        $cardBody.attachments[0].content.sections[0].activityImage = $customResponse.ThumbnailUrl
                    }

                    
                    if ($customResponse.Title) {
                        $cardBody.attachments[0].content.summary = $customResponse.Title
                        if ($customResponse.LinkUrl) {
                            $cardBody.attachments[0].content.title = "[$($customResponse.Title)]($($customResponse.LinkUrl))"
                        } else {
                            $cardBody.attachments[0].content.title = $customResponse.Title
                        }
                    }

                    
                    if ($customResponse.Text) {
                        $cardBody.attachments[0].content.sections[0].text = '<pre>' + $customResponse.Text + '</pre>'
                        $cardBody.attachments[0].content.sections[0].textFormat = 'markdown'
                    }

                    
                    if ($customResponse.Fields.Count -gt 0) {
                        $cardBody.attachments[0].content.sections[0].facts = @()
                        foreach ($field in $customResponse.Fields.GetEnumerator()) {
                            $cardBody.attachments[0].content.sections[0].facts += @{
                                name = $field.Name
                                value = $field.Value.ToString()
                            }
                        }
                    }

                    
                    if ($customResponse.ImageUrl) {
                        $cardBody.attachments[0].content.sections = @(
                            @{
                                images = @(
                                    @{
                                        image = $customResponse.ImageUrl
                                    }
                                )
                            }
                        ) + $cardBody.attachments[0].content.sections
                    }

                    $body = $cardBody | ConvertTo-Json -Depth 20
                    Write-Verbose $body
                    
                    $this.LogDebug("Sending response back to Teams conversation [$conversationId]", $body)
                    try {
                        $responseParams = @{
                            Uri         = $responseUrl
                            Method      = 'Post'
                            Body        = $body
                            ContentType = 'application/json'
                            Headers     = $headers
                        }
                        Invoke-RestMethod @responseParams
                    } catch {
                        $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
                    }

                    break
                }
                '(.*?)PoshBot\.Text\.Response' {
                    $this.LogDebug('Custom response is [PoshBot.Text.Response]')

                    $textFormat = 'plain'
                    $cardText = $customResponse.Text
                    if ($customResponse.AsCode) {
                        $textFormat = 'markdown'
                        $cardText = '<pre>' + $cardText + '</pre>'
                    }

                    $cardBody = @{
                        type = 'message'
                        from = @{
                            id   = $fromId
                            name = $fromName
                        }
                        conversation = @{
                            id = $conversationId
                        }
                        recipient = @{
                            id = $recipientId
                            name = $recipientName
                        }
                        text = $cardText
                        textFormat = $textFormat
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        replyToId = $activityId
                    }

                    $body = $cardBody | ConvertTo-Json -Depth 15
                    Write-Verbose $body
                    
                    $this.LogDebug("Sending response back to Teams channel [$conversationId]", $body)
                    try {
                        $responseParams = @{
                            Uri         = $responseUrl
                            Method      = 'Post'
                            Body        = $body
                            ContentType = 'application/json'
                            Headers     = $headers
                        }
                        Invoke-RestMethod @responseParams
                    } catch {
                        $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
                    }

                    break
                }
                '(.*?)PoshBot\.File\.Upload' {
                    
                    $this.LogDebug('Custom response is [PoshBot.File.Upload]')

                    
                    
                    $jsonResponse = @{
                        type = 'message'
                        from = @{
                            id = $recipientId
                            name = $recipientName
                        }
                        conversation = @{
                            id = $conversationId
                            name = ''
                        }
                        recipient = @{
                            id = $fromId
                            name = $fromName
                        }
                        text = "I don't know how to upload files to Teams yet but I'm learning."
                        replyToId = $activityId
                    } | ConvertTo-Json

                    
                    $this.LogDebug("Sending response back to Teams conversation [$conversationId]")
                    try {
                        $responseParams = @{
                            Uri         = $responseUrl
                            Method      = 'Post'
                            Body        = $jsonResponse
                            ContentType = 'application/json'
                            Headers     = $headers
                        }
                        Invoke-RestMethod @responseParams
                    } catch {
                        $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
                    }

                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    

                    
                    
                    
                    
                    

                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    

                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    

                    

                    
                    
                    

                    
                    

                    
                    
                    
                    
                    

                    
                    
                    
                    

                    
                    
                    
                    
                    
                    
                    
                    

                    
                    
                    
                    
                    
                    
                    
                    
                    

                    break
                }
            }
        }

        
        if ($Response.Text.Count -gt 0) {
            $this.LogDebug("Sending response back to Teams channel [$($Response.To)]")
            $this.SendTeamsMessaage($Response)
        }
    }

    
    
    [void]AddReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {

        $baseUrl = $Message.RawMessage.serviceUrl
        $fromId = $Message.rawmessage.from.id
        $fromName = $Message.RawMessage.from.name
        $recipientId = $Message.RawMessage.recipient.id
        $recipientName = $Message.RawMessage.recipient.name
        $conversationId = $Message.RawMessage.conversation.id
        $activityId = $Message.RawMessage.id
        $responseUrl = "$($baseUrl)v3/conversations/$conversationId/activities/$activityId"
        $channelId = $Message.RawMessage.channelData.teamsChannelId

        $headers = @{
            Authorization = "Bearer $($this.Connection._AccessTokenInfo.access_token)"
        }

        
        if ($Message.isDM) {
            $conversationId = $this._CreateDMConversation($fromId)
            $activityId = $conversationId
            $responseUrl = "$($baseUrl)v3/conversations/$conversationId/activities/"
        }

        if ($Type -eq [ReactionType]::Processing) {
            $cardBody = @{
                type         = 'typing'
                from         = @{
                    id   = $fromId
                    name = $fromName
                }
                conversation = @{
                    id   = $conversationId
                    name = ''
                }
                recipient    = @{
                    id   = $recipientId
                    name = $recipientName
                }
                replyToId    = $activityId
                channelId    = $channelId
            }

            $body = $cardBody | ConvertTo-Json -Depth 15
            Write-Verbose $body

            $this.LogDebug("Sending typing indicator to Teams conversation [$conversationId]", $body)

            try {
                $responseParams = @{
                    Uri         = $responseUrl
                    Method      = 'Post'
                    Body        = $body
                    ContentType = 'application/json'
                    Headers     = $headers
                }
                Invoke-RestMethod @responseParams
            } catch {
                $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
            }
        }
    }

    
    [void]RemoveReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        
    }

    
    [void]LoadUsers() {
        if (-not [string]::IsNullOrEmpty($this.ServiceUrl)) {
            $this.LogDebug('Getting Teams users')

            $uri = "$($this.ServiceUrl)v3/conversations/$($this.TeamId)/members/"
            $headers = @{
                Authorization = "Bearer $($this.Connection._AccessTokenInfo.access_token)"
            }
            $members = Invoke-RestMethod -Uri $uri -Headers $headers
            $this.LogDebug('Finished getting Teams users')

            $members | Foreach-Object {
                $user = [TeamsPerson]::new()
                $user.Id                = $_.id
                $user.FirstName         = $_.givenName
                $user.LastName          = $_.surname
                $user.NickName          = $_.userPrincipalName
                $user.FullName          = "$($_.givenName) $($_.surname)"
                $user.Email             = $_.email
                $user.UserPrincipalName = $_.userPrincipalName

                if (-not $this.Users.ContainsKey($_.ID)) {
                    $this.LogDebug("Adding user [$($_.ID):$($_.Name)]")
                    $this.Users[$_.ID] =  $user
                }
            }

            foreach ($key in $this.Users.Keys) {
                if ($key -notin $members.ID) {
                    $this.LogDebug("Removing outdated user [$key]")
                    $this.Users.Remove($key)
                }
            }
        }
    }

    
    [void]LoadRooms() {
        
            $this.LogDebug('Getting Teams channels')

            $uri = "$($this.ServiceUrl)v3/teams/$($this.TeamId)/conversations"
            $headers = @{
                Authorization = "Bearer $($this.Connection._AccessTokenInfo.access_token)"
            }
            $channels = Invoke-RestMethod -Uri $uri -Headers $headers

            if ($channels.conversations) {
                $channels.conversations | ForEach-Object {
                    $channel = [TeamsChannel]::new()
                    $channel.Id = $_.id
                    $channel.Name = $_.name
                    $this.LogDebug("Adding channel: $($_.id):$($_.name)")
                    $this.Rooms[$_.id] = $channel
                }

                foreach ($key in $this.Rooms.Keys) {
                    if ($key -notin $channels.conversations.ID) {
                        $this.LogDebug("Removing outdated channel [$key]")
                        $this.Rooms.Remove($key)
                    }
                }
            }
        
    }

    [bool]MsgFromBot([string]$From) {
        return $false
    }

    
    [TeamsPerson]GetUser([string]$UserId) {
        $user = $this.Users[$UserId]
        if (-not $user) {
            $this.LogDebug([LogSeverity]::Warning, "User [$UserId] not found. Refreshing users")
            $this.LoadUsers()
            $user = $this.Users[$UserId]
        }

        if ($user) {
            $this.LogDebug("Resolved user [$UserId]", $user)
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Could not resolve user [$UserId]")
        }
        return $user
    }

    
    [string]UsernameToUserId([string]$Username) {
        $Username = $Username.TrimStart('@')
        $user = $this.Users.Values | Where-Object {$_.Nickname -eq $Username}
        $id = $null
        if ($user) {
            $id = $user.Id
        } else {
            
            
            $this.LogDebug([LogSeverity]::Warning, "User [$Username] not found. Refreshing users")
            $this.LoadUsers()
            $user = $this.Users.Values | Where-Object {$_.Nickname -eq $Username}
            if (-not $user) {
                $id = $null
            } else {
                $id = $user.Id
            }
        }
        if ($id) {
            $this.LogDebug("Resolved [$Username] to [$id]")
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Could not resolve user [$Username]")
        }
        return $id
    }

    
    [string]UserIdToUsername([string]$UserId) {
        $name = $null
        if ($this.Users.ContainsKey($UserId)) {
            $name = $this.Users[$UserId].Nickname
        } else {
            $this.LogDebug([LogSeverity]::Warning, "User [$UserId] not found. Refreshing users")
            $this.LoadUsers()
            $name = $this.Users[$UserId].Nickname
        }
        if ($name) {
            $this.LogDebug("Resolved [$UserId] to [$name]")
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Could not resolve user [$UserId]")
        }
        return $name
    }

    
    [string]ChannelIdToName([string]$ChannelId) {
        $name = $null
        if ($this.Rooms.ContainsKey($ChannelId)) {
            $name = $this.Rooms[$ChannelId].Name
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Channel [$ChannelId] not found. Refreshing channels")
            $this.LoadRooms()
            $name = $this.Rooms[$ChannelId].Name
        }
        if ($name) {
            $this.LogDebug("Resolved [$ChannelId] to [$name]")
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Could not resolve channel [$ChannelId]")
        }
        return $name
    }

    
    [string]ResolveFromName([Message]$Message) {
        $fromName = $null
        if ($Message.From) {
            $fromName = $this.UserIdToUsername($Message.From)
        }
        return $fromName
    }

    
    [string]ResolveToName([Message]$Message) {
        $toName = $null
        if ($Message.To) {
            $toName = $this.ChannelIdToName($Message.To)
        }
        return $toName
    }

    
    [hashtable]GetUserInfo([string]$UserId) {
        $user = $null
        if ($this.Users.ContainsKey($UserId)) {
            $user = $this.Users[$UserId]
        } else {
            $this.LogDebug([LogSeverity]::Warning, "User [$UserId] not found. Refreshing users")
            $this.LoadUsers()
            $user = $this.Users[$UserId]
        }

        if ($user) {
            $this.LogDebug("Resolved [$UserId] to [$($user.Nickname)]")
            return $user.ToHash()
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Could not resolve channel [$UserId]")
            return $null
        }
    }

    hidden [void]DelayedInit([pscustomobject]$Message) {
        if ([string]::IsNullOrEmpty($this.ServiceUrl)) {
            $this.ServiceUrl = $Message.serviceUrl
            $this.LoadUsers()
            $this.LoadRooms()
        }

        if ([string]::IsNullOrEmpty($this.BotId)) {
            if ($Message.recipient) {
                $this.BotId   = $Message.recipient.Id
                $this.BotName = $Message.recipient.name
            }
        }

        if ([string]::IsNullOrEmpty($this.TenantId)) {
            if ($Message.channelData.tenant.id) {
                $this.TenantId = $Message.channelData.tenant.id
            }
        }
    }

    hidden [void]SendTeamsMessaage([Response]$Response) {
        $baseUrl        = $Response.OriginalMessage.RawMessage.serviceUrl
        $conversationId = $Response.OriginalMessage.RawMessage.conversation.id
        $activityId     = $Response.OriginalMessage.RawMessage.id
        $responseUrl    = "$($baseUrl)v3/conversations/$conversationId/activities/$activityId"
        $headers = @{
            Authorization = "Bearer $($this.Connection._AccessTokenInfo.access_token)"
        }

        if ($Response.Text.Count -gt 0) {
            foreach ($text in $Response.Text) {
                $jsonResponse = @{
                    type = 'message'
                    from = @{
                        id = $Response.OriginalMessage.RawMessage.recipient.id
                        name = $Response.OriginalMessage.RawMessage.recipient.name
                    }
                    conversation = @{
                        id = $Response.OriginalMessage.RawMessage.conversation.id
                        name = ''
                    }
                    recipient = @{
                        id = $Response.OriginalMessage.RawMessage.from.id
                        name = $Response.OriginalMessage.RawMessage.from.name
                    }
                    text = $text
                    replyToId = $activityId
                } | ConvertTo-Json

                
                $this.LogDebug("Sending response back to Teams conversation [$conversationId]")
                try {
                    $responseParams = @{
                        Uri         = $responseUrl
                        Method      = 'Post'
                        Body        = $jsonResponse
                        ContentType = 'application/json'
                        Headers     = $headers
                    }
                    Invoke-RestMethod @responseParams
                } catch {
                    $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
                }
            }
        }
    }

    
    
    hidden [string]_CreateDMConversation([string]$UserId) {
        if ($this.DMConverations.ContainsKey($userId)) {
            return $this.DMConverations[$UserId]
        } else {
            $newConversationUrl = "$($this.ServiceUrl)v3/conversations"
            $headers = @{
                Authorization = "Bearer $($this.Connection._AccessTokenInfo.access_token)"
            }

            $conversationParams = @{
                bot = @{
                    id = $this.BotId
                    name = $this.BotName
                }
                members = @(
                    @{
                        id = $UserId
                    }
                )
                channelData = @{
                    tenant = @{
                        id = $this.TenantId
                    }
                }
            }

            $body = $conversationParams | ConvertTo-Json
            
            $params = @{
                Uri         = $newConversationUrl
                Method      = 'Post'
                Body        = $body
                ContentType = 'application/json'
                Headers     = $headers
            }
            $conversation = Invoke-RestMethod @params
            if ($conversation) {
                $this.LogDebug("Created DM conversation [$($conversation.id)] with user [$UserId]")
                return $conversation.id
            } else {
                $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
                return $null
            }
        }
    }

    hidden [hashtable]_GetCardStub() {
        return @{
            type = 'message'
            from = @{
                id   = $null
                name = $null
            }
            conversation = @{
                id = $null
                
            }
            recipient = @{
                id = $null
                name = $null
            }
            attachments = @(
                @{
                    contentType = 'application/vnd.microsoft.card.adaptive'
                    content = @{
                        type = 'AdaptiveCard'
                        version = '1.0'
                        fallbackText = $null
                        body = @(
                            @{
                                type = 'Container'
                                spacing = 'none'
                                items = @(
                                    
                                    @{
                                        type = 'ColumnSet'
                                        spacing = 'none'
                                        columns = @()
                                    }
                                    
                                    @{
                                        type = 'ColumnSet'
                                        spacing = 'none'
                                        columns = @()
                                    }
                                    
                                    @{
                                        type = 'FactSet'
                                        facts = @()
                                    }
                                )
                            }
                        )
                    }
                }
            )
            replyToId = $null
        }
    }

    hidden [string]_RepairText([string]$Text) {
        if (-not [string]::IsNullOrEmpty($Text)) {
            $fixed = $Text.Replace('"', '\"').Replace('\', '\\').Replace("`n", '\n\n').Replace("`r", '').Replace("`t", '\t')
            $fixed = [System.Text.RegularExpressions.Regex]::Unescape($Text)
        } else {
            $fixed = ' '
        }

        return $fixed
    }

}
