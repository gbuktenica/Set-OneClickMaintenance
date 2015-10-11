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
    Set-OneClickMaintenance.ps1

.EXAMPLE
    Set-OneClickMaintenance.ps1 10.1.1.1 "Patching server until 20150109 1700 " -Maintenance 

.EXAMPLE
    Set-OneClickMaintenance.ps1 10.1.1.1

.EXAMPLE
    Set-OneClickMaintenance.ps1 servername "Patching server until 20150109 1700" -Maintenance 
 
 .EXAMPLE
    Set-OneClickMaintenance.ps1 servername

.EXAMPLE
    Set-OneClickMaintenance.ps1 -Notes "Patching server until 20150109 1700" -FilePath "C:\scripts\hostnames.txt" -Maintenance

.EXAMPLE
    Set-OneClickMaintenance.ps1 -FilePath "C:\scripts\hostnames.txt" 

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
    http://blog.buktenica.com
#> 
# Requires -version 4

#
# Parameter commands must be the first non-comment line.
#

Param(
     [Parameter(Position=0)] [String] $ManagedDevice,
     [Parameter(Position=1)] [String] $Notes,
     [Parameter(Position=2)] [String] $FilePath,
     [switch]$Maintenance,
     [switch]$Logging
     )

# Change the following variables to required values
#
    # Variable
    $Spectrum = "http://Spectrum/spectrum/restful/"
    $username = "Username" # This account needs write access
    $password = "Password"

# DO NOT PUT INLINE COMMENTS INTO XML OR TAB INDENTS
$XMLHeader = @'
<?xml version="1.0" encoding="UTF-8"?>
<rs:model-request throttlesize="5"
xmlns:rs="http://www.ca.com/spectrum/restful/schema/request"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.ca.com/spectrum/restful/schema/request ../../../xsd/Request.xsd ">
<rs:target-models>
<rs:models-search>
<rs:search-criteria xmlns="http://www.ca.com/spectrum/restful/schema/filter">
<action-models>
<filtered-models>
<equals>
<model-type>SearchManager</model-type>
</equals>
</filtered-models>
<action>FIND_DEV_MODELS_BY_IP</action>
<attribute id="AttributeID.NETWORK_ADDRESS">
<value>
'@

$XMLFooter = @'
</value>
</attribute>
</action-models>
</rs:search-criteria>
</rs:models-search>
</rs:target-models>
<rs:requested-attribute id="0x1006e" />
<rs:requested-attribute id="0x10000" />
<rs:requested-attribute id="0x10032" />
<rs:requested-attribute id="0x12de2" />
</rs:model-request>
'@

#
# Standard and error logging
#
    #$Logging = $true #Decomment to force logging
    If ($Logging){$VerbosePreference = "Continue"} else {$VerbosePreference = "SilentlyContinue"}
    If ($script:MyInvocation.MyCommand.Path.length -gt 0)
    {
        # Create log paths
        $CurrentPath = Split-Path $script:MyInvocation.MyCommand.Path
        $ScriptName = $MyInvocation.MyCommand.Name
        $ScriptName = [io.path]::GetFileNameWithoutExtension($ScriptName)
        $LogPath = "$CurrentPath\$ScriptName.log"
        $ErrorPath = "$CurrentPath\$ScriptName.err.log"
        
        # Standard
        If(($Host.UI.RawUI.BufferSize.Height -gt 0) -and ($Logging)) # Make sure not running in ISE
        {
            If ($ErrorPath.Length -gt 0)
            {
                Start-Transcript -path $LogPath -append
            }
        }
        # Error
        If ($ErrorPath.Length -gt 0) 
        {
            trap {$_ | Out-File -FilePath $ErrorPath -append; continue;}
        }
    }

