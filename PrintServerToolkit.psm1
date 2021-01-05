function Restore-SpoolerService {
    [CmdletBinding()]
    Param (
        [Parameter]
        [Switch]$DeleteCache,

        [Parameter]
        [Switch]$ReturnResult
    )

    Begin {
    }

    Process {
        # Stopping the service.
        Stop-Service -Name Spooler -Force

        # Checking to see if service has stopped, throws errors if not.
        if ((Get-Service -Name Spooler).Status -ne "Stopped") {
            throw "Failed to stop the Spooler service. Verify you are running this command as an administrator."
        }
        Write-Verbose "Stopped the spooler service."

        # If the DeleteCache switch was used, this deletes everything in the print spooler cache. 
        if ($DeleteCache) {
            Write-Verbose "Removing items from spooler cache."
            Get-ChildItem -Path "C:\Windows\System32\spool\PRINTERS" | ForEach-Object -Process {
                Remove-Item -Path $_.PSPath -Force
                Write-Verbose -Message "Removed $($_.PSPath)"
            }
        }

        # Tries to start spooler service 3 times before continuing.
        [int] $startServiceTryCount = 0
        do {
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

        # Returns true or false if the ReturnResult switch was used.
        # Two sets of validation code to handle whether DeleteCache switch was used or not.
        if ($ReturnResult -and $DeleteCache){
            $finalCacheCount = (Get-ChildItem -Path "C:\Windows\System32\spool\PRINTERS").count
            $finalServiceStatus = (Get-Service -Name Spooler).status

            if (($finalCacheCount) -eq 0 -and ($finalServiceStatus -eq "Running")) {
                Return $true
                Write-Verbose "Success: Spooler cache is empty and the spooler service is running."
            } else {
                Return $false
                Write-Verbose "Failure:`nRemaining items in cache: $($finalCacheCount)`nService status: $($finalServiceStatus)"
            }
        } elseif ($ReturnResult){
            $finalServiceStatus = (Get-Service -Name Spooler).status
            if ($finalServiceStatus -eq "Running"){
                Return $true
                Write-Verbose "Success: Spooler service is running."
            } else {
                Return $false
                Write-Verbose "Failure: Spooler service is $($finalServiceStatus)"
            }
        }
    }

    End {
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