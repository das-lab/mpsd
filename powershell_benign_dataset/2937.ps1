$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

properties {
    
    
    
    $container = @{}
}

Task default -depends task2

Task Step1 -alias task1 {
    'Hi from Step1 (task1)'
}

Task Step2 -alias task2 -depends task1 {
    'Hi from Step2 (task2)'
}
