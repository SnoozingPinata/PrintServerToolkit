# PrintServerToolkit
A collection of powershell functions used to ease administration of a print server.

Restore-SpoolerService 
    Can be used to restart the print spooler service. 
    Most useful when you also want to delete the print spooler cache and want to get a true/false response back.
    Can easily be used as part of another script. 

Remove-UnusedPrinterPorts
    Note: This function is not feature complete.
    Removes non-local printer ports that are not in use.