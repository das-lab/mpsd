


$platform = 'windows'

Add-Type -Path "$ModulePath/lib/$platform/Microsoft.ServiceBus.dll"


$factory      = [Microsoft.ServiceBus.Messaging.MessagingFactory]::CreateFromConnectionString($connectionString)
$receiver     = $factory.CreateMessageReceiver($QueueName, [Microsoft.ServiceBus.Messaging.ReceiveMode]::PeekLock)
$bindingFlags = [Reflection.BindingFlags] 'Public,Instance'


while (-not $receiver.IsClosed -and $ReceiverControl.ShouldRun) {
    $msg = $receiver.ReceiveAsync($receiveTimeout).GetAwaiter().GetResult()
    if ($msg) {
        $receiver.CompleteAsync($msg.LockToken).GetAwaiter().GetResult() > $null

        
        $stream = $msg.GetType().GetMethod('GetBody', $bindingFlags, $null, @(), $null).MakeGenericMethod([System.IO.Stream]).Invoke($msg, $null)
        $streamReader = [System.IO.StreamReader]::new($stream)
        $payload = $streamReader.ReadToEnd()
        $streamReader.Dispose()
        $stream.Dispose()
        if (-not [string]::IsNullOrEmpty($payload)) {
            $ReceiverMessages.Enqueue($payload) > $null
        }
    }
}
$receiver.Close()
