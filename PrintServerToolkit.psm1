function Restore-SpoolerService {
    [CmdletBinding()]
    Param (
        [Parameter]
        [Switch]$DeleteCache
    )

    Begin {
    }

    Process {
        Stop-Service -Name Spooler -Force

        if ((Get-Service -Name Spooler).Status -ne "Stopped") {
            throw "Failed to stop the Spooler service. Verify you are running this command as an administrator."
        }

        Write-Verbose "Stopped the spooler service."

        # This deletes everything in the print spooler cache if the DeleteCache switch is true. 
        if ($DeleteCache) {
            Write-Verbose "Removing items from spooler cache."
            Get-ChildItem -Path "C:\Windows\System32\spool\PRINTERS" | ForEach-Object -Process {
                Remove-Item -Path $_.PSPath -Force
                Write-Verbose -Message "Removed $($_.PSPath)"
            }
        }

        # Tries to start the spooler service. It will try 3 times before continuing. 
        do {
            [int] $startServiceTryCount = 0
            Write-Verbose "Starting the spooler service."
            try {
                Start-Service -Name Spooler
            }
            catch {
                Write-Verbose "Failed to start the Spooler service. Waiting 10 seconds to try again."
                Start-Sleep -Seconds 10
            }
            $startServiceTryCount + 1
        } while (((Get-Service -Name Spooler).Status -eq "Stopped") -and ($startServiceTryCount -ne 3))
    }

    End {
        # Need to update this so the message is more clear on exactly what has occurred.
        If (((Get-ChildItem -Path "C:\Windows\System32\spool\PRINTERS").count) -eq 0 -and ((Get-Service spooler).status -eq "Running")) {
            Write-Verbose "Success: All printer services have been reset. Press Enter to close."
        } else {
            Write-Verbose "Failure: Objects remain in print queue or the service is not running. You can try running this script again or restarting the computer and printer. Press Enter to close."
        }
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