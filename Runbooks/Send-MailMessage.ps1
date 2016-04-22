<#
.SYNOPSIS
  Sends an email message
.DESCRIPTION
  Wraps the Send-MailMessage PowerShell command, passing the passed parameters	
.PARAMETER To
.PARAMETER CC  
.PARAMETER From
.PARAMETER Subject 
.PARAMETER Body
.PARAMETER Server
.PARAMETER AttachmentPaths
.NOTES
   AUTHOR: Jamie Sayer
   LASTEDIT: 20/04/2016
#>


param (
	[parameter(Mandatory = $true)]
	[string[]]$To,
	[parameter(Mandatory = $true)]
	[string[]]$CC,
	[parameter(Mandatory = $true)]
	[string]$From,
	[parameter(Mandatory = $true)]
	[string]$Subject,
	[parameter(Mandatory = $true)]
	[string]$Body,
	[parameter(Mandatory = $false)]
	[string[]]$AttachmentPaths,
	[parameter(Mandatory = $true)]
	[string]$Server

)
	
if ($AttachmentPaths -ne $null)
{		
	Send-MailMessage -To $To -Subject $Subject -Body $Body -SmtpServer $Server -From $From -CC $CC -Attachments $AttachmentPaths
}
else
{
	Send-MailMessage -To $To -Subject $Subject -Body $Body -SmtpServer $Server -From $From -CC $CC
}

   		
		
