######################################################################################
# PowerShell script to update Password for an ID in Windows services & Scheduled tasks
# Written by Name on date
# Modified on Date by name
#
#####################################################################################

## Declaring Parameters
$logfilename = "Update_Services_Runas_Pwd" + "_" + (Get-Date -Format "yyyyMMdd") + ".log"
$logs = $PSScriptRoot + "\" + $logfilename
$serverlist = $PSScriptRoot + "\" + "serverlist.csv"

## Function to write logs to a file
function write-log ([string]$logtext)
{

"$(Get-Date -f 'yyyy-MM-dd hh:mm:ss'): $logtext" >> $logs

}

write-log ("*************************** Start of services run as user password reset block ***************************************")

##Creating Credential Object for run as ID
try
{
write-log ("INFO: Creating Powershell credential object for the ID that requires update")
$credentials = Get-Credential -Message "Please enter required Username with Domain and its password"
$svcuser = $credentials.UserName
$id = $svcuser.Split('\')
$svcid = $id[1]
$svcpwd = $credentials.GetNetworkCredential().Password ##Saving pwd to parameter value
write-log ("INFO: Username for this password update script is *$svcuser*")
}
catch { write-log ("ERROR: There was an error while creating credential object for ID *$svcuser* error is :-" + $_.Exception.Message)  }

$servers = Import-Csv $serverlist

foreach ($server in $servers)
{

$machinename = $server.servername


### Querying local computer for list of services that are running with required run as user
try
{
write-log ("INFO: Checking for services running with Run as ID *$svcid* on computer *$machinename*")
$getservice = Get-WmiObject -Class Win32_Service -ComputerName $machinename -Filter "StartName like '%$svcid%'"
}
catch { write-log ("ERROR: There is an error while checking machine *$machinename* for services running with run as ID *$svcid* with error :_" + $_.Exception.Message)  }

if (-not ([string]::IsNullOrEmpty($getservice )))
{

write-log ("INFO: Found services on Machine *$machinename* that are running services with ID *$svcid*")
##Parsing output of each service that has same run as ID
foreach ($service in $getservice )
{
##adding servicename to Parameter
$servicename = $service.Name


##Block to update run user credential for a specific service
try
{
$loadservice = Get-WmiObject -Class Win32_Service -ComputerName $machinename -Filter "Name = '$servicename'"
$servicereset = $loadservice.change($null,$null,$null,$null,$null,$null,"$svcuser","$svcpwd")

if ($servicereset.ReturnValue -eq 0) # If block start
{ 

write-log ("INFO: Successfully updated password for logon ID *$svcid* on machine *$machinename* for service *$servicename*") 
##Attempting to restart services post pwd reset
try
{
write-log ("INFO: Restarting service *$servicename* on computer *$machinename* post password update")
$restartservice = Get-Service -ComputerName $machinename -Name $servicename | Restart-Service
Get-Service -ComputerName $machinename -Name $servicename | Restart-Service
}
catch { write-log ("ERROR: There is an error while restarting service *$servicename* on computer *$computername* with error :_" + $_.Exception.Message)  }
} # If block end


}
catch { write-log ("ERROR: There is an error while updating run as user *$svcuser* credential for service *$servicename* on computer *$machinename* with error :-" + $_.Exception.Message )  }


}

##cooling period before we check final status of services
Start-Sleep -Seconds 10

##Check final status of services after password reset
$getservice = Get-WmiObject -Class Win32_Service -ComputerName $machinename -Filter "StartName like '%$svcid%'"


foreach ($service in $getservice)
{

$servicename = $service.Name
$response = Get-Service -ComputerName $machinename -Name $servicename
$currentstatus = $response.Status

if ($currentstatus -eq "Running"){ write-log ("INFO: Final Status of service *$servicename* on computer *$computername* is *$currentstatus*") }
else { write-log ("ERROR: Attention Required! - Final Status of service *$servicename* on computer *$computername* is *$currentstatus*") }

}

}

else
{
 write-log ("INFO: No services found on Machine *$machinename* running with run/logon as ID *$svcid*")

}

}

write-log ("*************************** End of services run as user password reset block ***************************************")

