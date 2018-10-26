# Set Oneclick Maintenance

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Copyright Glen Buktenica](https://img.shields.io/badge/Copyright-Glen_Buktenica-blue.svg)](http://buktenica.com)

This script will set the maintenance status of a device in CA Spectrum Oneclick using the ReST API

## Examples

```powershell
Set-OneClickMaintenance.ps1

Set-OneClickMaintenance.ps1 10.1.1.1 "Patching server until 20150109 1700 " -Maintenance

Set-OneClickMaintenance.ps1 10.1.1.1

Set-OneClickMaintenance.ps1 servername "Patching server until 20150109 1700" -Maintenance

Set-OneClickMaintenance.ps1 servername

Set-OneClickMaintenance.ps1 -Notes "Patching server until 20150109 1700" -FilePath "C:\\scripts\\host-names.txt"
```