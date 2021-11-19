<#
.SYNOPSIS
Imports firewall rules from a CSV or JSON file.
.DESCRIPTION
Imports firewall rules from with Export-FirewallRules generated CSV or JSON files. CSV files have to
be separated with semicolons. Existing rules with same display name will be overwritten.
.PARAMETER CSVFile
Input file
.PARAMETER JSON
Input in JSON instead of CSV format
.PARAMETER PolicyStore
Store to which the rules are written (default: PersistentStore).
Allowed values are PersistentStore, ActiveStore (the resultant rule set of all sources), localhost,
a computer name, <domain.fqdn.com>\<GPO_Friendly_Name> and others depending on the environment.
.NOTES
Author: Markus Scholtes
.CHANGE LOGE
    Build date: 2020/12/12 Markus Scholtes
    Update 2021/11/19 ThisIsJeremiah@protonmail.com
        -Rename path parameter for CSVFile to Path.
        -Added logic to validate file path
        -Added logic to determine file type


Version: 1.1.0
Build date: 2020/12/12

.EXAMPLE
    Import-FirewallRules -Path .\WmiRules.json
    Imports all firewall rules in the JSON file WmiRules.json.
#>
function Import-FirewallRules
{
	Param(
    [Parameter(Mandatory = $True)]
    $Path = "",
    [STRING]$PolicyStore = "PersistentStore"
    )

	#Requires -Version 4.0
    
    #Validate path & determine filetype
    Write-Output "Validating path: $path"
    IF(Test-Path -Path $Path) #throw error if path does not exit
        {
        #parse path to confirm json or csv
        
        if ($Path |Select-String -Pattern ".csv") #Test for CSV
            {
            $PathOk = $true
            $FileType = "CSV"
            Write-Output "Data is CSV"
            }
        ELSE
            {
            IF($Path |Select-String -Pattern ".json") # Test for json
                {
                $PathOk = $true
                $FileType = "JSON"
                Write-Output "Data is JSON"
                }
                ELSE
                    {
                    throw "Invalid Input file type."
                    }
            
            }
        }
    ELSE
        {
        throw "Invalid FilePath"
        }

	# convert comma separated list (String) to Stringarray
	function ListToStringArray([STRING]$List, $DefaultValue = "Any")
	{
		if (![STRING]::IsNullOrEmpty($List))
		{	return ($List -split ",")	}
		else
		{	return $DefaultValue}
	}

	# convert value (String) to boolean
	function ValueToBoolean([STRING]$Value, [BOOLEAN]$DefaultValue = $FALSE)
	{
		if (![STRING]::IsNullOrEmpty($Value))
		{
			if (($Value -eq "True") -or ($Value -eq "1"))
			{ return $TRUE }
			else
			{	return $FALSE }
		}
		else
		{
			return $DefaultValue
		}
	}
    Write-Output "Loading Firewall rules to memory"
    SWITCH($FileType)
        {
        "CSV" # read CSV file
            {
		    #if ([STRING]::IsNullOrEmpty($path)) { $CSVFile = ".\FirewallRules.csv" }
		    $FirewallRules = Get-Content $path | ConvertFrom-CSV -Delimiter ";"
            }
        "JSON" # Read JSON file
            {
            #if ([STRING]::IsNullOrEmpty($CSVFile)) { $CSVFile = ".\FirewallRules.json" }
	    	$FirewallRules = Get-Content $path | ConvertFrom-JSON
            }
        }

	# iterate rules
	ForEach ($Rule In $FirewallRules)
	{ # generate Hashtable for New-NetFirewallRule parameters
		$RuleSplatHash = @{
			Name = $Rule.Name
			Displayname = $Rule.Displayname
			Description = $Rule.Description
			Group = $Rule.Group
			Enabled = $Rule.Enabled
			Profile = $Rule.Profile
			Platform = ListToStringArray $Rule.Platform @()
			Direction = $Rule.Direction
			Action = $Rule.Action
			EdgeTraversalPolicy = $Rule.EdgeTraversalPolicy
			LooseSourceMapping = ValueToBoolean $Rule.LooseSourceMapping
			LocalOnlyMapping = ValueToBoolean $Rule.LocalOnlyMapping
			LocalAddress = ListToStringArray $Rule.LocalAddress
			RemoteAddress = ListToStringArray $Rule.RemoteAddress
			Protocol = $Rule.Protocol
			LocalPort = ListToStringArray $Rule.LocalPort
			RemotePort = ListToStringArray $Rule.RemotePort
			IcmpType = ListToStringArray $Rule.IcmpType
			DynamicTarget = if ([STRING]::IsNullOrEmpty($Rule.DynamicTarget)) { "Any" } else { $Rule.DynamicTarget }
			Program = $Rule.Program
			Service = $Rule.Service
			InterfaceAlias = ListToStringArray $Rule.InterfaceAlias
			InterfaceType = $Rule.InterfaceType
			LocalUser = $Rule.LocalUser
			RemoteUser = $Rule.RemoteUser
			RemoteMachine = $Rule.RemoteMachine
			Authentication = $Rule.Authentication
			Encryption = $Rule.Encryption
			OverrideBlockRules = ValueToBoolean $Rule.OverrideBlockRules
		}

		# for SID types no empty value is defined, so omit if not present
		if (![STRING]::IsNullOrEmpty($Rule.Owner)) { $RuleSplatHash.Owner = $Rule.Owner }
		if (![STRING]::IsNullOrEmpty($Rule.Package)) { $RuleSplatHash.Package = $Rule.Package }

		Write-Output "Generating firewall rule `"$($Rule.DisplayName)`" ($($Rule.Name))"
		# remove rule if present
        try
            {
            Write-Output "Processing firewall rule `"$($Rule.DisplayName)`" ($($Rule.Name))"
            Get-NetFirewallRule -EA Stop -PolicyStore $PolicyStore -Name $Rule.Name | Remove-NetFirewallRule
            Write-Output "Removed existing `"$($Rule.DisplayName)`" ($($Rule.Name))"
            }
        catch
            {          
            }
        # generate new firewall rule, parameter are assigned with splatting
        Write-Output "Adding `"$($Rule.DisplayName)`" ($($Rule.Name))"
		New-NetFirewallRule -EA Continue -PolicyStore $PolicyStore @RuleSplatHash |Out-Null

		
	}

}
