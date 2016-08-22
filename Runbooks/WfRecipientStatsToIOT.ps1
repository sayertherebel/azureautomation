workflow WfRecipientStatsToIOT
{
	Param($messages)
	Write-Output ("{0} Messages in scope..." -f $messages.Count)
	
	$checkpointCounter = 0
	
	foreach ($message in $messages)
	{
		$checkpointCounter++
		if($checkpointCounter -eq 20)
		{
			$checkpointCounter = 0
			CheckPoint-Workflow
		}
		
        Push-IoTEvent -strConn "HostName=IotHubRecipientStats.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=SCwNpfWZaAgJTT1IMPRuvMpXon6cGKWFFZlqyM+thOc=" -strIOTDevice "TestTwo" -strHubURI IotHubRecipientStats.azure-devices.net -objDatagram @{"ReceivedDate"=$message.ReceivedDateTime;"SenderAddress"=$message.SenderAddress;"RecipientAddress"=$message.RecipientAddress;"Direction"=$message.direction} -aSyncSend
	}
}