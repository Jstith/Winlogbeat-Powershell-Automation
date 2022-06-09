$cred = Get-Credential

Import-Csv $args[0] | ForEach-Object {
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

    Invoke-CimMethod @MethodArgs
}