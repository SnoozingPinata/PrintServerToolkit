# PrintServerToolkit
A collection of powershell functions used to ease administration of a print server.

Restore-SpoolerService
* Can be used to restart the print spooler service.
* DeleteCache switch can be used to delete everything in the "C:\Windows\System32\spool\PRINTERS" directory.
* ReturnResult switch can be used to return a boolean value if the service has been restarted properly. If the DeleteCache switch was used, ReturnResult will also detect whether there are items remaining in the directory.


Remove-UnusedPrinterPorts
* Removes all non-local printer ports that are not in use.    
* Useful for clearing old ports from a long-term print server.
