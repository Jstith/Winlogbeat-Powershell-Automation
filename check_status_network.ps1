<# This script checks a list of IP addresses or hosts passed via CSV for a successfully running Winlogbeat service.

The script first checks if WinRm is enabled, and if it is checks for the presence of the winlogbeat service.
Usage:

.\check_status_network.ps1 .\hosts.csv

#>

$ErrorActionPreference = 'silentlycontinue'

Import-Csv $args[0] | ForEach-Object {
    $result = $null
    $result = Test-WSMan -ComputerName $($_.TargetHost)
    if($result -eq $null) {
        Write-Host "$($_.TargetHost) WinRM Failure"
    }
    else {
        Write-Host -NoNewline "$($_.TargetHost) WinRM Success`t"
        $session = New-PSSession -ComputerName $($_.TargetHost)
        Invoke-Command -Session $session -ScriptBlock {
            $foo = $null
            $foo = (Get-Service winlogbeat).Status
            Write-Host "Service status: $foo"
        }
        if($session -eq $null) {
            Write-Host "Error creating session"
        }
        Remove-PSSession $session
    }
}