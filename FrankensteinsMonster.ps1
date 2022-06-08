<# This script contains all required steps for installing the Winlogbeat agent with a custom configuration file (winlogbeat.yml) for a group of windows hosts.
The winlogbeat agent is configured with the following steps:

On Domain Admin:
1. Enable PSRemoting on target host via CimMethod
2. Create a PSRemote session to target host

On Target Host:
3. Copy the winlogbeat msi installer
4. Copy the winlogbeat configuration file
5. Run the installer
6. Move configuration file to correct location
7. Start the winlogbeat service
8. Set the winlogbeat service to run on start

On Domain Admin:
9. Disable PSRemoting on target host via PSRemote session
10. Remove PSRemote session



Arguments:
$args[0] = CSV file with host names under "TargetHost" name (credentials can be read as well if needed in CimMethod or PS-Session calls).

Example:

.\FrankensteinsMonster .\workstations.csv

IMPORTANT! Run with the following files in C:\ directory:
C:\winlogbeat-8.2.2-windows-x86_64.msi
C:\winlogbeat.yml

See documentation at https://github.com/Jstith/Winlogbeat-Powershell-Automation for more information

#>

$fileName = $args[0]

# Credentials for CimSession Powershell connections. Tested with domain administrator creds.
$cred = Get-Credential

# Iterates through each entry in CSV file (after header)
Import-Csv $filename | ForEach-Object {
    
    
    $TargetHost = "$($_.TargetHost)"

    $SessionArgs = @{
        ComputerName = $TargetHost
        Credential = $cred
        SessionOption = New-CimSessionOption -Protocol Dcom
    }

    $MethodArgs = @{
        ClassName = 'Win32_Process'
        MethodName = 'Create'
        CimSession = New-CimSession @SessionArgs
        Arguments = @{
            CommandLine = "powershell Start-Process [pwershell -ArgumentList 'Enable-PSRemoting -Force'"
        }
    }

    # Uses CimMethod powershell to enable PS-Remote sessions (must be run in elevated context)
    Invoke-CimMethod @MethodArgs
}

# Hard coded delay, optional if you have strong network bandwidth
Start-Sleep -Seconds 5

# Iterates through csv file again, this time to install
Import-Csv $fileName | ForEach-Object {
    
    # Creates PS Session with target host
    $session = New-PSSession -ComputerName $($_.TargetHost)

    # Checks if a winlogbeat.yml file is already in the service's directory (indicating service is already installed)
    if((Invoke-Command -Session $session -ScriptBlock { Test-Path -Path "C:\winlogbeat.yml" -PathType Leaf }) -eq ("*","True","*")) {
        Write-Output "Configuration file already in place for $($_.TargetHost), skipping..."
    }
    else {
        Write-Output "Attempting to install winlogbeat on $($_.TargetHost)"
        
        # Copy installer and pre-configured configuration file to target host
        Copy-Item -Path "C:\winlogbeat-8.2.2-windows-x86_64.msi" -Destination "C:\" -ToSession $session
        Copy-Item -Path "C:\winlogbeat.yml" -Destination "C:\" -ToSession $session

        # Runs msi installer on target host
        Invoke-Command -Session $session -ScriptBlock { Start-Process msiexec.exe -Wait -ArgumentList '/I C:\winlogbeat-8.2.2-windows-x86_64.msi /quiet' }
        
        # Moves configuration file to service's directory and starts service
        Invoke-Command -Session $session -ScriptBlock { Move-Item -Path 'C:\winlogbeat.yml' -Destination 'C:\ProgramData\Elastic\Beats\winlogbeat\' }
        Invoke-Command -Session $session -ScriptBlock { Start-Service winlogbeat }
    }

    # Configure service to start automatically on boot
    Invoke-Command -Session $session -ScriptBlock { Set-Service -name winlogbeat -StartupType Automatic }

    # Disables future PS remote access (secure option, but can slow down troubleshooting)
    # Invoke-Command -Session $session -ScriptBlock { Disable-PSRemoting }

    # Gracefully exit session locally
    Remove-PSSession $session
}