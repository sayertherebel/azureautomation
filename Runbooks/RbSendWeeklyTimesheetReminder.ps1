$connectionName = "OMSAutoConnect"
try
{
	# Get the connection "AzureRunAsConnection "
	$servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

	"Logging in to Azure..."
	Add-AzureRmAccount `
		-ServicePrincipal `
		-TenantId $servicePrincipalConnection.TenantId `
		-ApplicationId $servicePrincipalConnection.ApplicationId `
		-CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
	if (!$servicePrincipalConnection)
	{
		$ErrorMessage = "Connection $connectionName not found."
		throw $ErrorMessage
	} else{
		Write-Error -Message $_.Exception
		throw $_.Exception
	}
}

"Logged in."
	
Set-AzureRmContext -SubscriptionId $servicePrincipalConnection.SubscriptionId

Start-AzureRmAutomationRunbook -Name "Send-MailMessage" `
 -Parameters @{"To"="'jamie.sayer@silversands.co.uk','steve.ianson@silversands.co.uk'"; "From"="simon.robinson@silversands.co.uk"; "Server"="silversmtp.silversands.co.uk"; "Subject"="Test massage"; "Body"="This is a test massage."} `
 -AutomationAccountName "OMSAutomation" -RunOn "HybridRunbookWorkersGroup" -ResourceGroupName "SSOMS"