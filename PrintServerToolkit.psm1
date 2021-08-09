function Restore-SpoolerService {
    <#
        .SYNOPSIS
        Restarts Window's print spooler service. Optionally, removes items in the spooler cache and/or performs validation.

        .DESCRIPTION
        Restarts Window's print spooler service. 
        Optionally, deletes all files in the spooler cache in C:\Windows\System32\spool\PRINTERS. 
        Optionally, performs validation and returns true or false.

        .PARAMETER DeleteCache
        Switch: Deletes all files within the Windows spooler cache located here: C:\Windows\System32\spool\PRINTERS.

        .PARAMETER ReturnResult
        Switch: Performs validation and returns a boolean value for success or failure. 

        .INPUTS
        None. You cannot pipe objects to Restore-SpoolerService.

        .OUTPUTS
        System.Boolean. ResturnResult switch returns a boolean value for success or failure.

        .EXAMPLE
        Restore-SpoolerService -ReturnResult -Verbose
        VERBOSE: Stopped the spooler service.
        VERBOSE: Starting the spooler service.
        VERBOSE: Success: Spooler service is running.
        True

        .EXAMPLE
        Restore-SpoolerService -ReturnResult -DeleteCache -Verbose
        VERBOSE: Stopped the spooler service.
        VERBOSE: Removing items from spooler cache.
        VERBOSE: Starting the spooler service.
        VERBOSE: Success: Spooler cache is empty and the spooler service is running.

        .LINK
        Github source: https://github.com/SnoozingPinata/PrintServerToolkit

        .LINK
        Author's website: www.samuelmelton.com
    #>

    [CmdletBinding()]
    Param (
        [Parameter()]
        [Switch]$DeleteCache,

        [Parameter()]
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
            $startServiceTryCount += 1
        } while (((Get-Service -Name Spooler).Status -eq "Stopped") -and ($startServiceTryCount -lt 3))

        # Performs validation. Returns true or false if ReturnResult switch was used. Different set of checks if DeleteCache switch was also used. 
        if ($ReturnResult){
            $finalServiceStatus = (Get-Service -Name Spooler).status

            # This is the code for the return value if DeleteCache switch was used.
            if ($DeleteCache){
                $finalCacheCount = (Get-ChildItem -Path "C:\Windows\System32\spool\PRINTERS").count
                if (($finalCacheCount) -eq 0 -and ($finalServiceStatus -eq "Running")) {
                    Write-Verbose "Success: Spooler cache is empty and the spooler service is running."
                    Return $true
                } else {
                    Write-Verbose "Failure:`nRemaining items in cache: $($finalCacheCount)`nService status: $($finalServiceStatus)"
                    Return $false
                }
            }

            # This is the code for the return value if ReturnResult switched was used, but DeleteCache was not.
            if ($finalServiceStatus -eq "Running"){
                Write-Verbose "Success: Spooler service is running."
                Return $true
            } else {
                Write-Verbose "Failure: Spooler service is $($finalServiceStatus)"
                Return $false
            }
        }
    }
    
    End {
    }
}


function Remove-UnusedPrinterPorts {
    <#
        .SYNOPSIS
        Removes non-local printer ports that are no longer in use.

        .DESCRIPTION
        Removes any printer port that is not a "local port" and that is not currently being used by a configured printer.

        .INPUTS
        None. You cannot pipe objects to Remove-UnusedPrinterPorts.

        .OUTPUTS
        None. This command does not provide any output.

        .EXAMPLE
        Remove-UnusedPrinterPorts

        .LINK
        Github source: https://github.com/SnoozingPinata/PrintServerToolkit

        .LINK
        Author's website: www.samuelmelton.com
    #>

    [CmdletBinding()]
    Param (
    )

    Begin {
    }

    Process {
        # Creates empty arrays to compare.
        $usedPrinterPorts = @()
        $allNonLocalPrinterPorts = @()

        # Gets all of the printer ports that are not local ports and adds each one to the $allNonLocalPrinterPorts array.
        Get-PrinterPort | Where-Object {$_.Description -ne "Local Port"} | ForEach-Object -Process {
            $allNonLocalPrinterPorts += $_.Name
        }
    
        # Gets all printers then adds whatever ports they are currently using to $usedPrinterPorts array.
        Get-Printer | ForEach-Object -Process {
            $usedPrinterPorts += $_.PortName
        }

        # Sorts both arrays by name ascending.
        $usedPrinterPorts = $usedPrinterPorts | Sort-Object
        $allNonLocalPrinterPorts = $allNonLocalPrinterPorts | Sort-Object

        $errorsOccurred = $false
    
        # Compares the arrays. If a port is on the $allNonLocalPrinterPorts list but not on the $usedPrinterPorts list, the port is removed.
        Compare-Object -ReferenceObject $allNonLocalPrinterPorts -DifferenceObject $usedPrinterPorts | ForEach-Object -Process {
            if($_.SideIndicator -eq '<=' ){
                try {
                    Remove-PrinterPort -Name $_.InputObject
                }
                catch{
                    $errorsOccurred = $true
                    Write-Verbose "Failed to remove port $($_)"
                }
            }
        }

        if ($errorsOccurred) {
            throw "Failed to remove one or more ports."
        }
    }

    End {
    }
}
