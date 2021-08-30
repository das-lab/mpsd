












$global:BlogUrl = 'www.adamtheautomator.com'
$global:WpApiUri = "https://public-api.wordpress.com/rest/v1/sites/$global:BlogUrl/posts"
$global:WpAuthorizeEndPoint = 'https://public-api.wordpress.com/oauth2/authorize'
$global:WpTokenEndpoint = 'https://public-api.wordpress.com/oauth2/token'
$global:WpComUserName = ''
$global:WpComPassword = ''
$global:WpBlogUserName = ''
$global:WpBlogPassword = ''

$oAuthTokens = @{
    'ClientID' = ''
    'CilentSecret' = ''
    'Code' = '' 
}





Function Get-WpAccessToken() {
    
    
    
    

    
    

    $PostParams = @{
        'client_id' = $oAuthTokens['ClientID']
        'redirect_uri' = "http://$global:BlogUrl"
        'response_type' = 'token'
        'blog' = $global:BlogUrl
    }

    
    $a = Invoke-WebRequest -Uri $global:WpAuthorizeEndPoint -Body $PostParams -SessionVariable sb
    $login_form = $a.Forms[0]

    
    $login_form.Fields['user_login'] = $global:WpComUserName
    $login_form.Fields['user_pass'] = [System.Web.HttpUtility]::UrlEncode($global:WpComPassword)
    $b = Invoke-WebRequest -Uri $login_form.Action -Body $login_form.Fields -Method Post -WebSession $sb
    $auth_form = $b.Forms[0]
    
    
    $auth_form.Fields['user_login'] = $global:WpComUserName
    $auth_form.Fields['user_pass'] = [System.Web.HttpUtility]::UrlEncode($global:WpComPassword)
    $c = Invoke-WebRequest -Uri $auth_form.Action -Body $auth_form.Fields -WebSession $sb
    $blog_login_form = $c.Forms[0]
    
    
    $blog_login_form.Fields['user_login'] = $global:WpBlogUserName
    $blog_login_form.Fields['user_pass'] = [System.Web.HttpUtility]::UrlEncode($global:WpBlogPassword)
    $z = Invoke-WebRequest -Uri $blog_login_form.Action  -Body $blog_login_form.Fields -WebSession $sb
    
    
    
    
    
    
    

    
}






Function Get-WpPost($PostLimit = 50) {
    $posts = Invoke-RestMethod -uri "$global:WpApiUri/?number=$PostLimit"
    $posts.posts
}

Function New-WpPost() {
    $Url = "$global:WpApiUri/new"
    $Attribs = @{
        'title'= 'testtest'
        'status' = 'draft'
    }
    $x = Invoke-RestMethod -Uri $Url -Method Post -Body $Attribs -Headers @{'Authorization' = "BEARER FIo9SNBGZO"}
}

Invoke-RestMethod -Uri "$global:WpApiUri/new/?title=testtitle&status=draft" -Method Post -



$x = Invoke-WebRequest -Uri 'http://www.adamtheautomator.com/api/get_recent_posts/' | ConvertFrom-Json




$nonce = Invoke-WebRequest -Uri 'http://www.adamtheautomator.com/api/get_nonce' -Body @{'controller' = 'posts';'method' = 'create_post'} -Method Post | ConvertFrom-Json
$post = Invoke-WebRequest -Uri 'http://www.adamtheautomator.com/api/posts/create_post' -Body @{'title' = 'testing';'status' = 'draft';'author' = 'adam';'password' = 'xhOkngWcvqHAuPm56qd';'nonce' = $nonce} -Method Post | ConvertFrom-Json



$postdata = @{
    'log' = 'adam'
    'pwd' = 'xhOkngWcvqHAuPm56qd'
    'wp-submit' = 'Log%In'
    'redirect_to' = 'http://www.adamtheautomator.com/wp-admin/'
    'testcookie' = '1'
}

$a = Invoke-WebRequest -Uri 'http://www.adamtheautomator.com/wp-login.php' -Method Post -Body $postdata -SessionVariable sv


$login_form = $a.Forms[0]
$login_form.Fields.user_login = 'adam'
$login_form.Fields.user_pass = 'xhOkngWcvqHAuPm56qd'
$r = Invoke-WebRequest -Uri $login_form.Action -Method Post -Body $login_form.Fields -WebSession $v