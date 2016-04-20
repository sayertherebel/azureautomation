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
$recips = @("team-projects@silversands.co.uk", "team-infrastructure@silversands.co.uk", "Team-Sharepoint&Development@silversands.co.uk")
$subject = "IMPORTANT Timesheet reminder"
$body = @"
All


Weekly reminder..........
 
Please ensure your timesheets are up to date. 


Thanks


Simon
"@

$CC = @("andy.petty@silversands.co.uk","james.mallalieu@silversands.co.uk")	

Start-AzureRmAutomationRunbook -Name "Send-MailMessage" `
 -Parameters @{"To"=$recips; "CC"=$CC; "From"="simon.robinson@silversands.co.uk"; "Server"="silversmtp.silversands.co.uk"; "Subject"=$subject; "Body"=$body} `
 -AutomationAccountName "OMSAutomation" -RunOn "HybridRunbookWorkersGroup" -ResourceGroupName "SSOMS"
	 
	 