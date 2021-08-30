
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope='Class', Target='*')]
class SlackBackend : Backend {

    
    
    [string[]]$MessageTypes = @(
        'channel_rename'
        'member_joined_channel'
        'member_left_channel'
        'message'
        'pin_added'
        'pin_removed'
        'presence_change'
        'reaction_added'
        'reaction_removed'
        'star_added'
        'star_removed'
    )

    [int]$MaxMessageLength = 3900

    
    hidden [hashtable]$_PSSlackColorMap = @{
        aliceblue = "
        antiquewhite = "
        aqua = "
        aquamarine = "
        azure = "
        beige = "
        bisque = "
        black = "
        blanchedalmond = "
        blue = "
        blueviolet = "
        brown = "
        burlywood = "
        cadetblue = "
        chartreuse = "
        chocolate = "
        coral = "
        cornflowerblue = "
        cornsilk = "
        crimson = "
        darkblue = "
        darkcyan = "
        darkgoldenrod = "
        darkgray = "
        darkgreen = "
        darkkhaki = "
        darkmagenta = "
        darkolivegreen = "
        darkorange = "
        darkorchid = "
        darkred = "
        darksalmon = "
        darkseagreen = "
        darkslateblue = "
        darkslategray = "
        darkturquoise = "
        darkviolet = "
        deeppink = "
        deepskyblue = "
        dimgray = "
        dodgerblue = "
        firebrick = "
        floralwhite = "
        forestgreen = "
        fuchsia = "
        gainsboro = "
        ghostwhite = "
        gold = "
        goldenrod = "
        gray = "
        green = "
        greenyellow = "
        honeydew = "
        hotpink = "
        indianred = "
        indigo = "
        ivory = "
        khaki = "
        lavender = "
        lavenderblush = "
        lawngreen = "
        lemonchiffon = "
        lightblue = "
        lightcoral = "
        lightcyan = "
        lightgoldenrodyellow = "
        lightgreen = "
        lightgrey = "
        lightpink = "
        lightsalmon = "
        lightseagreen = "
        lightskyblue = "
        lightslategray = "
        lightsteelblue = "
        lightyellow = "
        lime = "
        limegreen = "
        linen = "
        maroon = "
        mediumaquamarine = "
        mediumblue = "
        mediumorchid = "
        mediumpurple = "
        mediumseagreen = "
        mediumslateblue = "
        mediumspringgreen = "
        mediumturquoise = "
        mediumvioletred = "
        midnightblue = "
        mintcream = "
        mistyrose = "
        moccasin = "
        navajowhite = "
        navy = "
        oldlace = "
        olive = "
        olivedrab = "
        orange = "
        orangered = "
        orchid = "
        palegoldenrod = "
        palegreen = "
        paleturquoise = "
        palevioletred = "
        papayawhip = "
        peachpuff = "
        peru = "
        pink = "
        plum = "
        powderblue = "
        purple = "
        red = "
        rosybrown = "
        royalblue = "
        saddlebrown = "
        salmon = "
        sandybrown = "
        seagreen = "
        seashell = "
        sienna = "
        silver = "
        skyblue = "
        slateblue = "
        slategray = "
        snow = "
        springgreen = "
        steelblue = "
        tan = "
        teal = "
        thistle = "
        tomato = "
        turquoise = "
        violet = "
        wheat = "
        white = "
        whitesmoke = "
        yellow = "
        yellowgreen = "
    }

