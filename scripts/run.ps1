#!/bin/pwsh

. /var/run/config/bmc/variables.ps1

Import-Module /projects/powershell-redfish-lenovo/examples/get_system_log.psm1

$bmchash = ConvertFrom-Json -InputObject $bmc -AsHashtable
$slackMessage = @"
BMC: {0}
Node: {1}
Severity: {2}
Message: {3}
"@


$last24h = (Get-Date).AddHours(-24)

foreach ($key in $bmchash.Keys) {

    $credential = Import-Clixml -Path $bmchash[$key].secret

    $password = $credential.GetNetworkCredential().Password
    $username = $credential.GetNetworkCredential().UserName

    try {
        # array of json strings
        $listJsonStringLogs = get_system_log -ip $bmchash[$key].ip -username $username -password $password

        foreach ($jsonString in $listJsonStringLogs) {
            $logs = ConvertFrom-Json -Depth 10 -InputObject $jsonString -AsHashtable
            $logsLast24h = $logs | Where-Object { $_.Created -ge $last24h }

            foreach ($l in $logsLast24h) {
                try {
                    if ($l.ContainsKey("Severity")) {
                        if (-not $l.Severity.ToLower().Contains("ok")) {
                            $l.Message
                            $l.Severity
                            Send-SlackMessage -Uri $Env:SLACK_WEBHOOK_URI -Text ($slackMessage -f $bmchash[$key].ip, $bmchash[$key].node, $l.Severity, $l.Message)
                        }
                    }
                }
                catch {} # ignore
            }
        }
    }
    catch {
        Get-Error
    }
    finally {}
}

exit 0
