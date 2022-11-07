######################################################################################
# PowerShell script to update Password for an ID in Windows services & Scheduled tasks
# Written by Name on date
# Modified on Date by name
#
#####################################################################################

## Declaring Parameters
$taskpath = "\Task Path\"
$logfilename = "Update_ScheduledTask_Runas_Pwd" + "_" + (Get-Date -Format "yyyyMMdd") + ".log"
$logs = $PSScriptRoot + "\" + $logfilename
$serverlist = $PSScriptRoot + "\" + "serverlist.csv"

## Function to write logs to a file
function write-log ([string]$logtext)
{

"$(Get-Date -f 'yyyy-MM-dd hh:mm:ss'): $logtext" >> $logs

}

write-log ("*************************** Start of scheduled tasks run as user password update block ***************************************")

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

##Querying tasks that are running with certain run as ID
try
{
$tasks = Get-ScheduledTask -CimSession $machinename -TaskPath $taskpath | Where-Object { $_.Principal.UserId -eq $svcuser }
write-log ("INFO: Queried computer *$machinename* for task scheduler jobs running with Run as ID *$svcid*")
}
catch { write-log ("ERROR: There is an error while querying machine *$machinename* for scheduled tasks running with run as ID *$svcid* with error :_" + $_.Exception.Message)  }


if (-not ([string]::IsNullOrEmpty($tasks)))
{
## working on each scheduled task
foreach ($task in $tasks)
{

$taskname = $task.TaskName

write-log ("INFO: Started to work on Task *$taskname* on server *$machinename*")

##Disabling scheduled task
try
{
#Get-ScheduledTask -CimSession $machinename -TaskName $taskname | Disable-ScheduledTask
$disabletask = Get-ScheduledTask -CimSession $machinename -TaskName $taskname | Disable-ScheduledTask
write-log ("INFO: Disabled scheduled task *$taskname*")
}
catch { write-log ("ERROR: Error while disabling scheduled task *$taskname* with error:- " + $_.Exception.Message) }

##Updating cred
try
{
Get-ScheduledTask -CimSession $machinename -TaskName $taskname | Set-ScheduledTask -CimSession $machinename -User $svcuser -Password $svcpwd
write-log ("INFO: Password update has been done for scheduled task *$taskname*")
}
catch { write-log ("ERROR: There is an error while updating password for *$svcid* on scheduled task *$taskname* with error :-" + $_.Exception.Message)}


##Enabling scheduled task
try
{
write-log ("INFO: Enabling scheduled task *$taskname*")
#Get-ScheduledTask -CimSession $machinename -TaskName $taskname | Enable-ScheduledTask
$enabletask = Get-ScheduledTask -CimSession $machinename -TaskName $taskname | Enable-ScheduledTask
}
catch { write-log ("ERROR: Error while enabling scheduled task *$taskname* with error:- " + $_.Exception.Message) }

}

}
else
{

write-log ("INFO: No Scheduled tasks on Machine *$machinename* running with run/logon as ID *$svcid* in *$taskpath*")

}



##Checking final status of the scheduled task

try
{
$tasks = Get-ScheduledTask -CimSession $machinename -TaskPath $taskpath | Where-Object { $_.Principal.UserId -eq $svcuser }
write-log ("INFO: Queried computer *$machinename* for task scheduler jobs running with Run as ID *$svcuser*")
}
catch { write-log ("ERROR: There is an error while querying machine *$machinename* for scheduled tasks running with run as ID *$svcid* with error :_" + $_.Exception.Message)  }

foreach ($task in $tasks)
{
$taskname = $task.TaskName

$getstatus = Get-ScheduledTask -CimSession $machinename -TaskName $taskname
$status = $getstatus.State

write-log ("INFO: Final status of the scheduled task *$taskname* is *$status* on Machine *$machinename*")

}

}
write-log ("*************************** End of scheduled tasks run as user password Update block ***************************************")