    SlackBackend ([string]$Token) {
        Import-Module PSSlack -Verbose:$false -ErrorAction Stop

        $config = [ConnectionConfig]::new()
        $secToken = $Token | ConvertTo-SecureString -AsPlainText -Force
        $config.Credential = New-Object System.Management.Automation.PSCredential('asdf', $secToken)
        $conn = [SlackConnection]::New()
        $conn.Config = $config
        $this.Connection = $conn
    }

    
    [void]Connect() {
        $this.LogInfo('Connecting to backend')
        $this.LogInfo('Listening for the following message types. All others will be ignored', $this.MessageTypes)
        $this.Connection.Connect()
        $this.BotId = $this.GetBotIdentity()
        $this.LoadUsers()
        $this.LoadRooms()
    }

    
    [Message[]]ReceiveMessage() {
        $messages = New-Object -TypeName System.Collections.ArrayList
        try {
            
            [string[]]$jsonResults = $this.Connection.ReadReceiveJob()

            foreach ($jsonResult in $jsonResults) {
                if ($null -ne $jsonResult -and $jsonResult -ne [string]::Empty) {
                    
                    $this.LogDebug('Received message', $jsonResult)

                    
                    $jsonResult = $this._SanitizeURIs($jsonResult)

                    $slackMessage = @($jsonResult | ConvertFrom-Json)

                    
                    
                    
                    if ($slackMessage.subtype -eq 'bot_message') {
                        $this.LogDebug('SubType is [bot_message]. Ignoring')
                        continue
                    }

                    
                    
                    
                    
                    
                    if ($slackMessage.subtype -eq 'message_replied') {
                        $this.LogDebug('SubType is [message_replied]. Ignoring')
                        continue
                    }

                    
                    if ($slackMessage.Type -in $this.MessageTypes) {
                        $msg = [Message]::new()

                        
                        
                        switch ($slackMessage.type) {
                            'channel_rename' {
                                $msg.Type = [MessageType]::ChannelRenamed
                            }
                            'member_joined_channel' {
                                $msg.Type = [MessageType]::Message
                                $msg.SubType = [MessageSubtype]::ChannelJoined
                            }
                            'member_left_channel' {
                                $msg.Type = [MessageType]::Message
                                $msg.SubType = [MessageSubtype]::ChannelLeft
                            }
                            'message' {
                                $msg.Type = [MessageType]::Message
                            }
                            'pin_added' {
                                $msg.Type = [MessageType]::PinAdded
                            }
                            'pin_removed' {
                                $msg.Type = [MessageType]::PinRemoved
                            }
                            'presence_change' {
                                $msg.Type = [MessageType]::PresenceChange
                            }
                            'reaction_added' {
                                $msg.Type = [MessageType]::ReactionAdded
                            }
                            'reaction_removed' {
                                $msg.Type = [MessageType]::ReactionRemoved
                            }
                            'star_added' {
                                $msg.Type = [MessageType]::StarAdded
                            }
                            'star_removed' {
                                $msg.Type = [MessageType]::StarRemoved
                            }
                        }

                        
                        
                        if ($slackMessage.item -and ($slackMessage.item.channel)) {
                            $msg.To = $slackMessage.item.channel
                        }

                        if ($slackMessage.subtype) {
                            switch ($slackMessage.subtype) {
                                'channel_join' {
                                    $msg.Subtype = [MessageSubtype]::ChannelJoined
                                }
                                'channel_leave' {
                                    $msg.Subtype = [MessageSubtype]::ChannelLeft
                                }
                                'channel_name' {
                                    $msg.Subtype = [MessageSubtype]::ChannelRenamed
                                }
                                'channel_purpose' {
                                    $msg.Subtype = [MessageSubtype]::ChannelPurposeChanged
                                }
                                'channel_topic' {
                                    $msg.Subtype = [MessageSubtype]::ChannelTopicChanged
                                }
                            }
                        }
                        $this.LogDebug("Message type is [$($msg.Type)`:$($msg.Subtype)]")

                        $msg.RawMessage = $slackMessage
                        $this.LogDebug('Raw message', $slackMessage)
                        if ($slackMessage.text)    { $msg.Text = $slackMessage.text }
                        if ($slackMessage.channel) { $msg.To   = $slackMessage.channel }
                        if ($slackMessage.user)    { $msg.From = $slackMessage.user }

                        
                        $msg.FromName = $this.ResolveFromName($msg)

                        
                        $msg.ToName = $this.ResolveToName($msg)

                        
                        if ($msg.To -match '^D') {
                            $msg.IsDM = $true
                        }

                        
                        $unixEpoch = [datetime]'1970-01-01'
                        if ($slackMessage.ts) {
                            $msg.Time = $unixEpoch.AddSeconds($slackMessage.ts)
                        } elseIf ($slackMessage.event_ts) {
                            $msg.Time = $unixEpoch.AddSeconds($slackMessage.event_ts)
                        } else {
                            $msg.Time = (Get-Date).ToUniversalTime()
                        }

                        
                        
                        
                        
                        
                        if ($slackMessage.message) {
                            if ($slackMessage.message.user) {
                                $msg.From = $slackMessage.message.user
                            }
                            if ($slackMessage.message.text) {
                                $msg.Text = $slackMessage.message.text
                            }
                        }

                        
                        
                        
                        $processed = $this._ProcessMentions($msg.Text)
                        $msg.Text = $processed

                        
                        
                        
                        
                        if (-not $this.MsgFromBot($msg.From)) {
                            $messages.Add($msg) > $null
                        }
                    } else {
                        $this.LogDebug("Message type is [$($slackMessage.Type)]. Ignoring")
                    }

                }
            }
        } catch {
            Write-Error $_
        }

        return $messages
    }

    
    [void]Ping() {
        
        
        
        
        
        
        
        
        

        
        
        
        
    }

    
    [void]SendMessage([Response]$Response) {
        
        $this.LogDebug("[$($Response.Data.Count)] custom responses")
        foreach ($customResponse in $Response.Data) {

            [string]$sendTo = $Response.To
            if ($customResponse.DM) {
                $sendTo = "@$($this.UserIdToUsername($Response.MessageFrom))"
            }

            switch -Regex ($customResponse.PSObject.TypeNames[0]) {
                '(.*?)PoshBot\.Card\.Response' {
                    $this.LogDebug('Custom response is [PoshBot.Card.Response]')
                    $chunks = $this._ChunkString($customResponse.Text)
                    $x = 0
                    foreach ($chunk in $chunks) {
                        $attParams = @{
                            MarkdownFields = 'text'
                            Color = $customResponse.Color
                        }
                        $fbText = 'no data'
                        if (-not [string]::IsNullOrEmpty($chunk.Text)) {
                            $this.LogDebug("Response size [$($chunk.Text.Length)]")
                            $fbText = $chunk.Text
                        }
                        $attParams.Fallback = $fbText
                        if ($customResponse.Title) {

                            
                            if ($x -eq 0) {
                                $attParams.Title = $customResponse.Title
                            }
                        }
                        if ($customResponse.ImageUrl) {
                            $attParams.ImageURL = $customResponse.ImageUrl
                        }
                        if ($customResponse.ThumbnailUrl) {
                            $attParams.ThumbURL = $customResponse.ThumbnailUrl
                        }
                        if ($customResponse.LinkUrl) {
                            $attParams.TitleLink = $customResponse.LinkUrl
                        }
                        if ($customResponse.Fields) {
                            $arr = New-Object System.Collections.ArrayList
                            foreach ($key in $customResponse.Fields.Keys) {
                                $arr.Add(
                                    @{
                                        title = $key;
                                        value = $customResponse.Fields[$key];
                                        short = $true
                                    }
                                )
                            }
                            $attParams.Fields = $arr
                        }

                        if (-not [string]::IsNullOrEmpty($chunk)) {
                            $attParams.Text = '```' + $chunk + '```'
                        } else {
                            $attParams.Text = [string]::Empty
                        }
                        $att = New-SlackMessageAttachment @attParams
                        $msg = $att | New-SlackMessage -Channel $sendTo -AsUser
                        $this.LogDebug("Sending card response back to Slack channel [$sendTo]", $att)
                        $msg | Send-SlackMessage -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Verbose:$false > $null
                    }
                    break
                }
                '(.*?)PoshBot\.Text\.Response' {
                    $this.LogDebug('Custom response is [PoshBot.Text.Response]')
                    $chunks = $this._ChunkString($customResponse.Text)
                    foreach ($chunk in $chunks) {
                        if ($customResponse.AsCode) {
                            $t = '```' + $chunk + '```'
                        } else {
                            $t = $chunk
                        }
                        $this.LogDebug("Sending text response back to Slack channel [$sendTo]", $t)
                        Send-SlackMessage -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Channel $sendTo -Text $t -Verbose:$false -AsUser > $null
                    }
                    break
                }
                '(.*?)PoshBot\.File\.Upload' {
                    $this.LogDebug('Custom response is [PoshBot.File.Upload]')

                    $uploadParams = @{
                        Token = $this.Connection.Config.Credential.GetNetworkCredential().Password
                        Channel = $sendTo
                    }

                    if ([string]::IsNullOrEmpty($customResponse.Path) -and (-not [string]::IsNullOrEmpty($customResponse.Content))) {
                        $uploadParams.Content = $customResponse.Content
                        if (-not [string]::IsNullOrEmpty($customResponse.FileType)) {
                            $uploadParams.FileType = $customResponse.FileType
                        }
                        if (-not [string]::IsNullOrEmpty($customResponse.FileName)) {
                            $uploadParams.FileName = $customResponse.FileName
                        }
                    } else {
                        
                        if (-not (Test-Path -Path $customResponse.Path -ErrorAction SilentlyContinue)) {
                            
                            $this.RemoveReaction($Response.OriginalMessage, [ReactionType]::Success)
                            $this.AddReaction($Response.OriginalMessage, [ReactionType]::Failure)
                            $att = New-SlackMessageAttachment -Color '
                            $msg = $att | New-SlackMessage -Channel $sendTo -AsUser
                            $this.LogDebug("Sending card response back to Slack channel [$sendTo]", $att)
                            $null = $msg | Send-SlackMessage -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Verbose:$false
                            break
                        }

                        $this.LogDebug("Uploading [$($customResponse.Path)] to Slack channel [$sendTo]")
                        $uploadParams.Path = $customResponse.Path
                        $uploadParams.Title = Split-Path -Path $customResponse.Path -Leaf
                    }

                    if (-not [string]::IsNullOrEmpty($customResponse.Title)) {
                        $uploadParams.Title = $customResponse.Title
                    }

                    Send-SlackFile @uploadParams -Verbose:$false
                    if (-not $customResponse.KeepFile -and -not [string]::IsNullOrEmpty($customResponse.Path)) {
                        Remove-Item -LiteralPath $customResponse.Path -Force
                    }
                    break
                }
            }
        }

        if ($Response.Text.Count -gt 0) {
            foreach ($t in $Response.Text) {
                $this.LogDebug("Sending response back to Slack channel [$($Response.To)]", $t)
                Send-SlackMessage -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Channel $Response.To -Text $t -Verbose:$false -AsUser > $null
            }
        }
    }

    
    [void]AddReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        if ($Message.RawMessage.ts) {
            if ($Type -eq [ReactionType]::Custom) {
                $emoji = $Reaction
            } else {
                $emoji = $this._ResolveEmoji($Type)
            }

            $body = @{
                name = $emoji
                channel = $Message.To
                timestamp = $Message.RawMessage.ts
            }
            $this.LogDebug("Adding reaction [$emoji] to message Id [$($Message.RawMessage.ts)]")
            $resp = Send-SlackApi -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Method 'reactions.add' -Body $body -Verbose:$false
            if (-not $resp.ok) {
                $this.LogInfo([LogSeverity]::Error, 'Error adding reaction to message', $resp)
            }
        }
    }

    
    [void]RemoveReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        if ($Message.RawMessage.ts) {
            if ($Type -eq [ReactionType]::Custom) {
                $emoji = $Reaction
            } else {
                $emoji = $this._ResolveEmoji($Type)
            }

            $body = @{
                name = $emoji
                channel = $Message.To
                timestamp = $Message.RawMessage.ts
            }
            $this.LogDebug("Removing reaction [$emoji] from message Id [$($Message.RawMessage.ts)]")
            $resp = Send-SlackApi -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Method 'reactions.remove' -Body $body -Verbose:$false
            if (-not $resp.ok) {
                $this.LogInfo([LogSeverity]::Error, 'Error removing reaction from message', $resp)
            }
        }
    }

    
    [string]ResolveChannelId([string]$ChannelName) {
        if ($ChannelName -match '^
            $ChannelName = $ChannelName.TrimStart('
        }
        $channelId = ($this.Connection.LoginData.channels | Where-Object name -eq $ChannelName).id
        if (-not $ChannelId) {
            $channelId = ($this.Connection.LoginData.channels | Where-Object id -eq $ChannelName).id
        }
        $this.LogDebug("Resolved channel [$ChannelName] to [$channelId]")
        return $channelId
    }

    
    [void]LoadUsers() {
        $this.LogDebug('Getting Slack users')
        $allUsers = Get-Slackuser -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Verbose:$false
        $this.LogDebug("[$($allUsers.Count)] users returned")
        $allUsers | ForEach-Object {
            $user = [SlackPerson]::new()
            $user.Id = $_.ID
            $user.Nickname = $_.Name
            $user.FullName = $_.RealName
            $user.FirstName = $_.FirstName
            $user.LastName = $_.LastName
            $user.Email = $_.Email
            $user.Phone = $_.Phone
            $user.Skype = $_.Skype
            $user.IsBot = $_.IsBot
            $user.IsAdmin = $_.IsAdmin
            $user.IsOwner = $_.IsOwner
            $user.IsPrimaryOwner = $_.IsPrimaryOwner
            $user.IsUltraRestricted = $_.IsUltraRestricted
            $user.Status = $_.Status
            $user.TimeZoneLabel = $_.TimeZoneLabel
            $user.TimeZone = $_.TimeZone
            $user.Presence = $_.Presence
            $user.Deleted = $_.Deleted
            if (-not $this.Users.ContainsKey($_.ID)) {
                $this.LogDebug("Adding user [$($_.ID):$($_.Name)]")
                $this.Users[$_.ID] =  $user
            }
        }

        foreach ($key in $this.Users.Keys) {
            if ($key -notin $allUsers.ID) {
                $this.LogDebug("Removing outdated user [$key]")
                $this.Users.Remove($key)
            }
        }
    }

    
    [void]LoadRooms() {
        $this.LogDebug('Getting Slack channels')
        $getChannelParams = @{
            Token           = $this.Connection.Config.Credential.GetNetworkCredential().Password
            ExcludeArchived = $true
            Verbose         = $false
            Paging          = $true
        }
        $allChannels = Get-SlackChannel @getChannelParams
        $this.LogDebug("[$($allChannels.Count)] channels returned")

        $allChannels.ForEach({
            $channel = [SlackChannel]::new()
            $channel.Id          = $_.ID
            $channel.Name        = $_.Name
            $channel.Topic       = $_.Topic
            $channel.Purpose     = $_.Purpose
            $channel.Created     = $_.Created
            $channel.Creator     = $_.Creator
            $channel.IsArchived  = $_.IsArchived
            $channel.IsGeneral   = $_.IsGeneral
            $channel.MemberCount = $_.MemberCount
            foreach ($member in $_.Members) {
                $channel.Members.Add($member, $null)
            }
            $this.LogDebug("Adding channel: $($_.ID):$($_.Name)")
            $this.Rooms[$_.ID] = $channel
        })

        foreach ($key in $this.Rooms.Keys) {
            if ($key -notin $allChannels.ID) {
                $this.LogDebug("Removing outdated channel [$key]")
                $this.Rooms.Remove($key)
            }
        }
    }

    
    [string]GetBotIdentity() {
        $id = $this.Connection.LoginData.self.id
        $this.LogVerbose("Bot identity is [$id]")
        return $id
    }

    
    [bool]MsgFromBot([string]$From) {
        $frombot = ($this.BotId -eq $From)
        if ($fromBot) {
            $this.LogDebug("Message is from bot [From: $From == Bot: $($this.BotId)]. Ignoring")
        } else {
            $this.LogDebug("Message is not from bot [From: $From <> Bot: $($this.BotId)]")
        }
        return $fromBot
    }

    
    [SlackPerson]GetUser([string]$UserId) {
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
        if ($Message.To -and $Message.To -notmatch '^D') {
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

    
    hidden [string] _SanitizeURIs([string]$Text) {
        $sanitizedText = $Text -replace '<([^\|>]+)\|([^\|>]+)>', '$2'
        $sanitizedText = $sanitizedText -replace '<(http([^>]+))>', '$1'
        return $sanitizedText
    }

    
    
    
    hidden [Collections.Generic.List[string]] _ChunkString([string]$Text) {

        
        if ([string]::IsNullOrEmpty($Text)) {
            return $text
        }

        $chunks             = [Collections.Generic.List[string]]::new()
        $currentChunkLength = 0
        $currentChunk       = ''
        $array              = $Text -split [Environment]::NewLine

        foreach ($line in $array) {
            if (($currentChunkLength + $line.Length) -lt $this.MaxMessageLength) {
                $currentChunkLength += $line.Length
                $currentChunk += ($line + [Environment]::NewLine)
            } else {
                $chunks.Add($currentChunk + [Environment]::NewLine)
                $currentChunk = ($line + [Environment]::NewLine)
                $currentChunkLength = $line.Length
            }
        }
        $chunks.Add($currentChunk)

        return $chunks
    }

    
    hidden [string]_ResolveEmoji([ReactionType]$Type) {
        $emoji = [string]::Empty
        Switch ($Type) {
            'Success'        { return 'white_check_mark' }
            'Failure'        { return 'exclamation' }
            'Processing'     { return 'gear' }
            'Warning'        { return 'warning' }
            'ApprovalNeeded' { return 'closed_lock_with_key'}
            'Cancelled'      { return 'no_entry_sign'}
            'Denied'         { return 'x'}
        }
        return $emoji
    }

    
    hidden [string]_ProcessMentions([string]$Text) {
        $processed = $Text

        $mentions = $processed | Select-String -Pattern '(?<name><@[^>]*>*)' -AllMatches | ForEach-Object {
            $_.Matches | ForEach-Object {
                [pscustomobject]@{
                    FormattedId = $_.Value
                    UnformattedId = $_.Value.TrimStart('<@').TrimEnd('>')
                }
            }
        }
        $mentions | ForEach-Object {
            if ($name = $this.UserIdToUsername($_.UnformattedId)) {
                $processed = $processed -replace $_.FormattedId, "@$name"
                $this.LogDebug($processed)
            } else {
                $this.LogDebug([LogSeverity]::Warning, "Unable to translate @mention [$($_.FormattedId)] into a username")
            }
        }

        return $processed
    }
}

function New-PoshBotSlackBackend {
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('BackendConfiguration')]
        [hashtable[]]$Configuration
    )

    process {
        foreach ($item in $Configuration) {
            if (-not $item.Token) {
                throw 'Configuration is missing [Token] parameter'
            } else {
                Write-Verbose 'Creating new Slack backend instance'
                $backend = [SlackBackend]::new($item.Token)
                if ($item.Name) {
                    $backend.Name = $item.Name
                }
                $backend
            }
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotSlackBackend'
