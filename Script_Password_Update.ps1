######################################################################################
# PowerShell script to update Password for an ID in Windows services & Scheduled tasks
# Written by Name on date
# Modified on Date by name
#
#####################################################################################

## Declaring Parameters
$Domain = "domain"
$svcid = "ID_Name"
$svcuser = "$Domain" + "\" + "$svcid"
$logfilename = "ID__update" + "_" + (Get-Date -Format "yyyyMMdd") + ".log"
$logs = $PSScriptRoot + "\" + $logfilename

## Function to write logs to a file
function write-log ([string]$logtext)
{

"$(Get-Date -f 'yyyy-MM-dd hh:mm:ss'): $logtext" >> $logs

}

$machinename = hostname


write-log ("*************************** Start of services run as user password reset block ***************************************")
### Querying local computer for list of services that are running with required run as user
try
{
$getservice = Get-CimInstance -ClassName Win32_Service -Filter "StartName = '%$svcid%"
write-log ("INFO: Successfully queried computer *$machinename* for services running with Run as ID *$svcid*")
}
catch { write-log ("ERROR: There is an error while querying machine *$machinename* for services running with run as ID *$svcid* with error :_" + $_.Exception.Message)  }

##Creating Credential Object for run as ID
try
{
$credentials = Get-Credential -Message "Please enter credentials for run as ID" -UserName $svcuser
$svcpwd = $credentials.GetNetworkCredential().Password ##Saving pwd to parameter value
write-log ("INFO: Created Powershell credential object for ID *$svcuser*")
}
catch { write-log ("ERROR: There was an error while creating credential object for ID *$svcuser* error is :-" + $_.Exception.Message)  }

##Parsing output of each service that has same run as ID
foreach ($service in $getservice )
{
##adding servicename to Parameter
$servicename = $service.Name


##Block to update run user credential for a specific service
try
{
$servicereset = $service.change($null,$null,$null,$null,$null,$null,"$svcuser","$svcpwd")
write-log ("INFO: Successfully updated service *$servicename* with credentials of run as ID *$svcuser*")
}
catch { write-log ("ERROR: There is an error while updating run as user *$svcuser* credential for service *$servicename* on computer *$machinename* with error :-" + $_.Exception.Message )  }



##Attempting to restart services post pwd reset
try
{
Get-Service -Name $servicename | Restart-Service
write-log ("INFO: Successfully triggered restart of service *$servicename* on computer *$machinename*")
}
catch { write-log ("ERROR: There is an error while restarting service *$servicename* on computer *$computername* with error :_" + $_.Exception.Message)  }

}


##cooling period before we check final status of services
Start-Sleep -Seconds 30

##Check final status of services after password reset
try
{
$getservice = Get-CimInstance -ClassName Win32_Service -Filter "StartName = '%$svcid%"
write-log ("INFO: Successfully queried computer *$machinename* for services running with Run as ID *$svcid*")
}
catch { write-log ("ERROR: There is an error while querying machine *$machinename* for services running with run as ID *$svcid* with error :_" + $_.Exception.Message)  }

foreach ($service in $getservice)
{

$servicename = $service.Name
$response = Get-Service -Name $servicename
$currentstatus = $response.Status

if ($currentstate -eq "Running"){ write-log ("INFO: Final Status of service *$servicename* on computer *$computername* is *$currentstatus*") }
else { write-log ("ERROR: Attention Required! - Final Status of service *$servicename* on computer *$computername* is *$currentstatus*") }

}

write-log ("*************************** End of services run as user password reset block ***************************************")

write-log ("*************************** Start of scheduled tasks run as user password update block ***************************************")

##Querying tasks that are running with certain run as ID
try
{
$tasks = Get-ScheduledTask | Where-Object { $_.Principal.UserId -eq $svcid }
write-log ("INFO: Queried computer *$machinename* for task scheduler jobs running with Run as ID *$svcid*")
}
catch { write-log ("ERROR: There is an error while querying machine *$machinename* for scheduled tasks running with run as ID *$svcid* with error :_" + $_.Exception.Message)  }


## working on each scheduled task
foreach ($task in $tasks)
{

$taskname = $tasks.TaskName

write-log ("INFO: Started to work on Task *$taskname*")

##Disabling scheduled task
try
{
Get-ScheduledTask -TaskName $taskname | Disable-ScheduledTask
write-log ("INFO: Disabled scheduled task *$taskname*")
}
catch { write-log ("ERROR: Error while disabling scheduled task *$taskname* with error:- " + $_.Exception.Message) }

##Updating cred
try
{
Get-ScheduledTask -TaskName $taskname | Set-ScheduledTask -User $svcid -Password $svcpwd
write-log ("INFO: Password reset has been done for scheduled task *$taskname*")
}
catch { write-log ("ERROR: There is an error while updating password for *$svcid* on scheduled task *$taskname* with error :-" + $_.Exception.Message)}


##Enabling scheduled task
try
{
Get-ScheduledTask -TaskName $taskname | Enable-ScheduledTask
write-log ("INFO: Enabled scheduled task *$taskname*")
}
catch { write-log ("ERROR: Error while enabling scheduled task *$taskname* with error:- " + $_.Exception.Message) }

}

##Checking final status of the scheduled task

try
{
$tasks = Get-ScheduledTask | Where-Object { $_.Principal.UserId -eq $svcid }
write-log ("INFO: Queried computer *$machinename* for task scheduler jobs running with Run as ID *$svcid*")
}
catch { write-log ("ERROR: There is an error while querying machine *$machinename* for scheduled tasks running with run as ID *$svcid* with error :_" + $_.Exception.Message)  }

foreach ($task in $tasks)
{
$taskname = $tasks.TaskName

$status = Get-ScheduledTask -TaskName $taskname

write-log ("INFO: Final status of the scheduled task *$taskname* is *$status*")


}

write-log ("*************************** End of scheduled tasks run as user password Update block ***************************************")