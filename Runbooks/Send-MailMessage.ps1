<#
.SYNOPSIS
  Sends an email message
.DESCRIPTION
  Wraps the Send-MailMessage PowerShell command, passing the passed parameters	
.PARAMETER To 
.PARAMETER From
.PARAMETER Subject 
.PARAMETER Body
.PARAMETER Server
.NOTES
   AUTHOR: Jamie Sayer
   LASTEDIT: 20/04/2016
#>


param (
	[parameter(Mandatory = $true)]
	[object]$To,
	[parameter(Mandatory = $true)]
	[object]$From,
	[parameter(Mandatory = $true)]
	[object]$Subject,
	[parameter(Mandatory = $true)]
	[object]$Body,
	[parameter(Mandatory = $true)]
	[object]$Server

)
	
		
Send-MailMessage -To $To -Subject $Subject -Body $Body -SmtpServer $Server -From $From
   		
		
