######################################################################################
# PowerShell script restart windows services
# Written by Name on date
# Modified on Date by name
#
#####################################################################################

## Declaring Parameters
$logfilename = "Restart_Windows_Services" + "_" + (Get-Date -Format "yyyyMMdd") + ".log"
$logs = $PSScriptRoot + "\" + $logfilename
$serverlist = $PSScriptRoot + "\" + "serverlist.csv"

## Function to write logs to a file
function write-log ([string]$logtext)
{

"$(Get-Date -f 'yyyy-MM-dd hh:mm:ss'): $logtext" >> $logs

}

write-log ("*************************** Start of the scriptk ***************************************")



$servers = Import-Csv $serverlist

foreach ($server in $servers)
{

$machinename = $server.servername
$servicename = $server.servicename

write-log ("INFO: Working on to restart service *$servicename* on computer *$machinename*")
$restartservice = Get-Service -ComputerName $machinename -Name $servicename | Restart-Service

}

write-log ("*************************** End of the script ***************************************")

