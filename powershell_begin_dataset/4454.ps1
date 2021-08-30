



Register-PSRepository -PSGallery

<<<<<<< HEAD

Register-PSResourceRepository 'TestRepo' 'www.testrepo.com'


Register-PSResourceRepository -name 'TestRepo' -url 'www.testrepo.com'


Register-PSResourceRepository -name 'TestRepo' -url 'www.testrepo.com' -Trusted


Register-PSResourceRepository -name 'TestRepo' -url 'www.testrepo.com' -Priority 2



Register-PSResourceRepository -Repositories @(
    @{ Name = 'TestRepo1'; URL = 'https://testrepo1.com'; Trusted = $true; Credential = $cred }
    @{ Name = 'TestRepo2'; URL = '\\server\share\myrepository'; Trusted = $true }
    @{ Default = $true; Trusted = $true }
)


$repos = @(
    @{ Name = 'TestRepo1'; URL = 'https://testrepo1.com'; Trusted = $true; }
    @{ Name = 'TestRepo2'; URL = '\\server\share\myrepository'; Trusted = $true }
=======

Register-PSResourceRepository "TestRepo" "www.testrepo.com"


Register-PSResourceRepository -name "TestRepo" -url "www.testrepo.com"


Register-PSResourceRepository -name "TestRepo" -url "www.testrepo.com" -Trusted


Register-PSResourceRepository -name "TestRepo" -url "www.testrepo.com" -Priority 2



Register-PSResourceRepository -Repositories @(
    @{ Name = "TestRepo1"; URL = "https://testrepo1.com"; Trusted = $true; Credential = $cred }
    @{ Name = "TestRepo2"; URL = "\\server\share\myrepository"; Trusted = $true }
    @{ Default = $true; Trusted = $true }
)


$repos = @(
    @{ Name = "TestRepo1"; URL = "https://testrepo1.com"; Trusted = $true; }
    @{ Name = "TestRepo2"; URL = "\\server\share\myrepository"; Trusted = $true }
>>>>>>> 419fe737e7f5e0c8d31477cb656faa0ded253c37
    @{ Default = $true; Trusted = $true }
)
$repos | Register-PSResourceRepository







Get-PSResourceRepository

<<<<<<< HEAD

Get-PSResourceRepository 'TestRepo'


Get-PSResourceRepository -name 'TestRepo'


Get-PSResourceRepository 'TestRepo1', 'TestRepo2', 'TestRepo3'


Get-PSResourceRepository -name 'TestRepo1', 'TestRepo2', 'TestRepo3'


'TestRepo1' | Get-PSResourceRepository


'TestRepo1', 'TestRepo2', 'TestRepo3' | Get-PSResourceRepository
=======

Get-PSResourceRepository "TestRepo"


Get-PSResourceRepository -name "TestRepo"


Get-PSResourceRepository "TestRepo1", "TestRepo2", "TestRepo3"


Get-PSResourceRepository -name "TestRepo1", "TestRepo2", "TestRepo3"


"TestRepo1" | Get-PSResourceRepository


"TestRepo1", "TestRepo2", "TestRepo3" | Get-PSResourceRepository
>>>>>>> 419fe737e7f5e0c8d31477cb656faa0ded253c37






<<<<<<< HEAD

Set-PSResourceRepository 'TestRepo' 'www.testrepo.com'


Set-PSResourceRepository -name 'TestRepo' -url 'www.testrepo.com'


Set-PSResourceRepository 'TestRepo' -Trusted


Set-PSResourceRepository 'TestRepo' 'www.testrepo.com' -Priority 2


'TestRepo1' | Set-PSResourceRepository -url 'www.testrepo.com'



Set-PSResourceRepository -Repositories @(
    @{ Name = 'TestRepo1'; URL = 'https://testrepo1.com'; Trusted = $true; }
    @{ Name = 'TestRepo2'; URL = '\\server\share\myrepository'; Trusted = $true }
    @{ Default = $true; Trusted = $true }
)


$repos = @(
    @{ Name = 'TestRepo1'; URL = 'https://testrepo1.com'; Trusted = $true; }
    @{ Name = 'TestRepo2'; URL = '\\server\share\myrepository'; Trusted = $true }
=======

Set-PSResourceRepository "TestRepo" "www.testrepo.com"


Set-PSResourceRepository -name "TestRepo" -url "www.testrepo.com"


Set-PSResourceRepository "TestRepo" -Trusted


Set-PSResourceRepository "TestRepo" "www.testrepo.com" -Priority 2


"TestRepo1" | Set-PSResourceRepository -url "www.testrepo.com"



Set-PSResourceRepository -Repositories @(
    @{ Name = "TestRepo1"; URL = "https://testrepo1.com"; Trusted = $true; }
    @{ Name = "TestRepo2"; URL = "\\server\share\myrepository"; Trusted = $true }
    @{ Default = $true; Trusted = $true }
)


$repos = @(
    @{ Name = "TestRepo1"; URL = "https://testrepo1.com"; Trusted = $true; }
    @{ Name = "TestRepo2"; URL = "\\server\share\myrepository"; Trusted = $true }
>>>>>>> 419fe737e7f5e0c8d31477cb656faa0ded253c37
    @{ Default = $true; Trusted = $true }
)
$repos | Set-PSResourceRepository






<<<<<<< HEAD

Unregister-PSResourceRepository -name 'TestRepo'


Unregister-PSResourceRepository -name 'TestRepo1', 'TestRepo2', 'TestRepo3'


'TestRepo1' | Unregister-PSResourceRepository


'TestRepo1', 'TestRepo2', 'TestRepo3' | Unregister-PSResourceRepository
=======

Unregister-PSResourceRepository -name "TestRepo"


Unregister-PSResourceRepository -name "TestRepo1", "TestRepo2", "TestRepo3"


"TestRepo1" | Unregister-PSResourceRepository


"TestRepo1", "TestRepo2", "TestRepo3" | Unregister-PSResourceRepository
>>>>>>> 419fe737e7f5e0c8d31477cb656faa0ded253c37
