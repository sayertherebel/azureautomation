Param(
    [string]$CustomerName,
    [string]$CredentialObjectName,
    [string]$SubscriptionName,
    [int[]]$OfflineSets,
    [int[]]$OnlineSets

)

#Retrieve credential object by name

$objCredential = $null
try {
    $objCredential = Get-AutomationPSCredential -Name $CredentialObjectName    
}
catch {}

if($objCredential)
{

    #Bind to remote Azure instance using creds

    try {
        Add-AzureRmAccount -Credential $objCredential -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error ("Failed to bind to Azure RM: {0}" -f $_.Exception)
        return -1;
    }
    
    try {
        Select-AzureRmSubscription -SubscriptionName $SubscriptionName -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error ("Failed to bind to subscription with name {0} RM: {1}" -f $SubscriptionName, $_.Exception)
        return -1;
    }
    
    Write-Verbose "Bound to Remote Azure."

    $arrMachinesValidPowerState = @() # Machines whose power state is as expected
    $arrMachinesInvalidOff = @() # Machines that should be ON, and are NOT
    $arrMachinesInvalidOn = @() # Machines that should be OFF, and are NOT

    $boolInvalidState = $false # When an unexpected power state is detected, this is set to true and the reporting process at the end is handled differently to highlight that there is an issue

    #Enumerate the names of the machines that should currently be offline by querying the passed set identifiers
    foreach ($set in $OfflineSets)
    {
        $arrResults = @(Find-AzureRmResource -TagName AUTOSHUTDOWNSET -TagValue "$set" | Where-Object {$_.ResourceType -eq "Microsoft.Compute/virtualMachines"} | Select Name, ResourceGroupName)

        foreach ($result in $arrResults)
        {
            $strPowerState = ""
            #Query the powerstate of the VM
            $strPowerState = (Get-AzureRmVM -ResourceGroupName $result.ResourceGroupName -Name $result.Name -Status -ErrorAction SilentlyContinue -WarningAction $WarningPreference).Statuses.Code[1]
            if($strPowerState)
            {
                if($strPowerState.ToUpper() -eq "POWERSTATE/DEALLOCATED")
                {
                    $arrMachinesValidPowerState += @{Set = $set; Name = $result.Name; ResourceGroup = $result.ResourceGroupName; PowerState = $strPowerState}        
                }
                else
                {
                    $arrMachinesInvalidOn += @{Set = $set; Name = $result.Name; ResourceGroup = $result.ResourceGroupName; PowerState = $strPowerState}
                    $boolInvalidState = $true
                }
            }
            
        }

    }

    #Enumerate the names of the machines that should currently be online by querying the passed set identifiers
    foreach ($set in $OnlineSets)
    {
        $arrResults = @(Find-AzureRmResource -TagName AUTOSHUTDOWNSET -TagValue "$set" | Where-Object {$_.ResourceType -eq "Microsoft.Compute/virtualMachines"} | Select Name, ResourceGroupName)

        foreach ($result in $arrResults)
        {
            $strPowerState = ""
            #Query the powerstate of the VM
            $strPowerState = (Get-AzureRmVM -ResourceGroupName $result.ResourceGroupName -Name $result.Name -Status -ErrorAction SilentlyContinue -WarningAction $WarningPreference).Statuses.Code[1]

            if($strPowerState)
            {
                if($strPowerState.ToUpper() -eq "POWERSTATE/RUNNING")
                {
                    $arrMachinesValidPowerState += @{Set = $set; Name = $result.Name; ResourceGroup = $result.ResourceGroupName; PowerState = $strPowerState}        
                }
                else
                {
                    $arrMachinesInvalidOff += @{Set = $set; Name = $result.Name; ResourceGroup = $result.ResourceGroupName; PowerState = $strPowerState}
                    $boolInvalidState = $true        
                }
            }

        }

    }

    #Format output

    if($boolInvalidState)
    {
        $strSubject = ("URGENT: {0}: Azure VM in unexpected power state" -f $CustomerName)

        $strBody = ("When validating Azure VMs for customer '{0}', one or more machines was found to be in an unexpected power state.`n" -f $CustomerName)

        if($arrMachinesInvalidOff)
        {
            $strBody = $strBody + ("`nThe following machine(s) were expected to be in a RUNNING state but were not:``nn{0,-20}`t{1,-20}`t{2,-15}`n" -f "Name", "ResourceGroup", "PowerState")
            foreach ($machine in $arrMachinesInvalidOff)
            {
                $strBody = $strBody + ("{0,-20}`t{1,-20}`t{2,-15}`n" -f $machine.Name, $machine.ResourceGroup, $machine.PowerState)
            }
        }

        if($arrMachinesInvalidOn)
        {
            $strBody = $strBody + ("`nThe following machine(s) were expected to be in a DEALLOCATED state but were not:`n`n{0,-20}`t{1,-20}`t{2,-15}`n" -f "Name", "ResourceGroup", "PowerState")
            foreach ($machine in $arrMachinesInvalidOn)
            {
                $strBody = $strBody + ("{0,-20}`t{1,-20}`t{2,-15}`n" -f $machine.Name, $machine.ResourceGroup, $machine.PowerState)
            }
        }

        if($arrMachinesValidPowerState)
        {
            $strBody = $strBody + ("`nThe following machine(s) are in a CORRECT power state:`n`n{0,-20}`t{1,-20}`t{2,-15}`n" -f "Name", "ResourceGroup", "PowerState")
            foreach ($machine in $arrMachinesValidPowerState)
            {
                $strBody = $strBody + ("{0,-20}`t{1,-20}`t{2,-15}`n" -f $machine.Name, $machine.ResourceGroup, $machine.PowerState)
            }   
        }

        $strBody = $strBody + ("`nPlease investigate the virtual machine states and the power automation scripts!")

        Write-Output @{Body = $strBody; Subject = $strSubject}
        

		 

    }
    else {
        
        $strSubject = ("REPORT: {0}: Azure VM power state(s)" -f $CustomerName)

        $strBody = ("The Azure VM power states for customer '{0}' have been validated.`n" -f $CustomerName)

        if($arrMachinesValidPowerState)
        {
            $strBody = $strBody + ("`nThe following machine(s) are in a CORRECT power state:`n`n{0,-20}`t{1,-20}`t{2,-15}`n" -f "Name", "ResourceGroup", "PowerState")
            foreach ($machine in $arrMachinesValidPowerState)
            {
                $strBody = $strBody + ("{0,-20}`t{1,-20}`t{2,-15}`n" -f $machine.Name, $machine.ResourceGroup, $machine.PowerState)
            }   
        }

        $strBody = $strBody + ("`nThis is a report only, no action is required.")

        Write-Output @{Body = $strBody; Subject = $strSubject}

    }



}
else {
    Write-Error ("Failed to bind to select credential object with name {0} RM: {1}" -f $CredentialObjectName, $_.Exception)
}