########################
#                      #
# Functions start here #
#                      #
########################
Function Select-GUI
{
<#  
.SYNOPSIS  
    Open or save files or open folders using Windows forms.

.PARAMETER Start
    The start directory for the form.

.PARAMETER Description
    Text that is included on the chrome of the form.

.PARAMETER Ext
    Adds an extension filter to file open or save forms.

.PARAMETER File
    When present this switch uses file open or save forms. Used with the Save switch.

.PARAMETER Save
    When used with the File switch launches a file save form.

.PARAMETER UNC
    When used with no File swich and the required dll is missing will use Read-Host so a UNC path can be entered instead of failing back to the native non-unc path form.

.EXAMPLE
    Select-GUI -Start ([Environment]::GetFolderPath('MyDocuments')) -Description "Save File" -Ext "csv" -File -Save

.EXAMPLE
    Select-GUI -Start "C:\" -Description "Open Folder" -UNC

.INPUTS
    None. You cannot pipe objects to this function.

.OUTPUTS
    Full path of Folder or file    

.NOTES  
    Author     : Glen Buktenica
	Change Log : Initial Build  20150130
                 Public Release 20151005
    License    : The MIT License (MIT)
                 http://opensource.org/licenses/MIT

.LINK
    http://blog.buktenica.com
#> 
Param (
    [parameter(Position=1)][string] $Start = ([Environment]::GetFolderPath('Desktop')),
    [parameter(Position=2)][String] $Description,
    [String] $Ext,
    [Switch] $File,
    [Switch] $Save,
    [Switch] $UNC
)
    Add-Type -AssemblyName System.Windows.Forms
    
    If ($File)
    {
        If ($Save)
        {
            $OpenForm = New-Object System.Windows.Forms.SaveFileDialog
            If (!$Description)
            {
                $Description = "Select file to save"
            }
        }
        Else
        {
            $OpenForm = New-Object System.Windows.Forms.OpenFileDialog
            If (!$Description)
            {
                $Description = "Select file to open"
            }
        }
        $OpenForm.InitialDirectory = $Start
        If ($Ext.length -gt 0)
        {
            $OpenForm.Filter = "$Ext files (*.$Ext)|*.$Ext|All files (*.*)|*.*"
        }
        If ($OpenForm.showdialog() -eq "Cancel")
        {
            Write-Error "You pressed cancel, script will now terminate." 
            Start-Sleep -Seconds 2
            Break
        }
        $OpenForm.filename
        $OpenForm.Dispose()
    }
    Else #Open Folder
    {
        $DllPath = (Split-Path $script:MyInvocation.MyCommand.Path) + "\FolderSelect.dll"
        If (!$Description)
        {
            $Description = "Select folder"
        }
        If (Test-Path $DllPath -ErrorAction SilentlyContinue)
        {
            Add-Type -Path $DllPath
            $OpenForm = New-Object -TypeName FolderSelect.FolderSelectDialog -Property @{ Title = $Description; InitialDirectory = $Start }
            $A = $OpenForm.showdialog([IntPtr]::Zero)
            If (!($OpenForm.FileName))
            {
                Write-Error "You pressed cancel, script will now terminate." 
                Start-Sleep -Seconds 2
                Exit
            }
            Else
            {
                $OpenForm.FileName
            }
        }
        #If FolderSelect.dll missing fall back to .NET form or Read-Host if UNC forced
        Elseif($UNC)
        {
            $OpenForm = Read-Host $Description
            Return $OpenForm
        }
        Else
        {
            $OpenForm = New-Object System.Windows.Forms.FolderBrowserDialog
            $OpenForm.Rootfolder = $Start
            $OpenForm.Description = $Description

            If ($OpenForm.showdialog() -eq "Cancel")
            {
                Write-Error "You pressed cancel, script will now terminate." 
                Start-Sleep -Seconds 2
                Exit
            }
            $OpenForm.SelectedPath
            $OpenForm.Dispose()
        }
    }
}

#########################
#                       #
# Main Body starts here #
#                       #
#########################

#
# Validate parameters / get user input
#

# Create Credential object from passwords
$sPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($UserName, $sPassword)
$IPAddresses = @()

