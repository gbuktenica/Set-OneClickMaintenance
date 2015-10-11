<#  
.SYNOPSIS  
    Sets the maintenance status of a device in Spectrum Oneclick.
                
.PARAMETER ManagedDevice
    A single host name or IP address of a computer that will have its managed state changed.

.PARAMETER Notes
    The text that will be included in the notes field for the managed device.

.PARAMETER FilePath
    A text file containing hostnames and/or IP addresses of computers that will have their managed state changed.

.PARAMETER Maintenance
    When maintenance switch present managed devices will be put into maintenace mode. When absent managed devices will be put into managed mode.

.EXAMPLE
    Set-Maintenance.ps1

.EXAMPLE
    Set-Maintenance.ps1 10.1.1.1 "Patching server until 20150109 1700 " -Maintenance 

.EXAMPLE
    Set-Maintenance.ps1 10.1.1.1

.EXAMPLE
    Set-Maintenance.ps1 servername "Patching server until 20150109 1700" -Maintenance 
 
 .EXAMPLE
    Set-Maintenance.ps1 servername

.EXAMPLE
    Set-Maintenance.ps1 -Notes "Patching server until 20150109 1700" -FilePath "C:\scripts\hostnames.txt" -Maintenance

.EXAMPLE
    Set-Maintenance.ps1 -FilePath "C:\scripts\hostnames.txt" 

.INPUTS
    A single host name or IP address of a computer that will have its managed state changed.

.OUTPUTS
    None 

.NOTES  
    Author     : Glen Buktenica
	Change Log : Initial Build  20150311 
                 Public Release 20151006
    License    : The MIT License (MIT)
                 http://opensource.org/licenses/MIT

.LINK
    http://blog.buktenica.com/Set-OneClickMaintenance
