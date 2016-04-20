
<#
.SYNOPSIS
  Sends an email message
.DESCRIPTION
  This runbook connects to Azure and scales the passed VM either up or down based on the presence of a tag
  REQUIRED AUTOMATION ASSETS
  1. An Automation variable asset called "AzureSubscriptionId" that contains the GUID for this Azure subscription of the VM.  
  2. An Automation credential asset called "AzureCredential" that contains the Azure AD user credential with authorization for this subscription. 
.PARAMETER PSCredentialName
   Required 
   Name of the PSCredential resource 
.PARAMETER Subject
   Required 
   Message subject
.NOTES
   AUTHOR: Jamie Sayer, based on a Azure Compute Team sample
   LASTEDIT: 19/04/2016
#>

param (
	[parameter(Mandatory = $true)]
    [object]$Subject,
	[parameter(Mandatory = $true)]
    [object]$Body,
	[parameter(Mandatory = $true)]
    [object]$To,
	[parameter(Mandatory = $true)]
    [object]$From,
	[parameter(Mandatory = $true)]
    [object]$Server
)


workflow SendMailUsingOffice365 
{ 

      
     Send-MailMessage ` 
    -To $To 
    -Subject $Subject  ` 
    -Body $Body ` 
    -SmtpServer $Server `
    -From $userid
   
} 