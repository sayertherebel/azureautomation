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
.NOTES
   AUTHOR: Jamie Sayer
   LASTEDIT: 20/04/2016
#>


param (
	[parameter(Mandatory = $true)]
	[string[]]$To,
	[parameter(Mandatory = $false)]
	[string[]]$CC,
	[parameter(Mandatory = $true)]
	[string]$From,
	[parameter(Mandatory = $true)]
	[string]$Subject,
	[parameter(Mandatory = $true)]
	[string]$Body,
	[parameter(Mandatory = $true)]
	[string]$Server

)
	
		
Send-MailMessage -To $To -Subject $Subject -Body $Body -SmtpServer $Server -From $From -CC $CC
   		
		
