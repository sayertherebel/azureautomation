workflow StopStart-ServerAdvanced
{
    param (
	
        [Parameter(Mandatory=$true)]
        [String] 
        $CredsObjectName,
		
        [Parameter(Mandatory=$true)]
        [String] 
        $SubscriptionId,
		
        [Parameter(Mandatory=$true)]
        [Object[]] 
        $OddVMs,
		
        [Parameter(Mandatory=$true)]
        [Object[]] 
        $EvenVMs,
		
        [Parameter(Mandatory=$true)]
        [Boolean] 
        $StopMode,
		
        [Parameter(Mandatory=$false)]
        [Boolean] 
        $LiveMode,
		
        [Parameter(Mandatory=$false)]
        [Boolean] 
        $VMsStayProvisioned,
		
        [Parameter(Mandatory=$false)]
        [Boolean] 
        $ReverseSetsInStartMode
		
	)
	
    # StopStart-ServerAdvanced -CredsObjectName <string> -SubscriptionId <string> -OddVMs <String[]> -EvenVMs <String[]> -StopMode <Boolean> [-VMsStayProvisioned <Boolean>] [-ReverseSetsInStartMode <Boolean>]
	#
	# (c) Jamie Sayer, Silversands
	#
	# Azure Automation script to start or stop a subset of VMs.
	# The number of days since the 'UNIX' epoch is calculated. If the number is even,
	# the VMs supplied in the $EvenVMs are either stopped or started according to 
	# the variable $StopMode, and vice-versa.
	#
	# A valid AutomationPSCredential asset must be created alongside the Azure
	# Runbook and its name passed as the -CredsObjectName.
	
	Write-Output "Advanced VM Shutdown Script"
	
	$cred = $null
	
	Write-Output "Attempt Azure bind..."
	
	try
	{
		$cred = Get-AutomationPSCredential -Name $CredsObjectName 
		
		Write-Output "Credentials retrieved."
	}
	catch{
		Write-Output "An error occurred attempting to retrieve Azure credential object. Verify the value of -CredsObjectName. Processing will halt."
		exit
	}
		
    try
	{
		Add-AzureAccount -Credential $cred 
		Write-Output "Bound to Azure."
	}
	catch{
		Write-Output "An error occurred attempting to bind to Azure. Processing will halt."
		Write-Output $_.Exception
		exit
	}
	
    try
	{
		Select-AzureSubscription -SubscriptionId $SubscriptionId -Default
		Write-Output "Selected SubscriptionId '$SubscriptionId'"
	}
	catch{
		Write-Output "An error occurred attempting to select subscription with name '$SubscriptionId'. Processing will halt."
		Write-Output $_.Exception
		exit
	}
	
	#Phew! We made it this far...
	
	Write-Output "Ready to perform processing."
	
	if($LiveMode)
	{	
		Write-Output "LIVE mode."
	}
	else
	{
		Write-Output "TEST mode."
	}
    
	$EpochDays = (New-TimeSpan "01 January 1970 00:00:00" $(Get-Date -format "dd MMM yyyy 00:00:00")).TotalDays
	
	[Boolean] $EvenMode = ($EpochDays % 2 -eq 0)
	
	Write-Output "EpochDays: $EpochDays"
		
	if ($StopMode)
	{
		Write-Output "STOP mode."
	
		if($EvenMode) { $VMsToProcess = $EvenVMs; $AlternateVMs = $OddVMs } else { $VMsToProcess = $OddVMs; $AlternateVMs = $EvenVMs }
	
		if($EvenMode) { Write-Output "'Even' VMs will be processed."} else { Write-Output "'Odd' VMs will be processed."}
	
		#First verify all servers in the alternate collection are Running
		
		$AlternatesRunning = $true
				
		foreach ($VM in $AlternateVMs)
		{
			Write-Output ("Processing alternate VM: " + $VM.Name + " (Service: "  + $VM.Service + ")")
			$VMBinding = $null
			try
			{
				$VMBinding = @(Get-AzureVM -Name $VM.Name -Service $VM.Service)
			}
			catch{}
			
			if ($VMBinding.Count -ne 1)
			{
				Write-Output "The number of objects returned was not equal to 1."
				$AlternatesRunning = $false
			}
			else
			{
				if(-not ($VMBinding.InstanceStatus -eq "ReadyRole")) { Write-Output "The alternate is not running."; $AlternatesRunning = $false }
			}
		}
		
		if ($AlternatesRunning)
		{
			#Stop VMs
			
			Write-Output "Alternate VMs are all running. Processing VMs to be stopped..."
			
			foreach ($VM in $VMsToProcess)
			{
				Write-Output ("Processing VM: " + $VM.Name + " (Service: "  + $VM.Service + ")")
				$VMBinding = $null
				try
				{
					$VMBinding = @(Get-AzureVM -Name $VM.Name -Service $VM.Service)
				}
				catch{}
				
				if ($VMBinding.Count -ne 1)
				{
					Write-Output "The number of objects returned was not equal to 1, we will not attempt to stop the VM."
					
				}
				else
				{
					if($VMBinding.InstanceStatus -eq "ReadyRole")
					{ 
						if ($LiveMode)
						{
							Write-Output "Requesting VM Stop."
							try
							{
								if($VMsStayProvisioned)
								{
									$VMBinding | Stop-AzureVM -Force -StayProvisioned
								}
								else
								{
									$VMBinding | Stop-AzureVM -Force
								}
								Write-Output "Succeeded."
							}
							catch
							{
								Write-Output "An error occurred when requesting the VM to stop."
							}
						}
						else
						{
							Write-Output "TEST mode: At this point we would have attempting to stop the VM."
						}
					}
					else
					{
						Write-Output "The VM was not in a ready state, we will not attempt to stop it."
					}
				}
			}
			
		}
		else
		{
			Write-Output "One or more alternates was not ready. Processing will halt."
			Exit
		}
	}
	else
	{
		#Start mode
		Write-Output "START mode."
					
		if ($ReverseSetsInStartMode)
		{
			if($EvenMode) { $VMsToProcess = $OddVMs; $AlternateVMs = $EvenVMs } else { $VMsToProcess = $EvenVMs; $AlternateVMs = $OddVMs }
			
			if($EvenMode) { Write-Output "'Odd' VMs will be processed."} else { Write-Output "'Even' VMs will be processed."}
			
		}
		else
		{
			if($EvenMode) { $VMsToProcess = $EvenVMs; $AlternateVMs = $OddVMs } else { $VMsToProcess = $OddVMs; $AlternateVMs = $EvenVMs }
			
			if($EvenMode) { Write-Output "'Even' VMs will be processed."} else { Write-Output "'Odd' VMs will be processed."}
		}
					
		foreach ($VM in $VMsToProcess)
		{
			Write-Output ("Processing VM: " + $VM.Name + " (Service: "  + $VM.Service + ")")
			$VMBinding = $null
			try
			{
				$VMBinding = @(Get-AzureVM -Name $VM.Name -Service $VM.Service)
			}
			catch{}
			
			if ($VMBinding.Count -ne 1)
			{
				Write-Output "The number of objects returned was not equal to 1, we will not attempt to start the VM."
				
			}
			else
			{
				if(-not ($VMBinding.InstanceStatus -eq "ReadyRole"))
				{ 
					if ($LiveMode)
					{
						Write-Output "Requesting VM Start."
						try
						{
							$VMBinding | Start-AzureVM
							Write-Output "Succeeded."
						}
						catch
						{
							Write-Output "An error occurred when requesting the VM to start."
						}
					}
					else
					{
						Write-Output "TEST mode: At this point we would have attempting to start the VM."
					}
				}
				else
				{
					Write-Output "The VM was already in a ready state, we will not attempt to start it."
				}
			}
		}
		
	}
	
	
	
}