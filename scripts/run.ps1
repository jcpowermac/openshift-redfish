#!/bin/pwsh
. /var/run/config/bmc/variables.ps1

Import-Module /projects/powershell-redfish-lenovo/examples/get_system_logs.psm1

Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -Confirm:$false | Out-Null
$bmchash = ConvertFrom-Json -InputObject $bmc -AsHashtable
$slackMessage = @"
BMC: {0}
Host: {1}
"@

# Id                             2833
# @odata.context                 /redfish/v1/$metadata#LogEntry.LogEntry
# @odata.type                    #LogEntry.v1_11_0.LogEntry
# @odata.id                      /redfish/v1/Systems/1/LogServices/AuditLog/Entries/2833
# EventId                        0x400000a200000000
# Oem                            {[Lenovo, @{EventType=0; ReportingChain=XCC; IsLocalEvent=True; Ra…
# @odata.etag                    "ejUxX1N0YW5kYXJkTG9nRW50cnkK2833"
# EntryType                      Oem
# Name                           LogEntry
# OemRecordFormat                Lenovo
# Description                    This resource is used to represent a log entry for log services fo…
# Created                        7/20/2023 3:35:54 PM
# Severity                       OK
# Message                        User LXPM has mounted file tdm_image.img from Local.
# OemLogEntryCode                Lenovo0079
# MessageArgs                    {IPMIMBOX, 07/20/2023, 15:37:11, false…}
# EventGroupId                   0


$last24h = (Get-Date).AddHours(-24)

foreach ($key in $bmchash.Keys) {

    $credential = Import-Clixml -Path $bmchash[$key].secret

    $password = $credential.GetNetworkCredential().Password
    $username = $credential.GetNetworkCredential().UserName

    try {
        # array of json strings
        $listJsonStringLogs = get_system_logs -ip $bmchash[$key].ip -username $username -password $password

        foreach ($jsonString in $listJsonStringLogs) {
            $logs = ConvertFrom-Json -InputObject $jsonString -AsHashtable

            foreach ($l in $logs) {
                $l.Created

            }
        }




        #Send-SlackMessage -Uri $Env:SLACK_WEBHOOK_URI -Text ($slackMessage -f $cihash[$key].vcenter)
    }
    catch {
        Get-Error
    }
    finally {}
}

exit 0
