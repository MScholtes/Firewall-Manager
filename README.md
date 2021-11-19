# Firewall-Manager
There is only one possibility to export and import firewall rules: as a blob (wfw file) in the firewall console or with a script. 

If you want to automate removing or editing a rule from the set there is no (easy) way to do it without using a third party tool or messing with the registry in dangerous places.

The three commandlets ExportFirewallRules, ImportFirewallRules and RemoveFirewallRules export, import and remove complete firewall rule sets in CSV or JSON file format. When importing existing rules with the same display name will be overwritten.

Requires Windows 8.1 / Server 2012 R2 or above.

By Markus Scholtes, 2020

## Installation

```powershell
PS C:\> Install-Module Firewall-Manager
```
(on Powershell V4 you may have to install PowershellGet before) or download from here: https://www.powershellgallery.com/packages/Firewall-Manager/.

See the script version web page too: [Powershell scripts to export and import firewall rules](https://github.com/MScholtes/TechNet-Gallery).

## Functions
### Export-FirewallRules
```
Export-FirewallRules [[-Name] <Object>] [[-Path]<PathToFile>] [-OutFormat [CSV|JSON]] [-PolicyStore <String>] [-Inbound] [-Outbound] [-Enabled] [-Disabled] [-Allow] [-Block]

Exports firewall rules to a CSV or JSON file.

-Name   Displayname of the rules to be processed. Wildcard character * is allowed. Default: *
-OutFormat	Format of output file.
-Path	Path to export rules to.
-PolicyStore   Store from which the rules are retrieved (default: ActiveStore).
Allowed values are PersistentStore, ActiveStore (the resultant rule set of all sources), localhost, a computer name, <domain.fqdn.com>\<GPO_Friendly_Name>, RSOP and others depending on the environment.
-Inbound -Outbound -Enabled -Disabled -Allow -Block   Filter which rules to export
```
### Import-FirewallRules
```
Import-FirewallRules [[-Path] <PathToFile>][-PolicyStore <String>]

Imports firewall rules from a CSV or JSON file.

-Path    Input file. Default: .\Firewall.csv
-PolicyStore   Store to which the rules are written (default: PersistentStore).
Allowed values are PersistentStore, ActiveStore (the resultant rule set of all sources), localhost, a computer name, <domain.fqdn.com>\<GPO_Friendly_Name> and others depending on the environment.
```
### Remove-FirewallRules
```
Remove-FirewallRules [[-Path] <PathToFile>] [-PolicyStore <String>]

Remove firewall rules according to the list in a CSV or JSON file.

-Path    Input file. Default: .\Firewall.csv
-PolicyStore   Store from which rules are removed (default: PersistentStore).
Allowed values are PersistentStore, ActiveStore (the resultant rule set of all sources), localhost, a computer name, <domain.fqdn.com>\<GPO_Friendly_Name> and others depending on the environment.
```
## Examples
```powershell
PS C:\> # Export all firewall rules to the CSV file FirewallRules.csv in the current directory:
PS C:\> Export-FirewallRules -Path FirewallRules.csv -OutFormat CSV
PS C:\> 
PS C:\> # Export all inbound and allowing firewall rules to the CSV file FirewallRules.csv in the current directory:
PS C:\> Export-FirewallRules -Path FirewallRules.csv -OutFormat CSV -Inbound -Allow
PS C:\> 
PS C:\> # Export all SNMP firewall rules to the JSON file SNMPRules.json:
PS C:\> Export-FirewallRules snmp* -Path SNMPRules.json -OutFormat JSON 
PS C:\> 
PS C:\> # Imports all firewall rules in the CSV file FirewallRules.csv in the current directory:
PS C:\> Import-FirewallRules -Path FirewallRules.csv
PS C:\> 
PS C:\> # Imports all firewall rules in the JSON file WmiRules.json:
PS C:\> Import-FirewallRules -Path WmiRules.json:
```
## Remarks
There might be issues when importing rules for "metro apps" to another computer.

App packet rules are stored as a SID and usually apply only to user accounts whose SIDs are stored in the export file. Those rules will normally not work on another computer since a SID is unique.
## Versions
### 2.0, 2021-11-19
- Rename parameter CSVFIle to Path
- Improved Switch logic
- Added OutFormat Parameter to Export-Firewall-Manager

### 1.1.0, 2020-12-12
- new parameter -Policystore

### 1.0.3, 2020-10-12
- default file name for JSON data has extension json now

### 1.0.2, 2020-02-17
- initial release
