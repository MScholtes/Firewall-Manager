<#
.SYNOPSIS
Firewall-Manager is a module to manage firewall rules.
.NOTES
Version: 1.1.1
Date: 2022-01-04
Author: Markus Scholtes
#>

# Load modules manually for security reasons
. "$PSScriptRoot/Export-FirewallRules.ps1"
. "$PSScriptRoot/Import-FirewallRules.ps1"
. "$PSScriptRoot/Remove-FirewallRules.ps1"

# Export functions
Export-ModuleMember -Function @('Export-FirewallRules',	'Import-FirewallRules',	'Remove-FirewallRules')