If ((!($FilePath) -or !(Test-Path $FilePath -ErrorAction SilentlyContinue)) -and ($ManagedDevice.length -eq 0))
{ 
    #If no parameters passed, or if the file doesn't exist...
    Clear-Host 
    Write-Host "1. Single host or IP address"
    Write-Host "2. Select TXT file with host or IP" 
    Write-Host "3. Current host" 

    $Answer = Read-Host "Any other key to exit"        
    Switch ($Answer) 
    {
        1 {$ManagedDevice = Read-Host "Enter host/IP"}
        2 {Write-Host "Select Text file with one hostname per line"
           $FilePath = Select-GUI -Ext "txt" -File}
        3 {$ManagedDevice = (Get-NetIPAddress).IPAddress | Where-Object {$_ -notlike "127*" -and $_ -notlike "*::*" -and $_ -notlike ""}} #Ignore loop back and IPv6 addresses
        default 
        {
            Write-Host "Script will now terminate"
            Start-Sleep -s 5
            Exit
        }
    }

    Clear-Host
    Write-Host "1. Set Hosts to Maintenance Mode"
    Write-Host "2. Set Hosts to Managed Mode" 

    $Answer = Read-Host "Any other key to exit"
    Switch ($Answer) 
    {
        1 {$Managed = 'False'}
        2 {$Managed = 'True'}
        default {
            Write-Host "Script will now terminate"
            Start-Sleep -s 5
            Exit
        }
    }
}
Else
{
    If ($Maintenance)
    {
        Write-Verbose "Setting to Maintenance Mode"
        $Managed = "false"
    }
    Else
    {
        Write-Verbose "Setting to Managed Mode"
        $Managed = "true"
    }
}

If ($FilePath.length -gt 0)
{
    $Hostnames = Get-Content $FilePath
    Foreach ($Hostname in $Hostnames)
    {
        If ($Hostname[0] -match "^[1-9]+$")
        {
            $IPaddresses += $Hostname
        }
        ElseIf ($Hostname.Length -gt 0)
        {
            $IPaddresses += [System.Net.Dns]::GetHostAddresses($Hostname) 
        }
    }
}

ElseIf ($ManagedDevice[0] -match "^[1-9]+$")
{
    Write-Verbose "IP address received "
    $IPAddresses = $ManagedDevice
    If ($IPaddresses) {Write-verbose $IPAddresses}
}
Else
{
    Write-Verbose "Host name received "
    Write-Verbose $ManagedDevice
    $IPaddresses = [System.Net.Dns]::GetHostAddresses($ManagedDevice).IPAddressToString
    Write-verbose $IPAddresses
}

While (($Managed -eq "false") -and ($Notes.Length -lt 4))
{
    Write-Host "Notes are mandatory when devices are being set to maintenance mode"
    $Notes = Read-Host "Enter notes"
}
#
# Get Model ID's and set managed state
#

$URI = $Spectrum + "models"
$IPAddresses = $IPAddresses | Get-Unique
Write-Verbose "Getting Model ID's"

Foreach ($IP in $IPAddresses)
{
    Write-Verbose "Getting IP Address"
    Write-Verbose "------------------------------------------"
    Write-Verbose $IP
    $XML = $XMLHeader + $IP + $XMLFooter
    $Body = [byte[]][char[]]$XML
    $Request = [System.Net.HttpWebRequest]::CreateHttp($URI);
    $Request.Method = 'POST';
    $Request.KeepAlive = $false
    $Request.Credentials = New-Object System.Net.NetworkCredential($username, $password);
    $Stream = $Request.GetRequestStream();
    $Stream.Write($Body, 0, $Body.Length);
    $Stream.Close()
    $Response = $Request.GetResponse().getresponsestream()
    $Reader = New-Object System.IO.StreamReader($Response)
    $ResponseText = [xml]$Reader.ReadToEnd()

    $Reader.Close()
    $Stream.Dispose()
    $Response.Close()

    $ModelIDs = $ResponseText.'model-response-list'.'model-responses'.model.mh
    
    ForEach ($ModelID in $ModelIDs)
    {
        If ($ModelID.length -gt 0)
        {
            Write-Verbose $ModelID
            #Set managed state
            $URIPut = $Spectrum + "model/" + $ModelID + "?attr=0x1295d&val=" + $Managed
            Invoke-RestMethod -Uri $URIPut -Credential $Credential -Method Put

            # Set Comment
            If ($Managed -eq "false")
            {
                $URIPut = $Spectrum + "model/" + $ModelID + "?attr=0x11564&val=" + $Notes
                Invoke-RestMethod -Uri $URIPut -Credential $Credential -Method Put  
            }
            Else
            {
                $URIPut = $Spectrum + "model/" + $ModelID + "?attr=0x11564&val="
                Invoke-RestMethod -Uri $URIPut -Credential $Credential -Method Put 
            }
        }
 
        Else
        {
            Write-Verbose "No Model ID found"
        }
    }
}

#
# End Standard logging at end of script
#
If ($Logging){Start-Sleep -s 10}
$Logging = $false
Try{Stop-Transcript | Out-Null} Catch{}
