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

$recips = @("adrian.coombes@silversands.co.uk","martin.barringer@silversands.co.uk")
$subject = "Vmware Snapshot Report"
$body = "Weekly VMware snapshot report."
$attachments = @("D:\VmwareSnapshotReport\snapshot_Query.csv")

$CC = @("simon.robinson@silversands.co.uk","andy.petty@silversands.co.uk","steve.ianson@silversands.co.uk","jamie.stockton@silversands.co.uk")	

$jobId = (Start-AzureRmAutomationRunbook -Name "RbGenerateVMSnapshotReport" -AutomationAccountName "OMSAutomation" -RunOn "HybridRunbookWorkersGroup" -ResourceGroupName "SSOMS").JobID

do {
if($Status -ne $null)
{
“Job not complete – Status: $Status – Sleeping”
Start-Sleep -Seconds 2
}
$Status = Get-AzureRMAutomationJob -Id $jobId -ResourceGroupName "SSOMS" -AutomationAccountName "OMSAutomation" | Select-Object -ExpandProperty Status
} while (($status -ne “Completed”) -and ($status -ne “Failed”) -and ($status -ne “Suspended”) -and ($status -ne “Stopped”) )

if($status -eq “Completed”)
{
	Start-AzureRmAutomationRunbook -Name "Send-MailMessage" `
	 -Parameters @{"To"=$recips; "CC"=$CC; "From"="svc_OrchSrvAcc@silversands.co.uk"; "Server"="silversmtp.silversands.co.uk"; "Subject"=$subject; "Body"=$body; "AttachmentPaths"=$attachments} `
	 -AutomationAccountName "OMSAutomation" -RunOn "HybridRunbookWorkersGroup" -ResourceGroupName "SSOMS"
		 
}
	

	 