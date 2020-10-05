# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
     $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
     Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
     Exit
    }
}

# Stops the spooler service and stops the program that the printer queue is dependent upon. Then it deletes the files in the print queue in the system. Then it restarts everything.
# Does a check to see if all of the files are missing from the print queue folder to decide if the script has run properly or not and then informs the user either way.

Stop-Service Spooler -Force
Get-Process printfilterpipelinesvc | ForEach-Object -Process {
    Stop-Process $_.Id -Force
}
Get-ChildItem -Path "C:\Windows\System32\spool\PRINTERS" | ForEach-Object -Process {
    Remove-Item -Path $_.PSPath -Force
}
Start-Process -FilePath "C:\Windows\System32\printfilterpipelinesvc.exe"
Start-Service Spooler

If (((Get-ChildItem -Path "C:\Windows\System32\spool\PRINTERS").count) -eq 0 -and ((Get-Service spooler).status -eq "Running")) {
    Read-Host -Prompt "Success: All printer services have been reset. Press Enter to close."
} else {
    Read-Host -Prompt "Failure: Objects remain in print queue or the service is not running. You can try running this script again or restarting the computer and printer. Press Enter to close."
}




function Restore-SpoolerService {
    [CmdletBinding()]
    param ()

    Begin {
    }

    Process {
    }

    End {
        Do {


        } While ($success)
    }

}


function Remove-UnusedPrinterPorts {
    $usedPrinterPorts = @()
    $allPrinterPorts = Get-PrinterPort

    # Gets all printers then adds whatever ports they are currently using to $usedPrinterPorts array.
    Get-Printer | ForEach-Object -Process {$usedPrinterPorts += $_.PortName}

    # Compares all printer ports to used printer ports, each object that is not a part of the $usedPrinterPorts list is removed. Non printer port objects will produce an error.
    Compare-Object -ReferenceObject $allPrinterPorts -DifferenceObject $usedPrinterPorts | ForEach-Object -Process { If($_.SideIndicator -eq '<=' ){Remove-PrinterPort $_.InputObject}}
}